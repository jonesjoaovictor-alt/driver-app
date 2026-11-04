# PHASE_0 — Auditoria do ambiente

Status: **concluída em 2026-11-03**. Guardado para reexecução em outra
máquina.

## Objetivo

Verificar o ambiente sem instalar, alterar ou criar nada. Entregar relatório
e parar.

## Escopo

-   Diretório atual e isolamento do projeto.
-   Node.js, npm e `npm.cmd`.
-   Git.
-   JDK.
-   Android Studio.
-   Android SDK.
-   ADB.
-   Celular Android conectado.
-   Depuração USB.
-   Versões e compatibilidade da stack.

## Proibições

-   Não instalar nada.
-   Não modificar arquivos.
-   Não alterar configurações globais.
-   Não tocar em outros projetos.

## Formato do relatório

Uma tabela com cada item classificado como **APROVADO**, **ATENÇÃO**,
**BLOQUEADO** ou **NÃO VERIFICADO**, com a evidência observada. Depois:
o que está pronto, o que falta, riscos e próximos passos.

Ao final: **parar** e aguardar autorização para a FASE 1.

## Comandos usados (somente leitura)

```powershell
(Get-Location).Path
Test-Path .git
node -v
& "C:\Program Files\nodejs\npm.cmd" -v
git --version
java -version
echo $env:JAVA_HOME
echo $env:ANDROID_HOME
adb version
adb devices
```

## Resultado

Ver `docs/AUDIT_FASE_0.md`.
