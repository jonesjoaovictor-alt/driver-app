# AI_HANDOFF

Estado do projeto para quem assume agora. Atualizar ao final de toda etapa
aprovada. Se este arquivo estiver desatualizado, ele é a primeira coisa a
corrigir.

**Última atualização:** 2026-11-04
**Fase:** 1B concluída · próxima é 2A (prova do MapLibre, na máquina de build)
**Remote:** `github.com/jonesjoaovictor-alt/driver-app` (privado)
**Compila Android nesta máquina:** não (ver `docs/ENVIRONMENT.md`)

---

## Onde estamos

Existe uma especificação auditada (v1.1.0), uma estrutura documental completa
e um projeto Expo TypeScript que compila e passa no `expo-doctor`.

**Não existe nenhuma tela de produto, backend, banco ou GPS.** O `App.tsx` é
apenas um ponto de entrada provisório.

Stack verificada em 2026-11-04:

| Componente | Versão |
|---|---|
| Expo SDK | 58.0.23 |
| React Native | 0.88.1 |
| React | 19.3.0 |
| TypeScript | 6.0.3 |
| Node.js | 26.13.0 (LTS) |

18 ADRs registradas em `docs/DECISIONS.md`. Pendências P-01 a P-07.

## O que foi feito nesta sessão

**2026-11-03**

1. Leitura integral do `MASTER_SPEC.md` 1.0.0.
2. Auditoria do ambiente (FASE 0), somente leitura.
3. Auditoria da especificação: 5 bloqueadores, 4 contradições, 8 lacunas,
   3 riscos técnicos.
4. Instalação do Git e renomeação da pasta para `driver-app`.
5. Especificação revisada para 1.1.0.
6. Criação de `AGENTS.md`, `README.md`, `CHANGELOG.md`, `docs/`, `PROMPTS/`,
   `AI_LOG/`.
7. Commit `7e75469` publicado no repositório privado.

**2026-11-04**

8. Confirmado que Node 26.13.0 é LTS e suportado pelo Expo 58 (ADR-016
   corrigida).
9. Projeto Expo SDK 58 criado com TypeScript.
10. `expo-doctor` 20/20 e `tsc --noEmit` limpo.
11. `app.json` configurado: `com.jonesjoaovictor.driverapp`, scheme
    `driverapp`.
12. Matriz de versões e requisitos da máquina de build registrados em
    `docs/ENVIRONMENT.md`.

## Próximo passo exato

**FASE 2A — Prova do MapLibre na máquina de build.**
Guia completo: `docs/BUILD_MACHINE.md`. Prompt da tarefa:
`PROMPTS/PHASE_2A.md`.

Sequência:

1. Na máquina de build, clonar o repositório e rodar `npm.cmd install`,
   `npm.cmd run typecheck` e `npx.cmd expo-doctor`.
2. Instalar JDK 17, Android Studio, SDK 37 e NDK 27.1.12297006.
3. Confirmar `adb devices` mostrando o aparelho como `device`.
4. Instalar `@maplibre/maplibre-react-native`, configurar o plugin conforme a
   documentação do pacote.
5. `npx.cmd expo prebuild --platform android` e
   `npx.cmd expo run:android --device`.
6. Preencher `docs/MAPS.md` com o resultado real.

**Nenhuma tela de produto antes de a prova passar.** Se falhar, parar e
propor alternativa com ADR — não trocar de biblioteca por conta própria.

### Se estiver na máquina de build agora

Copie e cole:

```powershell
git clone https://github.com/jonesjoaovictor-alt/driver-app.git
cd driver-app
npm.cmd install
npm.cmd run typecheck
npx.cmd expo-doctor
```

## O que NÃO fazer agora

-   Não criar telas de produto antes da prova do MapLibre.
-   Não criar tabelas ou migrações (FASE 3).
-   Não instalar JDK, Android Studio ou SDK nesta máquina.
-   Não alterar decisões registradas sem nova ADR.
-   Não "melhorar" a especificação por conta própria.
-   Não adicionar Supabase, GPS ou permissões nesta fase.

## Armadilhas conhecidas

| Armadilha | O que fazer |
|---|---|
| `npm` no PowerShell falha | usar `npm.cmd` |
| `npx` no PowerShell pode falhar | usar `npx.cmd` |
| Git fora do PATH nesta sessão | usar caminho completo ou abrir terminal novo |
| Pasta antiga `Documents\driveapp` vazia e travada | ignorar; some após reiniciar |
| `newArchEnabled` no `app.json` quebra o schema | não usar; é o único modo no SDK 58 |
| `create-expo-app` puxa o template SDK 57 por padrão | usar `--template blank-typescript@latest` |
| MapLibre exige Development Build | nunca presumir que roda no Expo Go |

## Contexto que não está no código

-   O projeto é para **testes controlados**, não para publicação comercial.
-   Máximo de 5 motoristas e 5 passageiros fictícios.
-   Passageiros não têm login nem aplicativo.
-   Não haverá histórico de viagens — isso é decisão de produto, não
    esquecimento.
-   O responsável está aprendendo programação: explique com clareza.

## Critério para considerar a FASE 2 encerrada

-   [ ] MapLibre renderizando em aparelho físico
-   [ ] Identidade visual aprovada
-   [ ] Tela do motorista com estado online/offline
-   [ ] Entrada administrativa por sete toques
-   [ ] Estados de erro visuais definidos
-   [ ] Nenhum dado real de pessoa nos cadastros
