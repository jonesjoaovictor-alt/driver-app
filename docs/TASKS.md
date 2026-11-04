# Tarefas por fase

Legenda: `[x]` feito · `[ ]` pendente · `[~]` em andamento · `[!]` bloqueado

Fases oficiais estão no `MASTER_SPEC.md` §23.

---

## FASE 1A — Fundação documental · `[~]`

-   [x] Git instalado
-   [x] Pasta oficial `driver-app`
-   [x] `MASTER_SPEC.md` v1.1.0 revisado
-   [x] `AGENTS.md`
-   [x] `README.md`
-   [x] `CHANGELOG.md`
-   [x] `.gitignore` e `.env.example`
-   [x] `docs/ARCHITECTURE.md`
-   [x] `docs/DATABASE.md`
-   [x] `docs/DECISIONS.md`
-   [x] `docs/AUDIT_FASE_0.md`
-   [x] `docs/ENVIRONMENT.md`
-   [x] `docs/TASKS.md`
-   [x] `docs/AI_HANDOFF.md`
-   [x] `PROMPTS/`
-   [x] `AI_LOG/`
-   [x] `git init` (branch `main`, 20 arquivos rastreados)
-   [ ] Identidade do Git configurada (nome e e-mail)
-   [ ] Primeiro commit
-   [ ] Autenticar `gh` e criar repositório privado + `git push`
-   [ ] `CONTRIBUTING.md` (pode esperar a FASE 1B)

---

## FASE 1B — Projeto Expo · `[ ]`

-   [ ] Confirmar versão LTS de Node homologada pelo Expo
-   [ ] `create-expo-app` com TypeScript na pasta existente
-   [ ] `npx expo-doctor` sem erros
-   [ ] Registrar matriz de versões em `docs/ENVIRONMENT.md`
-   [ ] Definir `minSdk` e `targetSdk`
-   [ ] Estrutura de `src/` conforme spec §17
-   [ ] Confirmar que nada de backend ou GPS foi implementado
-   [ ] Commit aprovado

---

## FASE 2 — Interface · `[ ]`

-   [ ] **Prova do MapLibre** (bloqueia todo o resto da fase)
-   [ ] Identidade visual: nome, paleta, tipografia
-   [ ] Tela de login
-   [ ] Tela do motorista: online/offline e mapa
-   [ ] Entrada administrativa oculta: sete toques
-   [ ] Tela de login administrativa
-   [ ] Estados de erro visuais definidos

---

## FASE 3 — Backend e segurança · `[ ]`

-   [ ] Criar projeto Supabase
-   [ ] Desativar cadastro público
-   [ ] Migração 0001: enums, `profiles`, trigger
-   [ ] Migração 0002: `drivers`, `vehicles`, `passengers` + limites
-   [ ] Migração 0003: `active_rides` + índices + checks
-   [ ] Migração 0004: `ride_operations` + limpeza
-   [ ] Migração 0005: `driver_live_locations`
-   [ ] Migração 0006: RLS completa
-   [ ] `docs/SECURITY.md` com procedimento do primeiro admin
-   [ ] Edge Function `admin-create-driver`
-   [ ] Matriz de testes de segurança executada

---

## FASE 4 — Administração · `[ ]`

-   [ ] CRUD de motoristas
-   [ ] CRUD de veículos
-   [ ] CRUD de passageiros
-   [ ] Seletor de embarque e destino no mapa
-   [ ] Criação de solicitação com valor em centavos
-   [ ] Listagem de corridas ativas
-   [ ] Cancelamento conforme ADR-008

---

## FASE 5 — Corridas · `[ ]`

-   [ ] RPC `accept_ride` atômica
-   [ ] RPCs de transição
-   [ ] RPC `complete_ride` com recibo + remoção
-   [ ] RPC `cancel_ride`
-   [ ] `set_availability` e heartbeat
-   [ ] Realtime com reconexão e canal único
-   [ ] Testes de concorrência (dois aceites simultâneos)

---

## FASE 6 — Persistência e offline · `[ ]`

-   [ ] Schema SQLite local mínimo (ADR-013)
-   [ ] Recuperação de corrida ao reabrir
-   [ ] Reconciliação ao reconectar
-   [ ] Fila limitada de posições
-   [ ] Teste de resposta perdida com `idempotency_key`
-   [ ] Decidir sobre SQLCipher (P-04)

---

## FASE 7 — GPS e mapa · `[ ]`

-   [ ] Permissões progressivas
-   [ ] Foreground service + notificação
-   [ ] Intervalos de 5 s online e 3 s em corrida
-   [ ] MapLibre renderizando posição, embarque e destino
-   [ ] Teste com tela bloqueada e economia de bateria
-   [ ] Teste de reinício do aparelho

---

## FASE 8 — Navegação · `[ ]`

-   [ ] Deep link do Waze
-   [ ] Waze ausente
-   [ ] Link inválido
-   [ ] Confirmações continuam no app

---

## FASE 9 — Testes · `[ ]`

-   [ ] Funcionais
-   [ ] Concorrência
-   [ ] Segurança
-   [ ] Recuperação
-   [ ] GPS em aparelho físico
-   [ ] Relatório de resultados reais

---

## FASE 10 — Consolidação · `[ ]`

-   [ ] Revisão de segurança
-   [ ] Documentação final
-   [ ] Versão de teste
-   [ ] Limitações conhecidas escritas

---

## Pendências de decisão

| ID | Assunto | Prazo |
|---|---|---|
| P-01 | MapLibre funciona no Expo atual? | FASE 2 |
| P-02 | `targetSdk` e aparelho mínimo | FASE 1B |
| P-03 | Provedor de geocodificação/rota | antes da FASE 8 |
| P-04 | SQLCipher é necessário? | FASE 6 |
| P-05 | Nome e identidade visual | FASE 2 |
| P-06 | Retenção de logs técnicos | FASE 3 |
