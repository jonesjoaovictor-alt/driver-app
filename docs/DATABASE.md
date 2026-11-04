# Banco de dados

Rascunho de modelagem derivado do `MASTER_SPEC.md` §7 e §9, já com as
correções da auditoria.

> **Status: SQL escrito, não aplicado, não testado.**
> Os arquivos em `supabase/migrations/` existem, mas nunca rodaram em banco
> nenhum. Aplicar e testar é tarefa da FASE 3, com projeto Supabase real.
> Nenhuma afirmação de "funciona" deve ser feita antes disso.

## Arquivos de migração

| Arquivo | Conteúdo | Aplicado |
|---|---|---|
| `0001_profiles.sql` | enums, `profiles`, funções de contexto, proteção de papel | não |
| `0002_catalogs.sql` | `drivers`, `vehicles`, `passengers`, limites, contexto de motorista | não |
| `0003_active_rides.sql` | corridas ativas, índices únicos, checagens, travas de troca | não |
| `0004_ride_operations.sql` | recibos de idempotência e limpeza | não |
| `0005_driver_locations.sql` | localização ao vivo | não |
| `0006_rls.sql` | RLS, grants e policies | não |
| `0007_rpc.sql` | funções de transição | **a escrever** |
| `0008_seed.sql` | dados fictícios de desenvolvimento | **a escrever** |


Convenções gerais:

-   Chaves primárias `uuid` com `gen_random_uuid()`.
-   Datas `timestamptz` em UTC.
-   Dinheiro em `integer` de centavos.
-   Toda tabela exposta tem RLS habilitada e `updated_at` mantido por
    trigger.
-   `version` incrementada a cada atualização, para detectar escrita
    concorrente.

## `profiles`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid | PK |
| `auth_user_id` | uuid | único, referencia `auth.users` |
| `full_name` | text | 1–120 caracteres |
| `phone` | text | opcional |
| `role` | enum | `admin` ou `driver`, imutável pelo cliente |
| `is_active` | boolean | padrão `true` |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |
| `version` | integer | padrão 1 |

## `drivers`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid | PK |
| `profile_id` | uuid | único, FK `profiles` |
| `is_active` | boolean | cadastro pode operar |
| `availability` | enum | `offline`, `online`, `busy` |
| `last_seen_at` | timestamptz | heartbeat |
| `created_at` / `updated_at` | timestamptz | |
| `version` | integer | |

Limite: no máximo 5 linhas, garantido por função com
`pg_advisory_xact_lock`.

## `vehicles`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid | PK |
| `driver_id` | uuid | FK `drivers` |
| `brand`, `model`, `color` | text | 1–60 |
| `plate` | text | único, normalizado em maiúsculas |
| `is_active` | boolean | |
| `created_at` / `updated_at` | timestamptz | |
| `version` | integer | |

Regra: um veículo ativo por motorista → índice único parcial em
`driver_id` onde `is_active`. Não permitir troca ou desativação durante
corrida ativa.

## `passengers`

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid | PK |
| `name` | text | 1–120 |
| `phone` | text | opcional, fictício |
| `is_active` | boolean | |
| `created_at` / `updated_at` | timestamptz | |
| `version` | integer | |

Limite: no máximo 5 linhas, mesma função de trava.

## `active_rides`

Somente corridas não terminadas.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid | PK |
| `passenger_id` | uuid | NOT NULL, FK `passengers` |
| `driver_id` | uuid | NULL em `requested`, FK `drivers` |
| `vehicle_id` | uuid | NULL em `requested`, FK `vehicles` |
| `pickup_latitude` | numeric | −90 a 90 |
| `pickup_longitude` | numeric | −180 a 180 |
| `pickup_label` | text | 1–120 |
| `destination_latitude` | numeric | −90 a 90 |
| `destination_longitude` | numeric | −180 a 180 |
| `destination_label` | text | 1–120 |
| `estimated_fare_cents` | integer | ≥ 0 |
| `status` | enum | `requested`, `accepted`, `driver_arriving`, `arrived`, `in_progress` |
| `created_at` | timestamptz | |
| `accepted_at` | timestamptz | nulo até aceite |
| `arrived_at` | timestamptz | nulo até chegada |
| `started_at` | timestamptz | nulo até início |
| `cancelled_at`, `cancelled_by`, `cancel_reason` | | preenchidos antes da remoção |
| `updated_at` | timestamptz | |
| `version` | integer | |

