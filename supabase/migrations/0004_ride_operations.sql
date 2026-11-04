-- =============================================================================
-- 0004 — Recibos de operação (idempotência)
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
--
-- Regras de origem: MASTER_SPEC.md §7 "Recibos de operação", ADR-009.
--
-- NÃO é histórico de viagens. Não guarda coordenada, trajeto, nome, telefone
-- nem valor. Expira em 30 dias.
-- =============================================================================

create table if not exists public.ride_operations (
  id                uuid primary key default gen_random_uuid(),
  ride_id           uuid not null,
  operation         public.ride_operation_type not null,
  actor_profile_id  uuid not null references public.profiles (id) on delete cascade,
  idempotency_key   uuid not null unique,
  created_at        timestamptz not null default now(),
  expires_at        timestamptz not null default now() + interval '30 days'
);

comment on table public.ride_operations is
  'Recibo de idempotência com retenção de 30 dias. Não é histórico de viagens.';

comment on column public.ride_operations.ride_id is
  'Sem chave estrangeira de propósito: a corrida é removida antes do recibo.';

create index if not exists ix_ride_operations_ride
  on public.ride_operations (ride_id);

create index if not exists ix_ride_operations_expires
  on public.ride_operations (expires_at);

-- Limpeza diária. Deve ser agendada por pg_cron ou Edge Function agendada.
create or replace function public.purge_expired_ride_operations()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_removed integer;
begin
  delete from public.ride_operations
  where expires_at < now();

  get diagnostics v_removed = row_count;
  return v_removed;
end
$$;

revoke all on function public.purge_expired_ride_operations() from public;

-- Apenas o papel de serviço executa a limpeza.
do $$
begin
  if exists (select 1 from pg_roles where rolname = 'service_role') then
    execute 'grant execute on function public.purge_expired_ride_operations() to service_role';
  end if;
end
$$;
