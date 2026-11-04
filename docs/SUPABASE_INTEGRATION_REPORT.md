# SUPABASE_INTEGRATION_REPORT — Relatório de Integração Supabase

**Data:** 2026-11-04  
**Repositório:** `driver-app-main\driver-app-main`  
**Commit de referência:** `b902312`  
**Projeto Supabase:** `igsmfodwdobetfeozuim`  
**URL:** `https://igsmfodwdobetfeozuim.supabase.co`  
**Plataforma:** Android exclusivamente (ADR-020)

---

## 1. Correções Realizadas

### A-1 — Integridade de timestamps de corridas (0003_active_rides.sql)

**Problema:** A constraint `ck_rides_started_at` na migration 0003 verificava que `started_at >= accepted_at`, mas não verificava que `started_at >= arrived_at`. Uma corrida poderia iniciar antes de o motorista confirmar a chegada.

**Correção:** Criada migration `0009_active_rides_timestamps.sql` que adiciona a constraint:

```sql
alter table public.active_rides
  add constraint ck_rides_started_after_arrived
    check (
      started_at is null
      or arrived_at is null
      or started_at >= arrived_at
    );
```

**Por que migration 0009 (corretiva) em vez de alterar 0003:**
- Nenhuma migration foi aplicada remotamente.
- A migration 0003 já está versionada no Git; alterá-la silencientemente quebraria rastreabilidade.
- A migration corretiva preserva o histórico e é reversível.

### A-2 — Função total_fare_by_driver (0007_rpc.sql)

**Encontrado:** A função consulta `active_rides` com `status = 'completed'`, mas conforme MASTER_SPEC.md §7, corridas concluídas são removidas de `active_rides`. A função sempre retornará 0.

**Análise:**
- Não é referenciada em nenhum arquivo TypeScript do `src/`.
- Não há chamada em nenhum serviço do aplicativo.
- Não há definição na MASTER_SPEC.md.
- Não há alternativa coerente com a especificação (que proíbe histórico de viagens permanente).

**Decisão:** Manter a função sem uso e documentar a pendência. Não inventar estrutura de faturamento.

### A-4 — Limite de cadastros (0002_catalogs.sql)

**Revisado:** O limite de cinco registros (incluindo inativos) é mantido conforme interpretação atual da especificação. O `pg_advisory_xact_lock` garante concorrência segura para cadastros simultâneos. Não houve alteração.

### A-5 — Constraint de localização (0005_driver_locations.sql)

**Revisado:** A constraint `ck_locations_not_future` usa `now()` em CHECK. Isso é volátil mas funciona para validação de inserção. A função `upsert_location` já valida coordenadas (latitude/longitude) com defesa em profundidade. Não houve alteração.

---

## 2. Arquivos Criados

| Arquivo | Propósito |
|---------|-----------|
| `supabase/migrations/0009_active_rides_timestamps.sql` | Constraint `started_at >= arrived_at` para corridas ativas |
| `supabase/config.toml` | Configuração da Supabase CLI (projeto `igsmfodwdobetfeozuim`) |
| `.env` | Variáveis de ambiente locais (URL do Supabase + placeholder para chave anon) |
| `docs/SUPABASE_INTEGRATION_REPORT.md` | Este relatório |

---

## 3. Arquivos Modificados

Nenhum arquivo existente foi modificado. Apenas novos arquivos foram criados.

---

## 4. Decisões Técnicas

| Decisão | Justificativa |
|---------|---------------|
| Migration corretiva 0009 em vez de alterar 0003 | Preservar rastreabilidade do Git; não alterar migration já versionada |
| Manter `total_fare_by_driver` sem uso | Não há alternativa coerente com a spec (proíbe histórico de viagens) |
| Manter limite de 5 incluindo inativos | Conforme interpretação atual da especificação |
| Manter `now()` em CHECK de localização | Funciona para validação de inserção; função `upsert_location` já valida coordenadas |

---

## 5. Testes e Resultados

| Teste | Resultado |
|-------|-----------|
| `npm.cmd run typecheck` | ✅ Sem erros |
| `npx.cmd expo-doctor` | ✅ 20/20 checks aprovados |
| `.env` no `.gitignore` | ✅ Confirmado (linha 31) |
| `.env.example` sem valores reais | ✅ Confirmado |

