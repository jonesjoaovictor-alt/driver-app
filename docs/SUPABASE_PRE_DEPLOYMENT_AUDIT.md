# SUPABASE PRE-DEPLOYMENT AUDIT
## DRIVER APP — Projeto driver-app (igsmfodwdobetfeozuim)

**Data:** 2026-11-04
**Ambiente:** Local (inspecao remota nao possivel via Docker); Projeto remoto vinculado via CLI Supabase 3.0.0.
**Status:** Banco remoto vazio, sem migrations aplicadas.

---

## 1. Ordem e dependencias das migrations 0001-0009

| Ordem | Migration | Cria/Modifica | Dependencias |
|-------|-----------|---------------|--------------|
| 1 | 0001_profiles.sql | Enums, profiles, funções de contexto, triggers, policies | Nenhuma (base) |
| 2 | 0002_catalogs.sql | Tabelas drivers, vehicles, passengers; triggers; enforce_catalog_limit | 0001 (enums: profile_role, driver_availability, ride_status, etc.) |
| 3 | 0003_active_rides.sql | Tabela active_rides; indices; triggers de protecao e limite | 0001, 0002 (profiles, drivers, vehicles, passengers) |
| 4 | 0004_ride_operations.sql | Tabela ride_operations; function purge_expired | 0001 (profiles) |
| 5 | 0005_driver_locations.sql | Tabela driver_live_locations; constraint ck_locations_not_future | 0002 (drivers) |
| 6 | 0006_rls.sql | Habilitar RLS em todas tabelas; policies por tabela | 0001-0005 (todas tabelas existem) |
| 7 | 0007_rpc.sql | 13 funcoes RPC (accept, mark_driver_arriving, mark_arrived, start_ride, complete_ride, cancel_ride, list_available_rides, set_availability, upsert_location, create_ride, create_driver, create_passenger, set_role, create_driver_account) | 0001-0006 (todas tabelas e enums existem) |
| 8 | 0008_seed.sql | Insercao de 5 passageiros ficticios (INSERT com ON CONFLICT DO NOTHING) | 0002 (passengers table) |
| 9 | 0009_active_rides_timestamps.sql | Adicao de constraint ck_rides_started_after_arrived em active_rides | 0003 (já cria active_rides) |

**Observacoes de dependencia:**
- 0001 deve ser aplicado primeiro (cria base: enums, profiles, funções de contexto)
- 0002 depende de 0001 (usa enums criados em 0001)
- 0003 depende de 0001 e 0002 (cria active_rides que referencia passengers, drivers, vehicles)
- 0004 depende apenas de 0001 (cria ride_operations que referencia profiles)
- 0005 depende de 0002 (cria driver_live_locations que referencia drivers)
- 0006 depende de todas as tabelas acima (abilita RLS e policies em todas)
- 0007 depende de todas as tabelas acima (funcoes RPC referenciam todas as tabelas)
- 0008 depende de 0002 (insere passageiros; trigger trg_passengers_limit conta passageiros)
- 0009 modifica tabela ja criada em 0003 (adiciona constraint adicional)

**Ordem critica:** 0001 -> 0002 -> 0003 -> 0004 -> 0005 -> 0006 -> 0007 -> 0008 -> 0009

---

## 2. O que cada migration cria ou modifica

### 0001_profiles.sql
- Cria tipos ENUM: profile_role (admin, driver), driver_availability (offline, online, busy), ride_status (requested, accepted, driver_arriving, arrived, in_progress), ride_operation_type (accept, arrive, start, complete, cancel), cancel_actor (admin, driver)
- Cria tabela profiles com: id, auth_user_id, full_name, phone, role, is_active, created_at, updated_at, version
- Cria trigger trg_profiles_updated_at para atualizar updated_at automaticamente
- Cria funcoes de contexto: current_profile_id(), is_admin() (security definer, search_path fixo)
- Cria trigger trg_profiles_protect para impedir alteracao de role, auth_user_id, is_admin por usuarios nao-admin
- Concede permissoes de execute para funcoes selecionadas a authenticated

