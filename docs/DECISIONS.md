# Decisões de arquitetura (ADR)

Cada decisão abaixo nasceu de uma contradição ou lacuna encontrada na
auditoria de 2026-11-03. Uma decisão só muda com uma nova ADR que a
substitua — nunca por edição silenciosa.

Legenda de status: **Aceita** · **Pendente** · **Substituída**

---

## Decisões do responsável pelo projeto

Escolhas feitas pelo dono do projeto, não pela IA. Ficam aqui para não serem
rediscutidas sem motivo.

| Data | Decisão | Escolha |
|---|---|---|
| 2026-11-03 | Autorizar saída da FASE 0 | Git + estrutura + spec v1.1 |
| 2026-11-03 | Nome da pasta do projeto | `driver-app` |
| 2026-11-03 | Repositório remoto | GitHub privado |
| 2026-11-03 | Autor do commit | `jonejoaovictor <jonejoaovictor@gmail.com>` |
| 2026-11-04 | Autorizar a FASE 1B | Sim |
| 2026-11-04 | Delegação de decisão técnica | IA decide dentro do escopo da fase |
| 2026-11-04 | Prioridade após a FASE 1B | Caminho A: máquina de build primeiro |
| 2026-11-04 | Continuidade | Registrar tudo para revisão em outra máquina |

**Limite da delegação:** vale para decisões técnicas dentro da fase
autorizada. Não autoriza mudar o `MASTER_SPEC.md`, trocar biblioteca de mapa,
instalar SDK nesta máquina, publicar, contratar serviço ou expor credencial.

---

## ADR-001 — Uma única estrutura de documentação

**Status:** Aceita · 2026-11-03

**Contexto.** A especificação previa `CHANGELOG.md` na raiz; o plano de
memória permanente colocava `docs/CHANGELOG.md` e adicionava `AI_LOG/` e
`PROMPTS/`. Duas estruturas = duas verdades.

**Decisão.** Uma só estrutura, registrada na spec §17:
- raiz: `MASTER_SPEC.md`, `AGENTS.md`, `README.md`, `CHANGELOG.md`,
  `CONTRIBUTING.md`;
- `docs/`: arquitetura, banco, segurança, decisões, tarefas, handoff;
- `PROMPTS/`: prompts oficiais;
- `AI_LOG/`: registro por sessão.

**Consequência.** Nenhum documento é duplicado em dois lugares.

---

## ADR-002 — A pasta oficial é `driver-app`

**Status:** Aceita · 2026-11-03

**Contexto.** A spec dizia `driver-app`; a pasta real era `driveapp`.

**Decisão.** Renomeada para `C:\Users\jones\Documents\driver-app` antes do
primeiro commit.

**Consequência.** Caminhos em documentação e histórico Git coincidem.

---

## ADR-003 — `driver_id` e `vehicle_id` são nulos em `requested`

**Status:** Aceita · 2026-11-03

**Contexto.** A spec listava `driver_id` sem dizer quando é preenchido. Uma
solicitação nasce sem motorista.

**Decisão.**
- `passenger_id` é sempre obrigatório.
- `driver_id` e `vehicle_id` são `NULL` em `requested` e preenchidos
  atomicamente na aceitação.
- Índice único **parcial** em `driver_id` (só onde não é nulo): uma corrida
  ativa por motorista.
- Índice único **total** em `passenger_id`: uma corrida ativa por passageiro,
  inclusive antes de ser aceita.

**Consequência.** O índice parcial é o que impede que duas solicitações sem
dono violem a regra "uma corrida por motorista".

---

## ADR-004 — `is_active` e `availability` são coisas diferentes

**Status:** Aceita · 2026-11-03

**Contexto.** A palavra `status` significava três coisas: conta ativa,
cadastro ativo e disponibilidade (`offline/online/busy`).

**Decisão.**
- `is_active` (booleano): o cadastro pode operar?
- `availability` (enum `offline`/`online`/`busy`): está recebendo
  solicitações agora?
- Desativar cadastro força `offline`.
- `busy` só é escrito pelo backend na aceitação.

**Consequência.** Some a ambiguidade em policies e telas.

---

## ADR-005 — Contas de motorista são criadas por Edge Function

**Status:** Aceita · 2026-11-03

**Contexto.** A administração cria motoristas, mas criar usuário no Supabase
Auth exige `service_role`, proibido no cliente (spec §10).

