# PHASE_2A — Prova do MapLibre

Prompt para executar na máquina de build. Detalhes operacionais em
`docs/BUILD_MACHINE.md`.

## Objetivo

Provar, em aparelho Android físico, que `@maplibre/maplibre-react-native`
renderiza um mapa com tiles do OpenFreeMap dentro de um Development Build.

**Não é para construir tela do produto.** É um teste de viabilidade técnica.

## Por que isso vem antes de tudo

O MapLibre é módulo nativo. Se ele não funcionar na combinação atual de Expo
58 + RN 0.88.1, a camada de mapa inteira muda — e todas as telas que dependem
de mapa mudariam junto. Provar antes de desenhar evita refazer a FASE 2.

## Escopo autorizado

-   Instalar o pacote MapLibre.
-   Configurar o plugin do Expo, conforme a documentação do próprio pacote.
-   Gerar o Development Build.
-   Exibir mapa, marcador fixo e atribuição.
-   Registrar o resultado em `docs/MAPS.md`.

## Fora de escopo

-   GPS real, permissões de localização, segundo plano.
-   Waze.
-   Supabase, login, banco.
-   Telas de produto, identidade visual, navegação.
-   Otimização de bateria ou desempenho.

## Critério de aceite

Todos os itens de `docs/BUILD_MACHINE.md` §5.4, observados no aparelho.

## Se falhar

Parar, registrar evidência completa e propor alternativas com prós e contras.
Mudança de biblioteca de mapa é decisão de arquitetura: exige ADR e
autorização do responsável. Não trocar por conta própria.

## Resultado esperado

`docs/MAPS.md` preenchido com:

-   versões exatas usadas;
-   resultado de cada critério de aceite;
-   erros encontrados, se houver;
-   decisão: aprovado, aprovado com ressalva, ou reprovado.
