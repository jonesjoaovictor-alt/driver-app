# DRIVER APP

Aplicativo Android de transporte para testes controlados, com interface de
motorista e administração oculta. Arquitetura, código e identidade próprios.
A Uber é apenas referência de experiência.

> **Estado atual: FASE 1B concluída — projeto Expo criado.**
> Existe a estrutura e o ponto de entrada, **sem telas de produto, backend ou
> GPS**. A FASE 2 começa pela prova do MapLibre.

## Leia nesta ordem

| Ordem | Arquivo | Para que serve |
|---|---|---|
| 1 | [`MASTER_SPEC.md`](MASTER_SPEC.md) | Documento canônico. Todas as regras do produto. |
| 2 | [`AGENTS.md`](AGENTS.md) | Contrato de trabalho para qualquer IA ou pessoa. |
| 3 | [`docs/DECISIONS.md`](docs/DECISIONS.md) | Decisões registradas e o porquê de cada uma. |
| 4 | [`docs/AI_HANDOFF.md`](docs/AI_HANDOFF.md) | Onde o projeto parou e o que vem agora. |
| 5 | [`docs/TASKS.md`](docs/TASKS.md) | Backlog por fase. |
| 6 | [`docs/DATABASE.md`](docs/DATABASE.md) | Modelo de dados e restrições. |
| 7 | [`docs/ENVIRONMENT.md`](docs/ENVIRONMENT.md) | O que existe em cada computador. |

## Regra de ouro

`MASTER_SPEC.md` e `docs/DECISIONS.md` são a verdade do projeto. Se o código,
um prompt ou uma conversa discordar deles, **o documento vence** — ou o
documento é corrigido por decisão explícita e registrada.

## Estrutura

```text
driver-app/
├── MASTER_SPEC.md          regra do produto (canônico)
├── AGENTS.md               contrato de trabalho
├── README.md               este arquivo
├── CHANGELOG.md            histórico de versões da documentação
├── PROMPTS/                prompts oficiais reaproveitáveis
├── AI_LOG/                 registro de cada sessão com IA
├── docs/                   arquitetura, decisões, tarefas, ambiente
├── src/                    aplicativo (a partir da FASE 1B)
├── supabase/               migrações, funções, seed (FASE 3)
├── tests/                  testes automatizados
└── assets/                 ícones, imagens, fontes
```

## Duas máquinas

| Máquina | Papel | Pode compilar Android? |
|---|---|---|
| `jones` — Windows 10, 8 GB | Documentação, Git, organização | **Não** (sem JDK, SDK, ADB) |
| Máquina de build | Compilação, aparelho físico, testes de GPS | Sim |

Nada neste repositório deve depender de uma máquina específica. Tudo que for
necessário para continuar está escrito aqui dentro.

## Privacidade

Passageiros são registros fictícios. Não usar dados de pessoas reais. Não
armazenar histórico de trajetos, conforme a seção 7 do `MASTER_SPEC.md`.