### 0002_catalogs.sql
- Cria tabela drivers: referencia profiles(id) on delete restrict; campos: is_active, availability, last_seen_at
- Cria tabela vehicles: referencia drivers(id) on delete restrict; placa unica (upper btrim); indice unico por driver ativo
- Cria tabela passengers: campos basicos (name, phone, is_active)
- Cria funcoes de contexto: current_driver_id(), is_active_driver() (security definer)
- Cria funcao enforce_catalog_limit() com pg_advisory_xact_lock (limite de 5)
- Cria triggers trg_drivers_limit e trg_passengers_limit (impedem mais de 5 registros)
- Cria indices ix_drivers_profile, ix_vehicles_driver, ix_passengers_active

### 0003_active_rides.sql
- Cria tabela active_rides: referencia passengers, drivers, vehicles; campos de status, timestamps (pickup, destination, fare, cancelamento)
- Constraints: ck_rides_driver_vehicle_together, ck_rides_requested_unassigned, ck_rides_assigned_when_active, ck_rides_accepted_at, ck_rides_started_at, ck_rides_arrived_at, ck_rides_cancel_fields
- Indices unicos: ux_active_rides_passenger (passenger_id), ux_active_rides_driver (driver_id onde not null)
- Indices ix_active_rides_status, ix_active_rides_created
- Trigger trg_active_rides_updated_at
- Trigger trg_active_rides_protect_assignment (proibe troca de motorista/veiculo)
- Trigger trg_drivers_prevent_deactivation, trg_vehicles_prevent_deactivation
- Trigger trg_active_rides_passenger_active (verifica se passageiro esta ativo antes de inserir)

### 0004_ride_operations.sql
- Cria tabela ride_operations: id, ride_id, operation, actor_profile_id, idempotency_key, created_at, expires_at (30 dias)
- Indices ix_ride_operations_ride, ix_ride_operations_expires
- Funcao purge_expired_ride_operations() (apaga linhas expiradas; somente service_role pode executar)
- Concede execute a service_role (se existir)

### 0005_driver_locations.sql
- Cria tabela driver_live_locations: uma linha por motorista (driver_id primary key); coordenadas, heading, speed, accuracy, recorded_at
- Constraint ck_locations_not_future: recorded_at <= now() + interval '5 minutes'
- Trigger trg_driver_locations_updated_at
- Funcao is_location_fresh(p_driver_id, p_max_age_seconds) (verifica se localizacao esta fresca)

### 0006_rls.sql
- Habilita RLS em todas as 7 tabelas public
- Revoga todas permissoes de anon e authenticated
- Concede selects restritos a authenticated em profiles, drivers, vehicles, passengers, active_rides, ride_operations, driver_live_locations
- Politicas por tabela:
  - profiles: select/atualizado por id = current_profile_id() ou is_admin()
  - drivers: select por id = current_driver_id() ou is_admin(); admin write (all) apenas admin
  - vehicles: select por driver_id = current_driver_id() ou is_admin(); admin write (all) apenas admin
  - passengers: admin all (all operacoes apenas admin) — passageiro nao tem login
  - active_rides: select por is_admin() ou driver_id = current_driver_id(); admin update somente admin
  - ride_operations: select somente admin
  - driver_live_locations: select por driver_id = current_driver_id() ou is_admin()

