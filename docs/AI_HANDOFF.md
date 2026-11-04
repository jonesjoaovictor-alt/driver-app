# AI_HANDOFF

Estado do projeto para quem assume agora. Atualizar ao final de toda etapa
aprovada. Se este arquivo estiver desatualizado, ele é a primeira coisa a
corrigir.

**Última atualização:** 2026-11-03
**Fase:** 1A concluída — aguardando autorização para 1B
**Remote:** `github.com/jonesjoaovictor-alt/driver-app` (privado)
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
7. Commit `7e75469` publicado no repositório privado.

## Próximo passo exato

A FASE 1A está encerrada. Commit `7e75469` publicado em
`github.com/jonesjoaovictor-alt/driver-app`.

**Próximo passo:** aguardar autorização expressa do responsável para iniciar
a **FASE 1B — Projeto Expo**.

Quando autorizado, a ordem é:

```powershell
npx create-expo-app@latest . --template blank-typescript
npx expo install --fix
npx expo-doctor
```

Antes disso, confirmar a versão LTS de Node homologada pelo Expo (ADR-016).
Não criar telas, backend ou GPS nesta fase.

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
