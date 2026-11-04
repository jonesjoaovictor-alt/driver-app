# AI_HANDOFF

Estado do projeto para quem assume agora. Atualizar ao final de toda etapa
aprovada. Se este arquivo estiver desatualizado, ele é a primeira coisa a
corrigir.

**Última atualização:** 2026-11-03
**Fase:** 1A — fundação documental
**Compila Android nesta máquina:** não (ver `docs/ENVIRONMENT.md`)

---

## Onde estamos

A especificação existe, foi auditada e corrigida para a versão 1.1.0. A
estrutura documental está montada. **Não existe código de aplicativo, banco
ou tela.** Nada foi instalado além do Git.

O que foi decidido está em `docs/DECISIONS.md` (16 ADRs). O que falta está em
`docs/TASKS.md`.

## O que foi feito nesta sessão

1. Leitura integral do `MASTER_SPEC.md` 1.0.0.
2. Auditoria do ambiente (FASE 0), somente leitura.
3. Auditoria da especificação: 5 bloqueadores, 4 contradições, 8 lacunas,
   3 riscos técnicos.
4. Instalação do Git e renomeação da pasta para `driver-app`.
5. Especificação revisada para 1.1.0.
6. Criação de `AGENTS.md`, `README.md`, `CHANGELOG.md`, `docs/`, `PROMPTS/`,
   `AI_LOG/`.

## Próximo passo exato

**FASE 1A, itens finais.** O repositório já foi inicializado e os 20 arquivos
estão preparados (`git add`). Falta apenas a identidade do autor.

```powershell
cd C:\Users\jones\Documents\driver-app
git config user.name "SEU NOME"
git config user.email "SEU-EMAIL-DO-GITHUB"
git commit -m "docs: fundacao documental e spec v1.1.0"
```

O `gh` CLI 2.103.3 está instalado, mas não autenticado:

```powershell
gh auth login          # escolher GitHub.com e login pelo navegador
gh repo create driver-app --private --source . --remote origin --push
```

Depois disso, **parar** e aguardar autorização para a FASE 1B.

## O que NÃO fazer agora

-   Não criar o projeto Expo sem autorização (FASE 1B).
-   Não criar tabelas ou migrações (FASE 3).
-   Não instalar JDK, Android Studio ou SDK nesta máquina.
-   Não alterar decisões registradas sem nova ADR.
-   Não "melhorar" a especificação por conta própria.

## Armadilhas conhecidas

| Armadilha | O que fazer |
|---|---|
| `npm` no PowerShell falha | usar `npm.cmd` |
| Git fora do PATH nesta sessão | usar caminho completo ou abrir terminal novo |
| Pasta antiga `Documents\driveapp` vazia e travada | ignorar; some após reiniciar |
| Node 26 não é LTS | validar antes da FASE 1B (ADR-016) |
| MapLibre pode não funcionar no Expo atual | prova isolada antes das telas (P-01) |

## Contexto que não está no código

-   O projeto é para **testes controlados**, não para publicação comercial.
-   Máximo de 5 motoristas e 5 passageiros fictícios.
-   Passageiros não têm login nem aplicativo.
-   Não haverá histórico de viagens — isso é decisão de produto, não
    esquecimento.
-   O responsável está aprendendo programação: explique com clareza.

## Critério para considerar a FASE 1A encerrada

-   [ ] Commit inicial feito
-   [ ] Remote privado configurado e com push
-   [ ] Leitura de `MASTER_SPEC.md` e `AGENTS.md` sem contradições internas
-   [ ] `docs/TASKS.md` marcando 1A como concluída