### 0007_rpc.sql
- 13 funcoes RPC (security definer, search_path = public, pg_temp):
  - accept_ride: valida idempotencia, estado requested, motorista online, veiculo disponivel; atualiza corrida e grava recibo
  - mark_driver_arriving: motorista sinaliza chegada ao embarque (status accepted -> driver_arriving)
  - mark_arrived: motorista sinaliza chegada (status driver_arriving -> arrived; preenche arrived_at)
  - start_ride: motorista sinaliza inicio (status arrived -> in_progress; preenche started_at)
  - complete_ride: remove corrida ativa de active_rides; grava recibo de completamento; idempotencia via ride_operations
  - cancel_ride: matriz ADR-008 — admin pode cancelar qualquer estado nao-terminal; motorista so pode cancelar solicitacoes (requested)
  - list_available_rides: retorna corridas requested sem motorista (view da ADR-019); nunca expoe dados do passageiro
  - set_availability: motorista define disponibilidade; 'busy' proibido para cliente (apenas backend na aceitacao)
  - upsert_location: upsert por driver_id; validade de coordenadas (defesa em profundidade alem do CHECK)
  - create_ride: admin cria solicitacao de corrida (status requested); verifica passageiro ativo; indice unico em passenger_id impede duplicidade
  - create_driver: admin cria cadastro operacional do motorista vinculado a profile existente; respecta limite de 5 (trigger)
  - create_passenger: admin cria passageiro ficticio; respecta limite de 5 (trigger)
  - set_role: admin altera papel de perfil; proibe autoelevaçao (p_profile_id = current_profile_id)
  - create_driver_account: transacional (insert profile + driver); se falhar, rollback automatico; usada pela Edge Function admin-create-driver

### 0008_seed.sql
- Insere 5 passageiros ficticios: nomes 'Passageiro Ficticio 1-5', telefones (11) 90000-0001 a 0005
- ON CONFLICT DO NOTHING (idempotente)
- Comentarios: dados nao reais; triggers de limite impedem mais de 5
- Nota: insert de drivers e vehicles estao comentados (exemplo, nao executado)
- Importante: NAO cria admin automaticamente (provisionamento manual no painel)

### 0009_active_rides_timestamps.sql
- ALTER TABLE active_rides: adiciona constraint ck_rides_started_after_arrived
- Verificacao: started_at IS NULL OR arrived_at IS NULL OR started_at >= arrived_at
- Corrigica limitacao da constraint original em 0003 (so verificava started_at >= accepted_at)
- Permite corridas com started_at NULL (estados requested, accepted, driver_arriving)
- Exige started_at >= arrived_at apenas quando status = in_progress (apos mark_arrived e start_ride)

---

## 3. Riscos de cada etapa

### Etapa 1 — Migration 0001
- **Risco:** Baixo. Banco vazio; nao ha dados existentes para conflitar.
- **Atencao:** Cria enums que serao referenciados por todas as migrations seguintes. Se houver erro, o PostgreSQL fara rollback automatico ja que e um script SQL unico.

### Etapa 2 — Migration 0002
- **Risco:** Baixo. Banco vazio.
- **Atencao:** O limite de 5 (enforce_catalog_limit) e implementado via trigger + pg_advisory_xact_lock. Se duas transacoes tentarem inserir o 6º passageiro/motorista simultaneamente, uma levantara excecao 'LIMITE_ATINGIDO'.

### Etapa 3 — Migration 0003
- **Risco:** Baixo. Banco vazio.
- **Atencao:** Cria constraint ck_rides_started_at ja existente. A migration 0009 adicionara uma constraint adicional (ck_rides_started_after_arrived) sobre a mesma tabela. Ambas podem coexistir sem conflitos.

### Etapa 4 — Migration 0004
- **Risco:** Baixo. Banco vazio.
- **Atencao:** Funcao purge_expired_ride_operations usa service_role. Se o papel service_role nao existir, a funcao ainda sera criada mas o grant pode falhar silenciosamente.

### Etapa 5 — Migration 0005
- **Risco:** Medio. Constraint ck_locations_not_future usa now() em CHECK. Em operacao normal e seguro; porem se o relogio do servidor PostgreSQL mudar para atras, linhas previamente validadas poderao violar a constraint em updates subsequentes. **Nao e possivel corrigir esta migration historical (0005) sem reescreve-la; a solucao e a migration corretiva 0010 (nao criada ainda).**

### Etapa 6 — Migration 0006
- **Risco:** Medio-Alto. RLS e so eficaz se o supabase auth estiver configurado corretamente. Se houver configuracoes de auth inesperadas, policies podem nao funcionar como esperado. **Pontos criticos:**
  - passengers_admin_all: apenas admin tem acesso; passageiros nao podem criar/visualizar proprios dados (intencional para versao Android-exclusive)
  - vehicles concede update e delete para authenticated (além de select/insert) — superficie maior que o necessario, mas protegido pelas policies individuais
  - Nenhuma policy de INSERT em profiles para authenticated (intentional — perfis sao criados via Edge Function admin-create-driver usando service_role)

