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
2. **Node 26 não é LTS.** Antes de criar o projeto Expo (FASE 1B), validar a
   versão homologada. Se preciso, instalar LTS em paralelo, sem remover a
   atual (ADR-016).
3. Git é o único item que precisou ser instalado nesta máquina.

## Máquina de build — a definir

Precisa de:

| Item | Verificação |
|---|---|
| JDK 17 ou 21 | `java -version` e `JAVA_HOME` |
| Android Studio | instalação completa com SDK |
| Android SDK Platform | versão exigida pelo Expo escolhido |
| Build Tools | compatível com o SDK |
| `ANDROID_HOME` | variável de ambiente configurada |
| ADB | `adb version` responde |
| Aparelho físico | `adb devices` lista o aparelho como `device` |
| Depuração USB | ativada no aparelho, com autorização do computador |
| Node LTS | mesma versão da máquina de documentação |
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

O que viaja pelo Git: código, documentação, prompts, decisões e histórico.

O que **não** viaja e precisa ser recriado:

-   `.env` com as chaves reais.
-   Sessão autenticada do Supabase CLI.
-   Keystore de assinatura.
-   Projeto Supabase (é serviço remoto, não arquivo).

O clone em outra máquina é suficiente para uma IA ou pessoa reconstruir o
contexto, desde que `docs/AI_HANDOFF.md` esteja em dia.
