-- =============================================================================
-- 0005 — Localização ao vivo do motorista
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
--
-- Regras de origem: MASTER_SPEC.md §9 e §11, ADR-012.
--
-- Uma linha por motorista, atualizada por upsert. A linha é REMOVIDA quando o
-- motorista fica offline. Não existe histórico de localização.
-- =============================================================================

create table if not exists public.driver_live_locations (
  driver_id     uuid primary key references public.drivers (id) on delete cascade,
  latitude      numeric(9, 6) not null check (latitude between -90 and 90),
  longitude     numeric(9, 6) not null check (longitude between -180 and 180),
  accuracy      numeric(8, 2) check (accuracy is null or accuracy >= 0),
  heading       numeric(6, 2) check (heading is null or heading between 0 and 360),
  speed         numeric(8, 2) check (speed is null or speed >= 0),
  recorded_at   timestamptz not null,
  updated_at    timestamptz not null default now(),

  -- Leitura do futuro é sinal de relógio errado ou dado adulterado.
  constraint ck_locations_not_future
    check (recorded_at <= now() + interval '5 minutes')
);

comment on table public.driver_live_locations is
  'Posição atual por motorista. Removida ao ficar offline. Sem histórico.';

drop trigger if exists trg_driver_locations_updated_at on public.driver_live_locations;
create trigger trg_driver_locations_updated_at
  before update on public.driver_live_locations
  for each row
  execute function public.set_updated_at();

-- Posição velha não deve ser exibida como atual (MASTER_SPEC.md §11).
create or replace function public.is_location_fresh(p_driver_id uuid, p_max_age_seconds integer default 120)
returns boolean
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.driver_live_locations l
    where l.driver_id = p_driver_id
      and l.recorded_at >= now() - make_interval(secs => p_max_age_seconds)
  )
$$;
