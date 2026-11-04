-- =============================================================================
-- 0009 — Integridade de timestamps de corridas ativas
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
--
-- Regras de origem:
--   MASTER_SPEC.md §6 (validações), §7 (estados e campos)
--   Correção da constraint ck_rides_started_at em 0003_active_rides.sql
-- =============================================================================
--
-- A constraint original ck_rides_started_at na migration 0003 verifica que
-- started_at >= accepted_at, mas não verifica que started_at >= arrived_at.
-- Uma corrida não pode iniciar (in_progress) antes de o motorista confirmar
-- a chegada ao embarque (arrived).
--
-- Como a migration 0003 já está versionada no Git e não pode ser alterada
-- silenciosamente, esta migration adiciona a constraint faltante.
-- =============================================================================

alter table public.active_rides
  add constraint ck_rides_started_after_arrived
    check (
      started_at is null
      or arrived_at is null
      or started_at >= arrived_at
    );