---

## 6. Estado do Git

| Item | Valor |
|------|-------|
| Branch | `main` |
| Commit HEAD | `b902312` (antes das novas alterações) |
| `origin/main` | `b902312` (sincronizado) |
| Working tree | Limpo (antes das novas alterações) |
| Novos arquivos | `0009_active_rides_timestamps.sql`, `config.toml`, `.env` |
| `.env` versionado | ❌ Não (ignorado pelo `.gitignore`) |

---

## 7. Confirmação de Proteção de Credenciais

| Item | Status |
|------|--------|
| `.env` não commitado | ✅ Ignorado pelo `.gitignore` (linha 31) |
| `service_role` no aplicativo | ❌ Ausente (proibido) |
| Chaves privadas no repositório | ❌ Ausentes |
| `.env` com valores reais de chave anon | ⚠️ Placeholder — requer preenchimento pelo proprietário |

**Aviso:** O arquivo `.env` foi criado com a URL do projeto (`https://igsmfodwdobetfeozuim.supabase.co`) mas com placeholder para a chave anon (`SUA_CHAVE_ANON_AQUI`). O proprietário deve preencher o valor real do painel do Supabase.

---

## 8. Pendências para Integração Remota

| Item | Status | Próxima ação |
|------|--------|--------------|
| Vincular Supabase CLI (`supabase link`) | ❌ Pendente | Executar após autorização |
| Aplicar migrations 0001-0009 | ❌ Pendente | Executar após `supabase link` |
| Desativar cadastro público no Supabase Auth | ❌ Pendente | Ação manual no painel |
| Provisionar primeiro administrador | ❌ Pendente | Procedimento manual no painel |
| Implantar Edge Function `admin-create-driver` | ❌ Pendente | Executar após `supabase link` |
| Executar matriz de testes de segurança (`docs/SECURITY.md` §10) | ❌ Pendente | Após banco aplicado |
| Preencher `.env` com chave anon real | ❌ Pendente | Fornecido pelo proprietário |
| Prova do MapLibre (FASE 2A) | ❌ Pendente | Na máquina de build |

---

## 9. Próxima Sequência de Comandos (sem executar)

```powershell
# 1. Vincular o projeto Supabase (após autorização)
supabase link --project-ref igsmfodwdobetfeozuim

# 2. Aplicar migrations pendentes
supabase db push

# 3. Implantar Edge Functions
supabase functions deploy admin-create-driver

# 4. Verificar status do banco
supabase db diff
```

**Todos esses comandos requerem autorização explícita do proprietário antes da execução.**

---

## 10. Arquivos para Continuidade

| Arquivo | Caminho | Propósito |
|---------|---------|-----------|
| Especificação oficial | `MASTER_SPEC.md` | Regras canônicas do produto |
| Contrato de trabalho | `AGENTS.md` | Regras para IAs e desenvolvedores |
| Handoff de sessão | `docs/AI_HANDOFF.md` | Estado do projeto e próximo passo |
| Tarefas | `docs/TASKS.md` | Backlog por fase |
| Decisões | `docs/DECISIONS.md` | ADRs, incluindo ADR-020 |
| Segurança | `docs/SECURITY.md` | Matriz de acesso e testes de segurança |
| Integração Supabase | `docs/SUPABASE_INTEGRATION_REPORT.md` | Este relatório |
| Banco de dados | `docs/DATABASE.md` | Modelo de dados e status das migrações |
| Migrações SQL | `supabase/migrations/0001_*.sql` a `0009_*.sql` | Schema do banco (não aplicadas) |
| Edge Function | `supabase/functions/admin-create-driver/index.ts` | Criação de contas de motorista |
| Configuração CLI | `supabase/config.toml` | Configuração do Supabase CLI |
| Variáveis de ambiente | `.env.example` | Exemplo (não versionar `.env`) |

---

**Conclusão:** As correções técnicas A-1, A-4 e A-5 foram analisadas. A correção A-1 foi implementada via migration 0009. A correção A-2 foi analisada e mantida sem uso com documentação. A configuração local do Supabase foi preparada (`config.toml` e `.env`). O projeto está pronto para vinculação remota, aguardando autorização.
