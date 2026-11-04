# CHANGELOG

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/).
Versionamento semântico aplicado à **documentação e ao produto**.

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
