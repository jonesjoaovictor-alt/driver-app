# Mapas

Status: **prova pendente (P-01)**. Nenhum código de mapa foi escrito ainda.

## Decisão vigente

| Item | Valor |
|---|---|
| Renderizador | MapLibre React Native |
| Versão alvo | 11.5.1 |
| Fonte de tiles | OpenFreeMap (a validar) |
| Estilo inicial | `https://tiles.openfreemap.org/styles/liberty` |
| Geocodificação | Não usar nesta versão |
| Roteamento | Não usar nesta versão |
| Navegação | Waze por Deep Link (FASE 8) |

Ver `docs/DECISIONS.md` ADR-017 e `MASTER_SPEC.md` §12.

## Por que a prova é obrigatória

MapLibre React Native é módulo nativo. Não roda no Expo Go. Depende de
Development Build, do plugin do Expo e da compatibilidade com a arquitetura
nova do React Native. Nenhuma dessas coisas se prova lendo documentação.

## Resultado da prova

**PENDENTE.** Preencher após executar `PROMPTS/PHASE_2A.md`.

| Item | Resultado | Evidência |
|---|---|---|
| Versão do pacote instalada | — | — |
| `expo prebuild` sem erro | — | — |
| Compilação Gradle | — | — |
| Mapa renderiza tiles | — | — |
| Arrastar e zoom | — | — |
| Marcador em coordenada fixa | — | — |
| Atribuição visível | — | — |
| Sobrevive a minimizar/reabrir | — | — |
| Erros no `adb logcat` | — | — |

### Decisão

-   [ ] Aprovado
-   [ ] Aprovado com ressalva
-   [ ] Reprovado — alternativas propostas abaixo

## Alternativas, se reprovar

Avaliar somente se a prova falhar. Nenhuma foi escolhida.

| Alternativa | Prós | Contras |
|---|---|---|
| Versão anterior do MapLibre | pode já ser compatível | perde correções |
| `react-native-maps` | maduro, usa Google Maps | depende de chave e serviço do Google |
| Mapa adiado para fase posterior | não bloqueia o resto | sem feedback visual de posição |

Qualquer troca exige ADR e autorização.