### Etapa 7 — Migration 0007
- **Risco:** Medio. Funcoes RPC sao security definer e dependem de funcoes de contexto (current_profile_id, is_admin, current_driver_id). Se search_path for sequestrado ou funcoes estiverem corrompidas, RPCs poderao se comportar inesperadamente. **Atencao especial:**
  - Todas as funcoes validam identidade do chamador (current_driver_id, is_admin)
  - Idempotencia implementada via ride_operations ou verificacao de estado
  - complete_ride tem tratamento de excecao unique_violation para chave duplicada de idempotencia
  - cancel_ride valida matriz ADR-008 por estado e papel

### Etapa 8 — Migration 0008
- **Risco:** Baixo. Apenas 5 passageiros ficticios inseridos ON CONFLICT DO NOTHING.
- **Atencao:** Se ja existirem passageiros no banco (de uma tentativa anterior), o ON CONFLICT DO NOTHING garante idempotencia. Drivers e vehicles estao comentados — nao serao inseridos automaticamente.

### Etapa 9 — Migration 0009
- **Risco:** Baixo. Apenas add constraint em tabela existente.
- **Atencao:** A constraint ja existe implicitamente via fluxo de estados na RPC start_ride (que exige status 'arrived' antes de 'in_progress'). A constraint adicionada aqui serve como defesa em profundidade adicional.

---

## 4. Efeito do seed 0008

- Insere exatamente 5 passageiros ficticios com nomes padrao e telefones ficticios.
- ON CONFLICT DO NOTHING garante idempotencia se executado multiple vezes.
- NAO insere drivers ou vehicles automaticamente (estao comentados).
- Os triggers trg_drivers_limit e trg_passengers_limit impedem que mais de 5 registros de drivers ou passengers sejam inseridos no total.
- **Nao cria administrador automaticamente** — documented na secao comentarios da migration: "O primeiro administrador deve ser provisionado manualmente no painel do Supabase".
- Dados ficticios nao podem ser confundidos com dados de pessoas reais (MASTER_SPEC.md §3).

---

## 5. Como verificar o resultado após aplicacao

### Inmediato apos `supabase db push --remote`:

```sql
-- Confirmar migrations aplicadas
SELECT migration_name, status 
FROM supabase._migrations 
ORDER BY migration_name;

-- Listar tabelas criadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Verificar RLS habilitado
SELECT relname, relrowsecurity FROM pg_class 
WHERE relname IN ('profiles','drivers','vehicles','passengers','active_rides','ride_operations','driver_live_locations');

-- Verificar funcoes RPC
SELECT proname FROM pg_proc WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public') ORDER BY proname;
```

### Verificacao de seguranca propria (depois de aplicadas):

```sql
-- Testar politica de profiles
SELECT id, full_name, role FROM public.profiles WHERE id = public.current_profile_id();

-- Testar politica de drivers
SELECT id, availability FROM public.drivers WHERE id = public.current_driver_id();

-- Testar list_available_rides
SELECT * FROM public.list_available_rides() LIMIT 1;

-- Testar RPC accept_ride (apos inserir corrida e passageiro)
SELECT public.accept_ride('ride-uuid', 'idem-uuid', 'driver-uuid');
```

---

## 6. Como agir em caso de falha

### Cenario: Migration falha (excecao PostgreSQL)
- O PostgreSQL faz rollback automatico da declaracao que causou o erro.
- Nenhum dado existente e comprometido (banco estava vazio).
- Corrigir o erro na migration ou criar migration corretiva posterior.
- Nao reiniciar do zero sem analisar o que falhou.