**Decisão.** Edge Function `admin-create-driver`, executada no servidor:
1. valida o JWT e confirma o papel `admin` **no banco**;
2. cria o usuário no Auth com `service_role`;
3. chama função SQL transacional que cria `profiles` + `drivers`;
4. se o passo 3 falhar, remove o usuário do Auth para não deixar conta órfã.

Provisionamento manual pelo painel é contingência documentada.

**Consequência.** Nenhuma credencial administrativa chega ao APK.

---

## ADR-006 — Cadastro público desativado e papel único

**Status:** Aceita · 2026-11-03

**Decisão.** `signUp` público desativado no Supabase Auth. Cada perfil tem
exatamente um papel (`admin` ou `driver`). Não existe papel duplo na v1.

**Consequência.** Um administrador não pode ser motorista. Se isso for
necessário, será outra ADR.

---

## ADR-007 — Recusa de solicitação não é persistida

**Status:** Aceita · 2026-11-03

**Contexto.** A spec testava "recusa", mas não modelava o estado.

**Decisão.** Recusar apenas oculta a oferta naquele aparelho, naquela
sessão. A corrida continua `requested` e disponível aos outros. Ao reabrir
o app, a oferta pode reaparecer.

**Consequência.** Nenhuma tabela de recusas. Limitação aceita porque o
máximo é cinco motoristas. Se virar problema, criar `ride_declines`
operacional com retenção limitada.

---

## ADR-008 — Matriz de cancelamento

**Status:** Aceita · 2026-11-03

| Estado | Admin | Motorista da corrida |
|---|---|---|
| `requested` | Sim | Não (ainda não é dono) |
| `accepted` | Sim | Sim |
| `driver_arriving` | Sim | Sim |
| `arrived` | Sim | Sim |
| `in_progress` | Sim | Não |

**Decisão.** Cancelamento remove a linha de `active_rides` na mesma
transação e grava recibo em `ride_operations`. `cancelled_by` e
`cancel_reason` são registrados antes da remoção.

**Consequência.** Motorista não abandona corrida em andamento sozinho. A
administração sempre pode encerrar.

---

## ADR-009 — Recibos de idempotência em `ride_operations`

**Status:** Aceita · 2026-11-03

**Contexto.** A spec exigia recibo técnico, mas não criava tabela — e
proibia histórico.

**Decisão.** Tabela `ride_operations`: `id`, `ride_id` (uuid simples, **sem**
chave estrangeira), `operation`, `actor_profile_id`, `idempotency_key`
(única), `created_at`, `expires_at`. Retenção de 30 dias com limpeza
agendada. Nenhum dado pessoal, coordenada, trajeto ou preço.

**Consequência.** Repetir a mesma operação devolve o mesmo resultado sem
novo efeito. Não é histórico: expira.

---

## ADR-010 — Motorista vê ofertas por view restrita, e só escreve por RPC

**Status:** Aceita · 2026-11-03

**Contexto.** "Motorista acessa somente seus dados" impedia ver corridas sem
dono para aceitar.

**Decisão.**
- View `available_rides` expõe apenas `id`, rótulos, coordenadas, valor e
  `created_at` de linhas `requested` sem motorista.
- `SELECT` em `active_rides` cobre apenas linhas do próprio motorista.
- Nenhum `INSERT`/`UPDATE`/`DELETE` direto do motorista. Tudo por RPC.

**Consequência.** O motorista nunca lê nome ou telefone do passageiro.

---

## ADR-011 — Heartbeat e liberação de estado obsoleto

**Status:** Aceita · 2026-11-03

**Contexto.** App encerrado à força não avisa o servidor; o motorista
ficaria `busy` para sempre.

**Decisão.** Sinal de vida a cada 30 s. Rotina agendada marca `offline`
quem não sinaliza há mais de 120 s. Isso **nunca** cancela corrida. Somente
a administração libera motorista `busy` sem corrida correspondente.

**Consequência.** Corrida presa fica visível para intervenção humana, em vez
de desaparecer sozinha.

---

## ADR-012 — Localização apagada ao ficar offline

**Status:** Aceita · 2026-11-03

**Decisão.** A linha em `driver_live_locations` é **removida** quando o
motorista fica `offline`, não apenas marcada como antiga.

**Consequência.** Não sobra posição de quem não está trabalhando.

---

## ADR-013 — Cópia local mínima, sem dados pessoais

**Status:** Aceita · 2026-11-03

**Contexto.** `expo-sqlite` não é criptografado, e o cache guardaria dados
pessoais em texto claro no aparelho.

