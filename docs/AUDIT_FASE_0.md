# Auditoria — FASE 0 e revisão da especificação

**Data:** 2026-11-03
**Máquina:** `jones` — Windows 10 Home Single Language, AMD64, 7,8 GB RAM
**Executor:** OpenCode
**Modo:** somente leitura. Nada foi instalado, alterado ou criado durante a
auditoria.

---

## Parte 1 — Ambiente

| # | Item | Resultado | Evidência |
|---|---|---|---|
| 1 | Diretório e isolamento | **APROVADO** | `C:\Users\jones\Documents\driveapp`, apenas `MASTER_SPEC.md`. Nenhum outro projeto acessado. |
| 2 | Node.js | **ATENÇÃO** | `v26.13.0` em `C:\Program Files\nodejs\node.exe`. Versão `current`, não LTS. |
| 3 | npm / npm.cmd | **ATENÇÃO** | `npm.cmd` 11.20.0 funciona. `npm.ps1` bloqueado pela Execution Policy. |
| 4 | Git | **BLOQUEADO** | Não instalado. |
| 5 | JDK | **BLOQUEADO** | Sem `java`, `JAVA_HOME` ou `C:\Program Files\Java`. |
| 6 | Android Studio | **BLOQUEADO** | Não instalado. |
| 7 | Android SDK | **BLOQUEADO** | Sem `ANDROID_HOME` e sem `%LOCALAPPDATA%\Android\Sdk`. |
| 8 | ADB | **BLOQUEADO** | Não encontrado. |
| 9 | Celular conectado | **NÃO VERIFICADO** | Requer adb. |
| 10 | Depuração USB | **NÃO VERIFICADO** | Requer adb. |
| 11 | Compatibilidade da stack | **BLOQUEADO** | Depende dos itens 4 a 9. |

### Conclusão da Parte 1

Esta máquina **não compila Android**, e não deve ser preparada para isso.
Papel definido: documentação, Git e organização. Compilação e testes de GPS
acontecem na máquina de build, com aparelho físico.

Ação executada após autorização: instalação do Git 2.56.0.4, única
dependência necessária aqui.

---

## Parte 2 — Revisão da especificação 1.0.0

O documento estava acima da média: regras críticas no banco, proibições
explícitas, fases bem separadas. Foram encontrados cinco bloqueadores,
quatro contradições e oito lacunas.

### Bloqueadores

| ID | Achado | Resolução |
|---|---|---|
| B-01 | `driver_id` sem definir nulabilidade em `requested` | ADR-003 |
| B-02 | Nenhum caminho para criar contas de motorista sem `service_role` no cliente | ADR-005 |
| B-03 | "Motorista só vê seus dados" impedia ver ofertas sem dono | ADR-010 |
| B-04 | Recusa testada, mas inexistente no modelo de estados | ADR-007 |
| B-05 | Regras de cancelamento nunca enumeradas | ADR-008 |

### Contradições

| ID | Achado | Resolução |
|---|---|---|
| C-01 | Recibo de idempotência exigido sem tabela, e histórico proibido | ADR-009 |
| C-02 | `status` com três significados | ADR-004 |
| C-03 | Duas estruturas de documentação concorrentes | ADR-001 |
| C-04 | Pasta `driver-app` versus `driveapp` | ADR-002 |

### Lacunas

| ID | Achado | Resolução |
|---|---|---|
| L-01 | Sem heartbeat; motorista fica `busy` para sempre | ADR-011 |
| L-02 | Localização não era apagada ao ficar offline | ADR-012 |
| L-03 | Admin teria de digitar coordenadas manualmente | ADR-014 |
| L-04 | SQLite sem contrato e sem criptografia | ADR-013 |
| L-05 | Sem `minSdk`/`targetSdk` | Spec §16 (24 / a fixar) |
| L-06 | Sem repositório remoto | ADR-015 |
| L-07 | Faltavam `arrived_at`, `cancelled_at`, `cancelled_by` | Spec §7 |
| L-08 | Sem `version` em cadastros | Spec §9 |

### Riscos técnicos

| ID | Risco | Mitigação |
|---|---|---|
| R-01 | MapLibre é módulo nativo; pode não funcionar no Expo atual | Prova isolada na FASE 2, antes das telas |
| R-02 | Node 26 fora do LTS | ADR-016 |
| R-03 | 8 GB de RAM para Gradle e Android Studio | Build em aparelho físico; sem emulador |

### Itens aceitos sem alteração

-   Um único aplicativo com administração oculta por sete toques.
-   Passageiros fictícios sem login.
-   Ausência de histórico de viagens.
-   Conclusão e cancelamento transacionais.
-   Waze por Deep Links, sem depender de retorno.
-   Realtime como notificação, não como verdade.
