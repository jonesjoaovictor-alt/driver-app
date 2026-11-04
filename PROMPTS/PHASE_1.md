# PHASE_1 — Criação e organização

## Objetivo

Criar a base permanente do projeto: documentação versionada, repositório Git
com remote privado e, só depois, o projeto Expo TypeScript.

Dividida em duas partes para não misturar documentação com código.

## FASE 1A — Fundação documental

**Feito nesta etapa.** Ver `docs/TASKS.md`.

Entregáveis:

-   `MASTER_SPEC.md` v1.1.0
-   `AGENTS.md`, `README.md`, `CHANGELOG.md`
-   `.gitignore`, `.env.example`
-   `docs/` com arquitetura, banco, decisões, ambiente, tarefas e handoff
-   `PROMPTS/` e `AI_LOG/`
-   `git init` + commit inicial
-   Remote privado no GitHub

**Não inclui:** código de aplicativo, backend, GPS.

## FASE 1B — Projeto Expo

Só começa com autorização explícita após a 1A estar commitada.

Passos:

1. Confirmar a versão LTS de Node homologada pelo Expo (ADR-016).
2. Criar o projeto Expo TypeScript na pasta existente.
3. `npx expo install` para dependências e `npx expo-doctor`.
4. Registrar a matriz de versões em `docs/ENVIRONMENT.md`.
5. Criar a estrutura de `src/` conforme spec §17, **sem telas**.
6. Confirmar que não há backend, banco ou GPS.
7. Commit e push.

**Não inclui:** telas, MapLibre, Supabase, permissões.

## Critério de aceite da FASE 1

-   [ ] Clone do zero em outra máquina reconstrói o contexto lendo só os
    documentos.
-   [ ] `npx expo-doctor` sem erro.
-   [ ] Nenhuma credencial no repositório.
-   [ ] `docs/AI_HANDOFF.md` atualizado.
-   [ ] `docs/TASKS.md` refletindo o estado real.

## Riscos

| Risco | Mitigação |
|---|---|
| Node 26 não homologado pelo Expo | instalar LTS em paralelo |
| Estrutura criada cedo demais | 1A e 1B separadas por aprovação |
| Credencial vazando no commit | `.gitignore` + revisão antes do push |
