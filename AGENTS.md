# AGENTS.md — Contrato de trabalho

Este arquivo vale para qualquer IA, modelo ou pessoa que trabalhe neste
repositório. Ele existe para que o projeto sobreviva à troca de assistente,
de computador e de sessão.

## 1. Ordem de leitura obrigatória

Antes de qualquer tarefa:

1. `MASTER_SPEC.md`
2. `AGENTS.md` (este arquivo)
3. `docs/AI_HANDOFF.md`
4. `docs/TASKS.md`
5. `docs/DECISIONS.md`
6. O documento específico da área (`docs/DATABASE.md`, `docs/ARCHITECTURE.md`…)

Não comece a implementar antes disso.

## 2. Hierarquia de verdade

```text
MASTER_SPEC.md  >  docs/DECISIONS.md  >  código  >  conversa
```

Se a conversa contradizer o documento, o documento vence. Se o documento
estiver errado, **pare**, aponte a contradição e proponha a correção. Não
decida sozinho uma mudança de arquitetura.

## 3. Anúncio obrigatório antes de agir

Toda tarefa começa com este bloco, curto e direto:

-   **Objetivo** — o que será feito.
-   **Contexto** — por que agora.
-   **Arquivos criados** — lista.
-   **Arquivos modificados** — lista.
-   **Dependências** — instalações ou pacotes.
-   **Riscos** — o que pode dar errado.
-   **Resultado esperado** — como saber que funcionou.
-   **Como será testado** — teste real, não "deve funcionar".

## 4. Limites

Proibido sem autorização explícita:

-   Modificar, mover ou apagar arquivos de outros projetos.
-   Executar `git reset --hard`, `git clean -fd`, `git checkout .`, `git push --force`.
-   Alterar configurações globais do Windows.
-   Instalar pacotes além do escopo aprovado.
-   Colocar `service_role`, senha ou chave privada no aplicativo ou no Git.
-   Criar tabela de histórico de viagens.
-   Apagar corrida ativa antes da confirmação do servidor.
-   Declarar algo concluído sem teste real.

## 5. Regras técnicas inegociáveis

| Regra | Origem |
|---|---|
| Dinheiro em centavos inteiros, nunca `float` | Spec §6 |
| Timestamps em UTC (`timestamptz`) | Spec §6 |
| Latitude entre −90 e 90, longitude entre −180 e 180 | Spec §6 |
| Regras críticas no PostgreSQL, não na interface | Spec §6, §8 |
| Toda transição de corrida passa por RPC, não `UPDATE` direto | Spec §10 |
| Conclusão e cancelamento são transacionais no servidor | Spec §7 |
| Cópia local só é apagada depois da confirmação | Spec §7 |
| Realtime notifica, não é fonte de verdade | Spec §14 |
| Sem histórico de trajetos, localização ou corridas | Spec §7, §21 |
| Motorista offline não é rastreado | Spec §11 |

## 6. Como falhar

Ao encontrar erro: **parar**, identificar a causa, explicar em linguagem
simples, avaliar efeitos colaterais, propor correção e pedir autorização
quando houver risco. Nunca esconder erro, nunca usar exceção vazia, nunca
informar sucesso sem confirmação do servidor.

## 7. Definição de concluído

Uma tarefa só está concluída quando:

-   [ ] O comportamento foi testado de forma real e o resultado está descrito.
-   [ ] Nenhum documento ficou contradizendo o código.
-   [ ] `docs/AI_HANDOFF.md` foi atualizado.
-   [ ] `docs/TASKS.md` reflete o estado real.
-   [ ] Decisões novas foram registradas em `docs/DECISIONS.md`.
-   [ ] O commit tem mensagem que descreve o porquê, não só o quê.

## 8. Registro de sessão

Cada sessão relevante gera uma pasta em `AI_LOG/AAAA-MM-DD/` com `PROMPT.md`
e `RESPONSE.md`, e uma linha em `AI_LOG/SESSION_INDEX.md`. O objetivo é
permitir que outro modelo reconstrua o raciocínio sem reler toda a conversa.

## 9. Público

O responsável pelo projeto está aprendendo programação. Explique termos
técnicos em linguagem simples. Não presuma conhecimento avançado. Prefira
uma explicação a mais do que uma sigla sem tradução.
