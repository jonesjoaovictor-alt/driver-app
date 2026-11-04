# Índice de sessões

Uma linha por sessão relevante. Registro completo em `AAAA-MM-DD/`.

| Data | Fase | Tema | Decisões geradas | Modelo |
|---|---|---|---|---|
| 2026-11-03 | 0 e 1A | Auditoria do ambiente, revisão da spec, fundação documental | ADR-001 a ADR-016 | DeepSeek V4.1 Flash (OpenCode) |
| 2026-11-04 | 1B | Projeto Expo criado, matriz de versões verificada | ADR-016 corrigida, ADR-017, ADR-018 | DeepSeek V4.1 Flash (OpenCode) |

## Como registrar

1. Criar a pasta `AI_LOG/AAAA-MM-DD/`.
2. Salvar o pedido do usuário em `PROMPT.md`.
3. Salvar a resposta técnica relevante em `RESPONSE.md`.
4. Adicionar uma linha nesta tabela.
5. Se a sessão gerou decisão, registrar ADR em `docs/DECISIONS.md`.
6. Se mudou o estado do projeto, atualizar `docs/AI_HANDOFF.md`.

Não é necessário salvar conversa inteira. Salvar o que permite reconstruir o
raciocínio: pedido, decisões, alternativas descartadas e resultado.
