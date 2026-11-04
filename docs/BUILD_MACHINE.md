# Máquina de build — instalação e prova do MapLibre

Este documento é para ser seguido **na máquina de build**, não na máquina de
documentação. Ele existe para que a instalação não dependa de memória nem de
conversa.

**Objetivo:** provar que o MapLibre funciona em Development Build, antes de
qualquer tela do produto.

**Tempo estimado:** 1 a 2 horas, sendo a maior parte download.

---

## 1. Pré-requisitos de hardware

| Item | Mínimo | Observação |
|---|---|---|
| RAM | 16 GB recomendado | 8 GB compila, mas sofre com Gradle |
| Espaço livre | 25 GB | SDK + Gradle + cache |
| Aparelho Android | Android 7.0+ (API 24) | físico, com cabo de dados |
| Internet | banda larga | downloads de 5 a 10 GB |

## 2. Instalação

Abra o PowerShell **como administrador**.

```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e --source winget --accept-package-agreements --accept-source-agreements
winget install --id Google.AndroidStudio -e --source winget --accept-package-agreements --accept-source-agreements
```

Feche e reabra o terminal depois das instalações.

### Variáveis de ambiente

```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17*", "User")
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$env:LOCALAPPDATA\Android\Sdk", "User")
```

Ajuste o caminho do JDK para o que existir de fato em
`C:\Program Files\Eclipse Adoptium`. Não use curinga na variável: copie o nome
exato da pasta.

Adicione ao `Path` do usuário:

```text
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\cmdline-tools\latest\bin
%JAVA_HOME%\bin
```

### Componentes do SDK

Abra o Android Studio uma vez, conclua o assistente e instale pelo
**SDK Manager** (aba SDK Platforms / SDK Tools):

| Componente | Versão |
|---|---|
| Android SDK Platform | **API 37** (compileSdk do projeto) |
| Android SDK Build-Tools | compatível com API 37 |
| Android SDK Platform-Tools | mais recente |
| Android SDK Command-line Tools | mais recente |
| NDK (Side by side) | **27.1.12297006** |
| CMake | versão sugerida pelo SDK Manager |

## 3. Verificação obrigatória

Não avance sem todos os itens abaixo respondendo.

```powershell
java -version          # deve dizer 17.x
echo $env:JAVA_HOME
echo $env:ANDROID_HOME
adb version
adb devices            # deve listar o aparelho como "device"
node -v                # 26.13.0 LTS
npm.cmd -v
```

No aparelho: **Opções do desenvolvedor** ativas e **Depuração USB** ligada.
Aceite o aviso "Permitir depuração USB" no celular.

Se `adb devices` mostrar `unauthorized`, o aviso está pendente no aparelho.
Se mostrar lista vazia, o cabo é só de carga ou o driver não está instalado.

## 4. Clonar e preparar o projeto

```powershell
git clone https://github.com/jonesjoaovictor-alt/driver-app.git
cd driver-app
npm.cmd install
npm.cmd run typecheck
npx.cmd expo-doctor
```

Esperado: `20/20 checks passed` e nenhum erro de TypeScript. Se algo falhar
aqui, **pare** — o problema é de ambiente, não do projeto.

## 5. Prova do MapLibre (FASE 2A)

### 5.1 Instalar o pacote

```powershell
npx.cmd expo install "@maplibre/maplibre-react-native"
```

Conferir a versão instalada e o plugin do Expo:

```powershell
node -p "require('@maplibre/maplibre-react-native/package.json').version"
dir node_modules\@maplibre\maplibre-react-native\app.plugin.js
```

Se o plugin existir, ele deve ser adicionado em `app.json` dentro de
`"plugins"`. Use a documentação que vem no próprio pacote
(`node_modules\@maplibre\maplibre-react-native\README.md`) como fonte — não
inventar configuração.

### 5.2 Estilo do mapa

Fonte inicial: OpenFreeMap.

```text
https://tiles.openfreemap.org/styles/liberty
```

Verificar termos de uso e atribuição antes de considerar aprovado.

### 5.3 Gerar o Development Build

```powershell
npx.cmd expo prebuild --platform android
npx.cmd expo run:android --device
```

A primeira compilação baixa dependências do Gradle e demora bastante. Não
interromper.

### 5.4 Critério de aceite

A prova só é aprovada se **todos** os itens forem observados no aparelho
físico:

-   [ ] O mapa renderiza tiles reais, sem tela branca.
-   [ ] Arrastar move o mapa e o zoom funciona.
-   [ ] Um marcador aparece em coordenada fixa conhecida.
-   [ ] A atribuição da fonte de tiles está visível.
-   [ ] O aplicativo não fecha ao girar, minimizar e reabrir.
-   [ ] `adb logcat` não mostra erro nativo recorrente do MapLibre.

### 5.5 Se falhar

Não improvisar. Registrar e parar:

1. Versão exata do pacote, do Expo, do RN e do AGP.
2. Mensagem de erro completa do Gradle e do `adb logcat`.
3. Se possível, um trecho de tela ou log.
4. Gravar em `docs/MAPS.md` na seção "Resultado da prova".
5. Propor alternativas com prós e contras: versão anterior do MapLibre,
   `react-native-maps`, ou mapa adiado.

Alternativa de mapa muda a especificação e exige ADR. Não decidir sozinho.

## 6. O que NÃO fazer nesta etapa

-   Não desenhar telas de produto antes da prova passar.
-   Não conectar Supabase.
-   Não implementar GPS em segundo plano.
-   Não publicar nada em loja.
-   Não commitar `android/` (já está no `.gitignore`).

## 7. Registro obrigatório

Ao terminar, atualizar:

-   `docs/MAPS.md` — resultado real da prova.
-   `docs/ENVIRONMENT.md` — versões da máquina de build.
-   `docs/TASKS.md` — marcar FASE 2A.
-   `docs/AI_HANDOFF.md` — próximo passo.
-   Commit + push.
