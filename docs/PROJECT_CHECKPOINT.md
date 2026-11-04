# PROJECT_CHECKPOINT — Estado do DRIVER APP

**Data do checkpoint:** 2026-11-04  
**Branch:** `main`  
**Último commit:** `2c89cc8`  
**Remoto:** `origin` (https://github.com/jonesjoaovictor-alt/driver-app.git) — sincronizado

---

## Resumo do estado

O DRIVER APP está na conclusão da FASE 1B e início da FASE 2 (interface). O projeto Expo SDK 58 TypeScript está criado, compila (`tsc` limpo) e passa no `expo-doctor` (20/20). O Git está inicializado e sincronizado com o repositório remoto privado.

## O que foi concluído

- Documentação completa: MASTER_SPEC.md v1.1.0, AGENTS.md, README.md, CHANGELOG.md, docs/ (arquitetura, banco, decisões, ambiente, tarefas, handoff, segurança), PROMPTS/, AI_LOG/
- Projeto Expo SDK 58.0.23, React Native 0.88.1, React 19.3.0, TypeScript 6.0.3
- Dependências instaladas: Supabase, SQLite, Location, Task Manager, Notifications, MapLibre, React Navigation, gesture-handler, screens, safe-area
- Código base do app: tipos DB, cliente Supabase, AuthProvider, navegação, LoginScreen, DriverScreen (base)
- Camada de serviços: rides.ts (RPCs), location.ts (GPS), sqlite.ts (cache local), notifications.ts (persistente), realtime.ts (Supabase Realtime)
- Hooks: useRides.ts, useLocation.ts
- Migrações SQL 0001 a 0008 escritas e corrigidas (0007_rpc.sql corrigido: sintaxe, tipos, identidade, idempotência)
- Edge Function admin-create-driver escrita
- ADR-020 registrada: escopo Android exclusivamente

## O que está pendente

- Criar `.env` com credenciais do Supabase (bloqueador: `EXPO_PUBLIC_SUPABASE_URL` e `EXPO_PUBLIC_SUPABASE_ANON_KEY` ausentes)
- Criar projeto Supabase e aplicar migrações 0001 a 0008
- Desativar cadastro público no Supabase Auth
- Implantar Edge Function admin-create-driver
- Prova do MapLibre (FASE 2A) em aparelho físico (pré-requisito para telas)
- Executar matriz de testes de segurança

## Documentos atualizados nesta sessão

- `CHANGELOG.md` — versão 1.8.0: ADR-020 (escopo Android exclusivamente)
- `docs/DECISIONS.md` — ADR-020 adicionada
- `docs/AI_HANDOFF.md` — menção ao escopo Android exclusivamente
- `docs/PROJECT_CHECKPOINT.md` — este arquivo (checkpoint de estado)

## Arquivos modificados NÃO incluídos neste commit

- `package.json` — alteração funcional (script `android`: `expo start --android` → `expo run:android`). Preservada localmente, não incluída no commit de documentos.

---

**Próximo passo recomendado:** Resolver o bloqueador do Supabase (criar `.env`, projeto Supabase, aplicar migrações) antes de qualquer novo desenvolvimento.
