# PROMPT — 2026-11-03

## Pedido do usuário

> analise o doc master na pasta driveapp, pois quero que vc seja meu auditor.
> Minha última conversa com o ChatGPT foi a que vou te enviar, então me ajude
> a prosseguir.

## Contexto colado pelo usuário

O usuário havia combinado com outro assistente uma estratégia de
"DRIVER APP + memória técnica permanente":

-   Uma única base oficial do projeto, versionada no Git.
-   Estrutura com `MASTER_SPEC.md`, `AGENTS.md`, `README.md`, `PROMPTS/`,
    `AI_LOG/`, `docs/`.
-   Cada prompt importante salvo em arquivo.
-   Cada resposta técnica relevante registrada.
-   Decisões aprovadas no `MASTER_SPEC.md` ou em `docs/DECISIONS.md`.
-   `AI_HANDOFF.md` atualizado antes de trocar de computador ou modelo.
-   Git com commits por marco aprovado.
-   Regra: salvar o estado real do projeto, não apenas conversas.

Instruções do outro assistente naquele momento:

1. Colocar o `MASTER_SPEC.md` em `C:\Users\jones\Documents\driveapp\`.
2. Não enviar ainda o prompt de desenvolvimento.
3. Fazer o OpenCode ler a especificação e estabelecer a estrutura documental
   e o repositório Git, **sem começar a construir o aplicativo**.
4. Construir uma fundação que sobreviva à troca de computador, IA ou limite
   de mensagens.

## Papel solicitado

Auditor. Não construtor de aplicativo nesta etapa.

## Respostas dadas pelo usuário às perguntas de decisão

| Pergunta | Resposta |
|---|---|
| O que autorizar agora | Git + estrutura + spec v1.1 |
| Nome da pasta | Renomear para `driver-app` |
| Remote Git | GitHub privado |
