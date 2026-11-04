# AI_HANDOFF

Estado do projeto para quem assume agora. Atualizar ao final de toda etapa
aprovada. Se este arquivo estiver desatualizado, ele é a primeira coisa a
corrigir.

**Última atualização:** 2026-11-04
**Fase:** 1B concluída · camada de serviços da FASE 2 criada · próxima: 2A (prova do MapLibre, na máquina de build)
**Remote:** `github.com/jonesjoaovictor-alt/driver-app` (privado) — sincronizado (push concluído)
**Compila Android nesta máquina:** não (ver `docs/ENVIRONMENT.md`)
**Git local:** branch `main`, 10 commits, remoto sincronizado

---

## Onde estamos

Especificação auditada (v1.1.0), documentação completa, Git sincronizado com
o remoto, projeto Expo TypeScript que compila (`tsc` limpo, `expo-doctor`
20/20), migrações SQL corrigidas, Edge Function criada, dependências
instaladas, código base do app e camada de serviços desenvolvidos.

**Git:** 10 commits, branch `main`, remote `origin` sincronizado.

| Frente | Estado real |
|---|---|
| Documentação e decisões | completo |
| Git local + remoto | 10 commits, sincronizado com GitHub |
| Projeto Expo | SDK 58, `20/20` no doctor, `tsc` limpo |
| Dependências instaladas | Supabase, SQLite, Location, Task Manager, Notifications, MapLibre, React Navigation, gesture-handler, screens, safe-area |
| MapLibre | instalado, plugin configurado em app.json, **não provado em aparelho** |
| SQL do banco | 7 migrações escritas (0007 corrigido) + 0008_seed.sql; **0 aplicadas** |
| Edge Function | admin-create-driver criada |
| Código do app | tipos DB, cliente Supabase, AuthProvider, navegação, LoginScreen, DriverScreen (base) |
| Camada de serviços | rides.ts (RPCs), location.ts (GPS), sqlite.ts (cache local), notifications.ts (persistente), realtime.ts (Supabase Realtime) |
| Hooks | useRides.ts, useLocation.ts |

Stack verificada em 2026-11-04:

| Componente | Versão |
|---|---|
| Expo SDK | 58.0.23 |
| React Native | 0.88.1 |
| React | 19.3.0 |
| TypeScript | 6.0.3 |
| Node.js | 26.13.0 (LTS) |

18 ADRs registradas em `docs/DECISIONS.md`. Pendências P-01 a P-07.

## O que foi feito nesta sessão de desenvolvimento

1. Git inicializado (branch `main`), 10 commits, push para remoto GitHub concluído.
2. Correção crítica de `0007_rpc.sql`: sintaxe, tipos, validação de identidade, idempotência, RPCs faltantes.
3. Criação de `0008_seed.sql` (dados fictícios).
4. Criação de `supabase/functions/admin-create-driver/index.ts`.
5. Instalação de todas as dependências do app.
6. Código base do app: tipos, Supabase client, AuthProvider, navegação, LoginScreen, DriverScreen.
7. Camada de serviços: rides, location, sqlite, notifications, realtime.
8. Hooks: useRides, useLocation.
9. Documentação atualizada: AI_HANDOFF, TASKS, CHANGELOG (v1.6.0).

## Próximo passo exato

**FASE 2A — Prova do MapLibre na máquina de build.**
Guia completo: `docs/BUILD_MACHINE.md`. Prompt da tarefa: `PROMPTS/PHASE_2A.md`.

Se estiver nesta máquina (documentação, sem Android):
- O repositório está sincronizado com o remoto. Qualquer máquina pode clonar e continuar.

Se estiver na máquina de build:
1. Clonar o repositório: `git clone https://github.com/jonesjoaovictor-alt/driver-app.git`
2. `npm.cmd install`, `npm.cmd run typecheck`, `npx.cmd expo-doctor`.
3. Instalar JDK 17, Android Studio, SDK 37, NDK 27.1.12297006.
4. Confirmar `adb devices` mostrando o aparelho como `device`.
5. `npx.cmd expo prebuild --platform android` e `npx.cmd expo run:android --device`.
6. Preencher `docs/MAPS.md` com o resultado real.

**Nenhuma tela de produto adicional antes de a prova do MapLibre passar.** Se falhar, parar e propor alternativa com ADR.

## O que NÃO fazer agora

- Não criar tabelas ou aplicar migrações (FASE 3 — requer Supabase real).
- Não instalar JDK, Android Studio ou SDK nesta máquina de documentação.
- Não criar telas de produto antes da prova do MapLibre passar.
- Não alterar decisões registradas sem nova ADR.

## Armadilhas conhecidas

| Armadilha | O que fazer |
|---|---|
| `npm` no PowerShell falha | usar `npm.cmd` |
| `npx` no PowerShell pode falhar | usar `npx.cmd` |
| Plugin MapLibre não resolvido | usar `@maplibre/maplibre-react-native/app.plugin.js` (não expo-plugin) |
| Pasta antiga `Documents\driveapp` vazia e travada | ignorar |

## Contexto que não está no código

- O projeto é para **testes controlados**, não para publicação comercial.
- Máximo de 5 motoristas e 5 passageiros fictícios.
- Passageiros não têm login nem aplicativo.
- Não haverá histórico de viagens — decisão de produto, não esquecimento.
- O responsável está aprendendo programação: explique com clareza.

## Critério para considerar a FASE 2 encerrada

- [ ] MapLibre renderizando em aparelho físico
- [ ] Identidade visual aprovada
- [ ] Tela do motorista com estado online/offline
- [ ] Entrada administrativa por sete toques
- [ ] Estados de erro visuais definidos
- [ ] Nenhum dado real de pessoa nos cadastros
