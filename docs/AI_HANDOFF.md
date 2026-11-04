# AI_HANDOFF

Estado do projeto para quem assume agora. Atualizar ao final de toda etapa
aprovada. Se este arquivo estiver desatualizado, ele é a primeira coisa a
corrigir.

**Última atualização:** 2026-11-04
**Fase:** 1B concluída · código base da FASE 2 criado · próxima: 2A (prova do MapLibre, na máquina de build)
**Remote:** `github.com/jonesjoaovictor-alt/driver-app` (privado) — configurado como `origin`, push pendente por falha de timeout/autenticação nesta máquina
**Compila Android nesta máquina:** não (ver `docs/ENVIRONMENT.md`)
**Git local:** inicializado (branch `main`) — histórico recuperado a partir do estado atual

---

## Onde estamos

Existe uma especificação auditada (v1.1.0), uma estrutura documental completa,
um projeto Expo TypeScript que compila e passa no `expo-doctor`, o SQL do
banco corrigido e a base de código do aplicativo criada.

**Git local restaurado:** commits `1eac1bb` (estado inicial), `532b62b` (correções SQL + Edge Function), `6a9b328` (base do app), `5d292bc` (correção plugin MapLibre + gesture handler).

| Frente | Estado real |
|---|---|
| Documentação e decisões | completo |
| Git local | inicializado, 4 commits, remote configurado |
| Projeto Expo | SDK 58, `20/20` no doctor, `tsc` limpo |
| Dependências instaladas | @supabase/supabase-js, expo-sqlite, expo-location, expo-task-manager, expo-notifications, @maplibre/maplibre-react-native, @react-navigation/native, @react-navigation/stack, react-native-screens, react-native-safe-area-context, react-native-gesture-handler |
| MapLibre | instalado, plugin configurado em app.json, **não provado em aparelho** |
| SQL do banco | 7 migrações escritas + 0008_seed.sql; **0 aplicadas** |
| 0007_rpc.sql | corrigido (sintaxe, tipos, validação de identidade, idempotência, RPCs faltantes) |
| Edge Function | admin-create-driver criada |
| RLS | desenhada, **não testada** |
| RPCs de corrida | escritas (accept, cancel, complete, mark_driver_arriving, mark_arrived, start_ride, list_available_rides, set_availability, upsert_location, create_ride, create_driver, create_passenger, set_role, create_driver_account) |
| Código do app | tipos DB, cliente Supabase, AuthProvider, navegação, LoginScreen, DriverScreen (base) |

Stack verificada em 2026-11-04:

| Componente | Versão |
|---|---|
| Expo SDK | 58.0.23 |
| React Native | 0.88.1 |
| React | 19.3.0 |
| TypeScript | 6.0.3 |
| Node.js | 26.13.0 (LTS) |

18 ADRs registradas em `docs/DECISIONS.md`. Pendências P-01 a P-07.

## O que foi feito nesta sessão (retomada de desenvolvimento)

1. Inicialização do Git local (branch `main`) e commit inicial do estado após auditoria.
2. Correção crítica de `0007_rpc.sql`: erro de sintaxe (parêntese faltando), referência a coluna inexistente (`drivers.vehicle_id`), tipos incompatíveis em `cancel_ride` (`cancel_actor`, `actor_profile_id`), funções gravadoras de `stable` → `volatile`, validação de identidade via `current_driver_id()` em accept/complete/mark_driver_arriving/mark_arrived/start_ride, recibo de idempotência na aceitação.
3. Criação de `0008_seed.sql` (dados fictícios: 5 passageiros, estrutura para 5 motoristas e 5 veículos).
4. Criação de `supabase/functions/admin-create-driver/index.ts` (Edge Function para criação de contas de motorista com service_role).
5. Instalação de dependências do app: Supabase, SQLite, Location, Task Manager, Notifications, MapLibre, React Navigation, gesture-handler.
6. Correção de `app.json`: plugin do MapLibre (`app.plugin.js`) com permissões de localização.
7. Correção de `tsconfig.json`: exclusão de `supabase/functions/` do typecheck do app.
8. Código base do aplicativo: `src/types/database.ts`, `src/services/supabase/client.ts`, `src/app/providers/AuthProvider.tsx`, `src/app/navigation/RootNavigator.tsx`, `src/screens/auth/LoginScreen.tsx`, `src/screens/driver/DriverScreen.tsx`, `App.tsx` atualizado.

## Próximo passo exato

**FASE 2A — Prova do MapLibre na máquina de build.**
Guia completo: `docs/BUILD_MACHINE.md`. Prompt da tarefa: `PROMPTS/PHASE_2A.md`.

Se estiver nesta máquina (documentação, sem Android):
1. Clonar o repositório e rodar `npm.cmd install`, `npm.cmd run typecheck`, `npx.cmd expo-doctor`.
2. Fazer push para o remote `origin` (resolve autenticação GitHub se necessário).
3. Ir para a máquina de build.

Se estiver na máquina de build:
1. Instalar JDK 17, Android Studio, SDK 37, NDK 27.1.12297006.
2. Confirmar `adb devices` mostrando o aparelho como `device`.
3. `npx.cmd expo prebuild --platform android` e `npx.cmd expo run:android --device`.
4. Preencher `docs/MAPS.md` com o resultado real.

**Nenhuma tela de produto adicional antes de a prova do MapLibre passar.** Se falhar, parar e propor alternativa com ADR.

## O que NÃO fazer agora

- Não criar tabelas ou aplicar migrações (FASE 3 — requer Supabase real).
- Não instalar JDK, Android Studio ou SDK nesta máquina de documentação.
- Não alterar decisões registradas sem nova ADR.
- Não adicionar mais dependências sem verificar compatibilidade com Expo 58.

## Armadilhas conhecidas

| Armadilha | O que fazer |
|---|---|
| `npm` no PowerShell falha | usar `npm.cmd` |
| `npx` no PowerShell pode falhar | usar `npx.cmd` |
| Git push expira/falha | verificar autenticação GitHub ou continuar localmente |
| Plugin MapLibre não resolvido | usar `@maplibre/maplibre-react-native/app.plugin.js` (não expo-plugin) |
| Pasta antiga `Documents\driveapp` vazia e travada | ignorar |
| `create-expo-app` puxa o template SDK 57 por padrão | usar `--template blank-typescript@latest` |

## Contexto que não está no código

- O projeto é para **testes controlados**, não para publicação comercial.
- Máximo de 5 motoristas e 5 passageiros fictícios.
- Passageiros não têm login nem aplicativo.
- Não haverá histórico de viagens — isso é decisão de produto, não esquecimento.
- O responsável está aprendendo programação: explique com clareza.

## Critério para considerar a FASE 2 encerrada

- [ ] MapLibre renderizando em aparelho físico
- [ ] Identidade visual aprovada
- [ ] Tela do motorista com estado online/offline
- [ ] Entrada administrativa por sete toques
- [ ] Estados de erro visuais definidos
- [ ] Nenhum dado real de pessoa nos cadastros
