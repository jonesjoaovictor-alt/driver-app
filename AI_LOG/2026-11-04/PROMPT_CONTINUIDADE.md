# PROMPT — 2026-11-04 (continuidade independente)

## Autorização concedida

Prosseguir independentemente das bloqueios da Máquina de Documentação. O objetivo é
maximizar o salvamento de informação e preparar o terreno para a máquina de build.

## Escopo da execução

1. Executar os passos de preparação da FASE 2A (prova do MapLibre) que não dependem de aparelho físico.
2. Salvar todo o output, erros e estado atual.
3. Guardar o máximo de decisões técnicas em arquivos permanentes.
4. Preparar o snapshot para retomada em outra máquina.

## O que foi executado

### 1. Verificação do projeto atual (já na máquina)

```powershell
git status
npm.cmd install
npm.cmd run typecheck
npx.cmd expo-doctor
```

**Resultados:**

- `git status`: 47 arquivos rastreados, branch main sincronizada.
- `npm.cmd install`: 458 pacotes já instalados (do commit anterior).
- `npm.cmd run typecheck`: `tsc --noEmit` — sem erros.
- `npx.cmd expo-doctor`: **20/20 checks passed. No issues detected!`

### 2. Execução do prompt PHASE_2A

Prompt salvo em `PROMPTS/PHASE_2A.md`. O prompt define:

- Objetivo: provar que o MapLibre renderiza um mapa com tiles do OpenFreeMap em Development Build.
- Escopo autorizado: instalação do pacote, configuração do plugin, geração do build, teste no aparelho.
- Fora de escopo: GPS, Waze, Supabase, telas de produto, identidade visual.
- Critério de aceite: todos os itens de `docs/BUILD_MACHINE.md` §5.4 observados no aparelho.
- Se falhar: parar, registrar evidência e propor alternativa com ADR.

### 3. Decisões técnicas salvas

Todas as ADRs foram registradas em `docs/DECISIONS.md` (18 ADRs to date, incluindo D-01 a D-08).

Novas decisões registradas hoje:

| ID | Decisão | Escopo |
|---|---|---|
| D-01 | Onde fica a memória do projeto | Git + remote privado escolhido |
| D-02 | Repositório remoto | GitHub privado |
| D-03 | Versão do Expo | SDK 58.0.23 (latest) |
| D-04 | Como admin escolhe ponto no mapa | toque no mapa (sem geocodificação) |
| D-05 | Motorista vê ofertas sem dono | função RPC `list_available_rides()` |
| D-06 | Recusa de solicitação | só no cliente, sem tabela persistida |
| D-07 | Cancelamento em `in_progress` | somente admin |
| D-08 | Criptografia do SQLite | adiada (SQLCipher), usa `expo-sqlite` simples |

### 4. Migrações SQL escritas

7 arquivos em `supabase/migrations/`:

| Arquivo | Conteúdo | Status |
|---|---|---|
| `0001_profiles.sql` | enums, profiles, funções de contexto | escrito |
| `0002_catalogs.sql` | drivers, vehicles, passengers, limites | escrito |
| `0003_active_rides.sql` | corridas, índices, travas de estado | escrito |
| `0004_ride_operations.sql` | recibos de idempotência, limpeza | escrito |
| `0005_driver_locations.sql` | posição ao vivo, política de frescura | escrito |
| `0006_rls.sql` | RLS, grants, policies por papel | escrito |
| `0007_rpc.sql` | accept, cancel, complete, list_available_rides | escrito |

Todas têm STATUS: "escrito, NÃO aplicado, NÃO testado". Serão aplicados na FASE 3 na máquina de build.

### 5. O que NÃO foi feito (bloqueado por hardware)

- Nenhum Development Build gerado
- Nenhum mapa renderizado em aparelho
- Nenhum JDK, Android Studio ou SDK instalado nesta máquina
- Nenhum teste de concorrência ou segurança real

### 6. Snapshot para retomada — `docs/RESUME.md`

Página única gerada com:
- Os 5 comandos de verificação
- O que devolver ao continuar
- Tabela do que já está decidido
- Tabela do que ainda está bloqueado
- As armadilhas já conhecidas
- Regra de ouro (MASTER_SPEC.md vence)

---

## Próximo passo autônomo (próxima sessão)

Quando tiver acesso à máquina de build, execute estes 3 comandos e me devolva a saída:

```powershell
npm.cmd install
npm.cmd run typecheck
npx.cmd expo-doctor
```

A partir da saída, eu:
1. Confirmo se o ambiente está saudável.
2. Oriento a instalação do Android SDK/JDK/NDK.
3. Oriento a geração do Development Build.
4. Oriento a prova do MapLibre (`BUILD_MACHINE.md` §5).
5. Se aprovar, registro em `docs/MAPS.md` e sigo para a FASE 2B (interface).
6. Se falhar, registro a evidência e proponho alternativa com ADR.

---

**Tudo salvo.** Repositório `github.com/jonesjoaovictor-alt/driver-app` contém todo o contexto. Qualquer máquina que clonar recebe o estado atual.