### Cenario: Conflito de schema inesperado
- Verificar historico de migrations remotas: `supabase migration list --remote`
- Se alguma migration ja foi parcialmente aplicada, pode ser necessario criar migration corretiva.
- Nao executar `supabase db reset` — isso apagaria dados e requisitaria re-autenticacao.

### Cenario: RLS nao funciona como esperado
- Verificar policies criadas: `SELECT * FROM pg_policy WHERE polschema = 'public'`
- Verificar GRANTs: `SELECT * FROM information_schema.role_table_grants WHERE table_schema = 'public'`
- Verificar configuracao do Auth do Supabase (anon key, usuarios cadastrados).
- Ajustar policies via ALTER POLICY ou novas CREATE POLICY.

### Cenario: Funcao RPC retorna erro inesperado
- Verificar search_path dentro da funcao (todos usam set search_path = public, pg_temp)
- Verificar se funcoes de contexto (current_profile_id, is_admin, current_driver_id) estao disponiveis
- Verificar permissoes de execute nas funcoes RPC

---

## 7. Pendencias que dependem do painel Supabase

| # | Pendencia | Descricao | Prioridade |
|---|-----------|-----------|-----------|
| P-01 | Chave anon EXPO_PUBLIC_SUPABASE_ANON_KEY | .env contem placeholder; aplicativo nao conecta sem chave real | CRITICA |
| P-02 | Desativar cadastro public no Supabase Auth | Configuracao no painel Supabase > Authentication > Settings | ALTA |
| P-03 | Primeiro administrador manual | Criar usuario no painel Supabase Auth e atribuir papel 'admin' via painel ou RPC set_role | ALTA |
| P-04 | Configuracao de emails/strings do Auth | Definir urls de redirect, confirmacao, etc. no painel | MÉDIA |
| P-05 | Desenvolvimento build MapLibre | Requer Development Build, nao Expo Go; maquina fisica com ambiente Android | PENDENTE |

---

## 8. Plano de implantação recomendado

### Fase A — Preparacao (já concluída nesta sessão)
1. ✅ Vincular CLI: `supabase link --project-ref igsmfodwdobetfeozuim`
2. ✅ Auditar migrations localmente (concluída)
3. ✅ Preparar arquivo SUPABASE_REMOTE_INSPECTION.sql (concluído)
4. ✅ Preencher .env com EXPO_PUBLIC_SUPABASE_ANON_KEY (aguardar do proprietario)
5. ✅ Desativar cadastro public no painel Supabase (aguardar autorizacao)
6. ✅ Provisionar primeiro administrador no painel Supabase (aguardar autorizacao)

### Fase B — Aplicacao de migrations (depois de autorizado)
7. Executar: `npx.cmd supabase db push --remote`
8. Confirmar: `supabase migration list --remote` (deve retornar 9 migrations com status applied)
9. Verificar schema via SQL Editor do painel (consultas do SUPABASE_REMOTE_INSPECTION.sql)

### Fase C — Configuracao de seguranca (depois de migrations aplicadas)
10. Verificar matriz de testes RLS (docs/SECURITY.md §10)
11. Testar RPCs autenticadas (accept_ride, complete_ride, etc.)
12. Testar usuario sem papel admin (permissoes esperadas)
13. Testar falhas de seguranca (tentativas nao autorizadas)

### Fase D — Edge Function (depois de seguranca validada)
14. Deploy: `supabase functions deploy admin-create-driver`
15. Testar edge function com credenciais de service_role
16. Verificar criacao de driver_account transacional

### Fase E — Integracao Android
17. Testar aplicativo Android com credenciais reais
18. Validar autenticacao, sessao, persistencia
19. Validar navegacao e funcionalidades de corrida

---

## 9. Confirmacao expressa de que nenhuma alteracao remota foi executada

**Esta auditoria apenas leu arquivos locais, gerou arquivos de inspeccao e elaborou planos.
Nenhum comando supabase db push, db reset ou alteracao de dados remotos foi executado durante esta sessao.
O banco remoto igsmfodwdobetfeozuim continua vazio (nenhuma migration aplicada).
Todos os arquivos criados/modificados nesta sessao estao listados no final deste documento.**