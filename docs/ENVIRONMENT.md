# Ambiente

Inventário real, verificado em 2026-11-03. Atualizar sempre que algo mudar.

## Máquina `jones` — documentação

| Item | Valor |
|---|---|
| Sistema | Windows 10 Home Single Language |
| Arquitetura | AMD64 |
| Memória | 7,8 GB |
| Papel | Documentação, Git, organização |
| Compila Android | **Não** |

### Ferramentas

| Ferramenta | Estado | Versão / caminho |
|---|---|---|
| Node.js | Instalado | v26.13.0 — `C:\Program Files\nodejs\node.exe` |
| npm | Instalado | 11.20.0 via `npm.cmd` |
| npm.ps1 | **Bloqueado** | Execution Policy impede scripts `.ps1` |
| npx | Instalado | `C:\Program Files\nodejs\npx.ps1` |
| Git | Instalado em 2026-11-03 | 2.56.0.4 — `C:\Program Files\Git\cmd\git.exe` |
| GitHub CLI | Instalado em 2026-11-03 | 2.103.3 — `C:\Program Files\GitHub CLI\gh.exe` (não autenticado) |
| winget | Disponível | v1.29.290 |
| JDK | Ausente | — |
| Android Studio | Ausente | — |
| Android SDK | Ausente | — |
| ADB | Ausente | — |
| Expo CLI | Não global | usar `npx` |
| eas-cli | Não global | — |

### Observações

1. **Não usar `npm` direto no PowerShell** nesta máquina: falha por Execution
   Policy. Usar `npm.cmd`. Não é necessário alterar configuração global.
2. **Node 26.13.0 é LTS (Lithium).** Verificado no calendário oficial do
   Node e em `npm view expo engines`. O Expo 58 aceita `^26.0.0`. Nenhuma
   instalação extra é necessária (ADR-016, corrigida em 2026-11-04).
3. Git e GitHub CLI foram as únicas instalações feitas nesta máquina.

## Matriz da stack — verificada em 2026-11-04

| Componente | Versão | Origem da verificação |
|---|---|---|
| Expo SDK | 58.0.23 | `npm view expo version` |
| React Native | 0.88.1 | `package.json` gerado |
| React | 19.3.0 | `package.json` gerado |
| TypeScript | 6.0.3 | `package.json` gerado |
| `@types/react` | 19.3.0 | `package.json` gerado |
| Node.js | 26.13.0 (LTS) | `node -v` + calendário oficial |
| npm | 11.20.0 | `npm.cmd -v` |
| `expo-doctor` | 1.21.6 | execução real, 20/20 checks |
| JVM alvo (toolchain) | 17 | `react-native/ReactAndroid/build.gradle.kts` |
| `minSdkVersion` | 24 | `react-native/gradle/libs.versions.toml` |
| `targetSdkVersion` | 36 | idem |
| `compileSdkVersion` | 37 | idem |
| Android Gradle Plugin | 9.2.1 | idem |
| Kotlin | 2.2.0 | idem |
| NDK | 27.1.12297006 | idem |
| MapLibre RN | 11.5.1 (exige expo ≥54, RN ≥0.80) | `npm view ... peerDependencies` |

`expo-doctor`: **20/20 checks aprovados**.
`tsc --noEmit`: **sem erros**.

### Configuração nativa decidida

| Item | Valor | Onde |
|---|---|---|
| `android.package` | `com.jonesjoaovictor.driverapp` | `app.json` |
| `scheme` | `driverapp` | `app.json` |
| `minSdk` | 24 (Android 7.0) | padrão RN 0.88 |
| `targetSdk` | 36 | padrão RN 0.88 |

## Máquina de build — a definir

Precisa de:

| Item | Verificação |
|---|---|
| JDK 17 | `java -version` e `JAVA_HOME` — o toolchain do RN 0.88 é 17 |
| Android Studio | instalação completa com SDK |
| Android SDK Platform | API 37 (compileSdk) |
| Build Tools | compatível com API 37 |
| NDK | 27.1.12297006 |
| `ANDROID_HOME` | variável de ambiente configurada |
| ADB | `adb version` responde |
| Aparelho físico | `adb devices` lista o aparelho como `device` |
| Depuração USB | ativada no aparelho, com autorização do computador |
| Node.js | 26.13.0 LTS (o mesmo desta máquina) |
| Git | com acesso ao remote privado |

### Como verificar (somente leitura)

```powershell
node -v
npm.cmd -v
git --version
java -version
echo $env:JAVA_HOME
echo $env:ANDROID_HOME
adb version
adb devices
```

## Continuidade entre máquinas

| Item | Valor |
|---|---|
| Remote oficial | `https://github.com/jonesjoaovictor-alt/driver-app.git` |
| Visibilidade | Privado |
| Branch principal | `main` |
| Primeiro commit | `7e75469` |
| Autenticação do push | Git Credential Manager (system) |

O que viaja pelo Git: código, documentação, prompts, decisões e histórico.

O que **não** viaja e precisa ser recriado:

-   `.env` com as chaves reais.
-   Sessão autenticada do Supabase CLI.
-   Keystore de assinatura.
-   Projeto Supabase (é serviço remoto, não arquivo).

O clone em outra máquina é suficiente para uma IA ou pessoa reconstruir o
contexto, desde que `docs/AI_HANDOFF.md` esteja em dia.
