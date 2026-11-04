# Erros e avisos capturados — 2026-11-04

## 1. Erro de sintaxe do PowerShell (não relacionado ao projeto)

```
No linha:6 caractere:3
+ & $npm run typecheck 2>&1 | Out-String
+   ~~~~
    + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
    + FullyQualifiedErrorId : BadExpression
```

**Contexto:** O caractere `&` no PowerShell tem significado especial (execução de comando). Quando usado dentro de uma string passada para `Out-String`, ele quebra a expressão. A solução foi usar `&` diretamente sem a concatenação `| Out-String`, ou escapar adequadamente.

**Lição:** Ao capturar saída de comandos em variáveis, prefira redirecionamento (`2>&1 > captura.txt`) em vez de pipeline no PowerShell, ou use forma explícita `cmd /c`.

## 2. `expo-doctor` — 20/20 checks passed ✅

Nenhum problema detectado. Projeto Expo SDK 58 está em condições de Development Build.

## 3. `tsc --noEmit` — sem erros ✅

TypeScript compilou sem erros. O projeto mantém a tipagem estrita.

---

## Arquivos salvos neste commit (5fec8f3)

| Arquivo | Tipo | Status |
|---|---|---|
| `supabase/migrations/0001_profiles.sql` | Migração SQL | escrita, não aplicada |
| `supabase/migrations/0002_catalogs.sql` | Migração SQL | escrita, não aplicada |
| `supabase/migrations/0003_active_rides.sql` | Migração SQL | escrita, não aplicada |
| `supabase/migrations/0004_ride_operations.sql` | Migração SQL | escrita, não aplicada |
| `supabase/migrations/0005_driver_locations.sql` | Migração SQL | escrita, não aplicada |
| `supabase/migrations/0006_rls.sql` | Migração SQL | escrita, não aplicada |
| `supabase/migrations/0007_rpc.sql` | Migração SQL | escrita, não aplicada |
| `docs/SECURITY.md` | Documento de política | escrito |
| `docs/RESUME.md` | Página de retomada | escrita |
| `docs/BUILD_MACHINE.md` | Guia da máquina de build | escrito |
| `docs/MAPS.md` | Ficha da prova do mapa | escrito |
| `PROMPTS/PHASE_2A.md` | Prompt da prova do MapLibre | escrito |
| `docs/AI_HANDOFF.md` | Handoff da sessão | atualizado |
| `docs/TASKS.md` | Tarefas por fase | atualizado |
| `docs/DECISIONS.md` | ADRs e opções Descartadas | atualizado |
| `CHANGELOG.md` | Histórico de versões | atualizado |
| `docs/AUDIT_FASE_0.md` | Relatório da auditoria | atualizado |

---

## Próximo passo autônomo

Quando tiver acesso à máquina de build, execute:

```powershell
git clone https://github.com/jonesjoaovictor-alt/driver-app.git
cd driver-app
npm.cmd install
npm.cmd run typecheck
npx.cmd expo-doctor
```

Depois me devolva a saída destes 3 comandos. A partir daí eu conduzo a prova do MapLibre.

Se houver erro na instalação ou na verificação, copie a mensagem completa e me devolva — eu diagnostico.

---
Fim do registro 2026-11-04.