**Decisão.** Localmente ficam apenas: id, status, versão, ids de motorista e
veículo, coordenadas e rótulos, valor e timestamps de servidor. **Nenhum**
nome ou telefone de passageiro. Fila de posições limitada, descartando as
mais antigas.

**Consequência.** Exposição em caso de aparelho perdido fica limitada a
dados de uma corrida ativa. Se ainda for insuficiente, avaliar SQLCipher
somente com nova ADR.

---

## ADR-014 — Administração escolhe o ponto tocando no mapa

**Status:** Aceita · 2026-11-03

**Contexto.** A spec permitia "coordenadas informadas pela administração",
o que na prática significaria digitar latitude e longitude.

**Decisão.** Toque no mapa captura as coordenadas; o rótulo é digitado. Não
exige serviço de geocodificação.

**Consequência.** Nenhuma dependência nova de provedor pago. Geocodificação
por endereço continua fora do escopo até decisão própria.

---

## ADR-015 — Repositório remoto privado obrigatório

**Status:** Aceita · 2026-11-03

**Decisão.** GitHub privado como remote oficial. Push ao fim de cada etapa
aprovada.

**Consequência.** Trocar de computador deixa de depender de um disco. O
remote não protege o banco Supabase.

---

## ADR-016 — Node LTS, não `current`

**Status:** Aceita · 2026-11-03 · **Corrigida em 2026-11-04**

**Contexto.** A máquina de documentação tem Node 26. Na época da auditoria,
presumi que fosse versão `current` e não LTS.

**Correção.** A verificação nas fontes oficiais mostrou que **Node 26.13.0 é a
Latest LTS (Lithium)** desde outubro de 2026, e que o Expo 58 declara
`engines.node: ^22.13.0 || ^24.3.0 || ^26.0.0 || >=27.0.0`. Node 26 é
suportado oficialmente.

**Decisão.** Usar Node 26 LTS, já instalado. Nenhuma instalação adicional.
A regra permanente continua: conferir `engines` do Expo e o status LTS antes
de trocar de runtime.

**Lição.** Não deduzir versão por número. Verificar `npm view <pkg> engines` e
o calendário oficial do Node.

---

## ADR-017 — Expo SDK 58, e não o template padrão 57

**Status:** Aceita · 2026-11-04

**Contexto.** `create-expo-app` com `blank-typescript` entregou o template
`blank-typescript@sdk-57`, marcado como compatível com Expo Go. O projeto
usa Development Build e módulos nativos, então compatibilidade com Expo Go
é irrelevante.

**Verificação feita.** `@maplibre/maplibre-react-native` 11.5.1 declara
`expo >= 54.0.0` e `react-native >= 0.80.0`. O SDK 58 traz React Native
0.88.1 e React 19.3.0, portanto está dentro do suportado.

**Decisão.** Usar `blank-typescript@latest` com Expo SDK 58.0.23.

**Consequência.** Começamos na versão estável mais recente, sem dívida de
atualização imediata. O risco do MapLibre continua no escopo da prova da
FASE 2 (P-01), agora com a matriz de versões já registrada.

---

## ADR-018 — `src/` cresce por demanda, não com pastas vazias

**Status:** Aceita · 2026-11-04

**Contexto.** A spec §17 lista muitas pastas em `src/`, mas Git não versiona
pasta vazia e a própria spec proíbe arquivo vazio sem finalidade.

**Decisão.** Nesta fase existe apenas `src/constants/app.ts`, com constantes
reais do produto. As demais pastas são criadas quando o primeiro arquivo com
propósito real aparecer, por fase.

**Consequência.** Nenhum `index.ts` vazio, nenhum `.gitkeep`. A estrutura
final continua documentada na spec §17 como destino, não como estado atual.

---

## Pendentes

| ID | Assunto | Bloqueia | Prazo |
|---|---|---|---|
| P-01 | Prova real do MapLibre no Expo atual | FASE 2 em diante | FASE 2, antes das telas |
| P-03 | Provedor de geocodificação/rota (se houver) | FASE 8 | Antes da FASE 8 |
| P-04 | Necessidade real de SQLCipher | FASE 6 | FASE 6 |
| P-05 | Nome, marca e identidade visual | FASE 2 | FASE 2 |
| P-06 | Política de retenção de logs técnicos | FASE 3 | FASE 3 |
| P-07 | Licença do projeto (não copiamos a MIT do template) | Publicação | Antes de qualquer distribuição |