Índices:
- `unique (passenger_id)` — uma corrida ativa por passageiro;
- `unique (driver_id) where driver_id is not null` — uma por motorista;
- `index (status)` para consultas da administração.

Invariantes de estado, verificadas por função:

| Transição | Pré-condição |
|---|---|
| `requested → accepted` | `driver_id IS NULL` |
| `accepted → driver_arriving` | é o motorista da corrida |
| `driver_arriving → arrived` | é o motorista da corrida |
| `arrived → in_progress` | é o motorista da corrida |
| `in_progress → completed` | é o motorista da corrida |
| qualquer → `cancelled` | respeita ADR-008 |

## `ride_operations`

Recibo técnico de idempotência. Não é histórico.

| Coluna | Tipo | Regra |
|---|---|---|
| `id` | uuid | PK |
| `ride_id` | uuid | sem FK, de propósito |
| `operation` | enum | `accept`, `arrive`, `start`, `complete`, `cancel` |
| `actor_profile_id` | uuid | quem executou |
| `idempotency_key` | uuid | único |
| `created_at` | timestamptz | |
| `expires_at` | timestamptz | criação + 30 dias |

Limpeza diária por rotina agendada. Sem coordenadas, nomes, telefones ou
valores.

## `driver_live_locations`

Uma linha por motorista, `upsert`. Removida quando o motorista fica
`offline`.

| Coluna | Tipo | Regra |
|---|---|---|
| `driver_id` | uuid | PK, FK `drivers` |
| `latitude` | numeric | −90 a 90 |
| `longitude` | numeric | −180 a 180 |
| `accuracy` | numeric | ≥ 0 |
| `heading` | numeric | 0–360, opcional |
| `speed` | numeric | ≥ 0, opcional |
| `recorded_at` | timestamptz | leitura do GPS |
| `updated_at` | timestamptz | |

## Função `list_available_rides()`

Projeção restrita para o motorista encontrar ofertas. Substitui a `view`
prevista na ADR-010 (ver ADR-019).

Retorna apenas:

```text
id, pickup_label, destination_label,
pickup_latitude, pickup_longitude,
destination_latitude, destination_longitude,
estimated_fare_cents, created_at
```

Regras:
- `security definer`, com `search_path` fixo;
- exige que o chamador seja motorista ativo;
- filtra `status = 'requested' AND driver_id IS NULL`;
- nunca expõe `passenger_id`, nome ou telefone.

## Funções (RPC) previstas

| Função | Papel | Efeito |
|---|---|---|
| `accept_ride(ride_id, idempotency_key)` | driver | atômico, define motorista e veículo |
| `mark_driver_arriving(ride_id, version)` | driver | transição |
| `mark_arrived(ride_id, version)` | driver | transição |
| `start_ride(ride_id, version)` | driver | transição |
| `complete_ride(ride_id, idempotency_key)` | driver | recibo + remoção |
| `cancel_ride(ride_id, reason, idempotency_key)` | driver/admin | respeita ADR-008 |
| `set_availability(state)` | driver | `busy` proibido |
| `upsert_location(...)` | driver | só a própria linha |
| `create_driver(...)` | admin | respeita limite de 5 |
| `create_passenger(...)` | admin | respeita limite de 5 |
| `create_ride(...)` | admin | exige passageiro ativo e livre |
| `set_role(...)` | admin | nunca pelo próprio usuário |

## Migrações previstas (FASE 3)

| Ordem | Conteúdo |
|---|---|
| 0001 | extensões, enums, `profiles`, trigger `updated_at` |
| 0002 | `drivers`, `vehicles`, `passengers`, limites |
| 0003 | `active_rides`, índices únicos, checks |
| 0004 | `ride_operations` + rotina de limpeza |
| 0005 | `driver_live_locations` |
| 0006 | RLS de todas as tabelas |
| 0007 | RPCs de corrida |
| 0008 | view `available_rides` |
| 0009 | seed de desenvolvimento (5 motoristas, 5 passageiros fictícios) |

Nunca editar migração já aplicada. Correção = nova migração.
