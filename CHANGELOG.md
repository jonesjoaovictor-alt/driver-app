# CHANGELOG

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento semântico aplicado à **documentação e ao produto**.

## [1.5.0] — 2026-11-04

Avanço em desenho de backend, sem aplicar nada em banco.

### Adicionado

-   `docs/SECURITY.md`: modelo de confiança, matriz de acesso, criação de
    contas, primeiro administrador, proibições e testes de segurança.
-   `supabase/migrations/0001` a `0006`: enums, perfis, cadastros, corridas,
    recibos, localização e RLS.
-   ADR-019: ofertas por função RPC, substituindo a `view` da ADR-010.
-   Seção "Opções consideradas e descartadas" em `docs/DECISIONS.md`, com 8
    decisões e o motivo de cada alternativa rejeitada.

### Importante

-   Nenhuma migração foi aplicada. Nenhum teste de banco foi executado.
-   `docs/DATABASE.md` marca explicitamente o status de cada arquivo.

## [1.4.0] — 2026-11-04

### Adicionado

-   `docs/RESUME.md`: página única de retomada em outra máquina, com
    comandos, decisões já tomadas e o que ainda está bloqueado.
-   Seção "Decisões do responsável pelo projeto" em `docs/DECISIONS.md`,
    com data, escolha e limite da delegação.

## [1.3.0] — 2026-11-04

Preparação da prova de viabilidade do mapa (FASE 2A).

### Adicionado

-   `docs/BUILD_MACHINE.md`: instalação da máquina de build, verificação
    obrigatória e critério de aceite da prova.
-   `docs/MAPS.md`: decisão de mapa e ficha de resultado da prova.
-   `PROMPTS/PHASE_2A.md`: escopo fechado da prova do MapLibre.
-   FASE 2 dividida em 2A (viabilidade) e 2B (produto).

### Alterado

-   `MASTER_SPEC.md` §17 passa a listar `BUILD_MACHINE.md` e
    `AUDIT_FASE_0.md`.

## [1.2.0] — 2026-11-04

FASE 1B: projeto Expo criado. Ainda **sem telas, backend ou GPS**.

### Adicionado

-   Projeto Expo SDK 58.0.23 com TypeScript, React Native 0.88.1 e React
    19.3.0.
-   `app.json` com `name`, `slug`, `scheme` e `android.package` definidos.
-   `src/constants/app.ts` com constantes reais do produto.
-   Scripts `typecheck` e `doctor`.
-   `.gitattributes`, para evitar reescrita de fim de linha entre máquinas.

### Corrigido

-   ADR-016: Node 26.13.0 **é LTS** e é suportado pelo Expo 58. A avaliação
    anterior da auditoria estava errada e foi corrigida no documento.
-   `newArchEnabled` removido: não é campo válido no SDK 58 (arquitetura nova
    é o único modo).

### Verificado

-   `npx expo-doctor`: 20/20 checks.
-   `tsc --noEmit`: sem erros.

## [1.1.0] — 2026-11-03

Revisão de auditoria da especificação. Nenhuma linha de código de aplicativo
foi criada.

### Adicionado

-   `AGENTS.md`: contrato de trabalho para qualquer IA.
-   `docs/DECISIONS.md`: 16 decisões registradas com contexto.
-   `docs/AUDIT_FASE_0.md`: relatório de ambiente e auditoria da spec.
-   `docs/ENVIRONMENT.md`: inventário das duas máquinas.
-   `docs/ARCHITECTURE.md` e `docs/DATABASE.md`.
-   `docs/TASKS.md` e `docs/AI_HANDOFF.md`.
-   `PROMPTS/` e `AI_LOG/`: memória permanente das sessões com IA.
-   Seção "Criação de contas de motorista" (spec §5).
-   Seção "Heartbeat e estado obsoleto" (spec §8).
-   Seção "Visibilidade de solicitações" (spec §10).
-   Seção "Recibos de operação" (spec §7).
-   Seção "Cópia local mínima" (spec §13).
-   Fases 1A e 1B, separando fundação documental de projeto Expo.

### Corrigido

-   `driver_id` e `vehicle_id` agora explicitamente nulos até a aceitação.
-   `status` sobrecarregado substituído por `is_active` + `availability`.
-   Regras de cancelamento enumeradas por estado e por autor.
-   Recusa de solicitação definida como ação local, sem tabela.
-   Restrições de banco listadas em bloco único na spec §9.
-   Estrutura de pastas unificada com `PROMPTS/` e `AI_LOG/`.
-   Pasta oficial alinhada: `driver-app`.
-   Requisito de repositório remoto privado (spec §18).
-   Risco do MapLibre registrado com prova obrigatória na FASE 2.
-   Node LTS exigido; versão `current` não presumida suportada.

### Alterado

-   `MASTER_SPEC.md` de 1.0.0 para 1.1.0.
