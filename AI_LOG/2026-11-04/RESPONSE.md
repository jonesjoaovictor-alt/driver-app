# RESPONSE — 2026-11-04

## 1. Correção de erro próprio

A auditoria de 2026-11-03 classificou o Node 26.13.0 como "ATENÇÃO, não é
LTS". **Estava errado.**

Verificação nas fontes oficiais:

-   calendário de releases do Node: `v26.13.0` é a **Latest LTS** (Lithium);
-   `npm view expo engines` → `^22.13.0 || ^24.3.0 || ^26.0.0 || >=27.0.0`.

Consequência: nenhuma instalação extra, nenhum LTS paralelo. ADR-016
corrigida, `docs/AUDIT_FASE_0.md` corrigido e `CHANGELOG` registra a
correção. O erro foi mantido visível, não apagado.

## 2. Decisão de SDK

`create-expo-app` com `blank-typescript` entregou o template SDK 57 (marcado
como Expo Go compatível). O projeto usa Development Build e módulo nativo,
então essa compatibilidade é irrelevante.

Verificado que `@maplibre/maplibre-react-native` 11.5.1 exige `expo >= 54` e
`react-native >= 0.80`. O SDK 58 atende com folga.

**Decisão:** SDK 58.0.23 (ADR-017).

## 3. Execução

1. Scaffold em pasta temporária, para não misturar com os documentos.
2. Copiados apenas os arquivos de projeto (`package.json`, `app.json`,
   `tsconfig.json`, `App.tsx`, `index.ts`, `assets/`).
3. **Não copiados:** `LICENSE` do template (MIT da Expo, não é nossa),
   `AGENTS.md` do template (o nosso é o oficial) e `.git` do scaffold.
4. `package.json` renomeado para `driver-app`, scripts `typecheck` e
   `doctor` adicionados.
5. `app.json` configurado com nome, slug, scheme e `android.package`.
6. `npm install`: 458 pacotes.
7. `expo-doctor`: falhou 1 de 20 por `newArchEnabled`.
8. Campo removido (não existe mais no SDK 58; arquitetura nova é o único
   modo).
9. `expo-doctor`: **20/20**.
10. `tsc --noEmit`: **sem erros**.

## 4. Matriz verificada

| Componente | Versão |
|---|---|
| Expo SDK | 58.0.23 |
| React Native | 0.88.1 |
| React | 19.3.0 |
| TypeScript | 6.0.3 |
| minSdk / targetSdk / compileSdk | 24 / 36 / 37 |
| AGP / Kotlin / NDK | 9.2.1 / 2.2.0 / 27.1.12297006 |
| Toolchain Java | 17 |

## 5. O que não foi feito

-   Nenhuma tela de produto.
-   Nenhum Supabase, tabela, migração ou RLS.
-   Nenhum GPS, permissão ou MapLibre instalado.
-   Nenhum JDK ou Android Studio nesta máquina.

## 6. Incidente de integridade

O `.gitignore` foi encontrado com 580 bytes de zeros — mesmo tamanho do
original, conteúdo destruído. O Git não detectou, porque confia em tamanho e
data.

Detecção: varredura byte a byte. Correção: conteúdo restaurado, `.git/index.lock`
removido, `git add` refeito, staging conferido antes do commit. Varredura final
em todos os arquivos: nenhum outro corrompido. Os PNGs acusaram falso positivo
por conterem zeros por natureza; a assinatura `89504E47` foi validada.

Causa provável: encerramento abrupto do processo. Não é problema do projeto.

## 7. Próximo passo

A decisão foi o **caminho A**: ir para a máquina de build agora.

Como esta máquina não compila Android, a entrega é operacional: guia completo,
prompt da prova e critério de aceite. Ver `docs/BUILD_MACHINE.md` e
`PROMPTS/PHASE_2A.md`.
