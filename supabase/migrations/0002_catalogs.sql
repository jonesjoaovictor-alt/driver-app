-- =============================================================================
-- 0002 — Motoristas, veículos e passageiros
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
--
-- Regras de origem:
--   MASTER_SPEC.md §5 (administração), §6 (limites), §9 (tabelas)
--   ADR-004 (is_active x availability), ADR-011 (heartbeat)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- drivers
-- -----------------------------------------------------------------------------

create table if not exists public.drivers (
  id            uuid primary key default gen_random_uuid(),
  profile_id    uuid not null unique references public.profiles (id) on delete restrict,
  is_active     boolean not null default true,
  availability  public.driver_availability not null default 'offline',
  last_seen_at  timestamptz,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  version       integer not null default 1 check (version >= 1)
);

comment on table public.drivers is
  'Cadastro operacional do motorista. is_active não é a mesma coisa que availability (ADR-004).';

drop trigger if exists trg_drivers_updated_at on public.drivers;
create trigger trg_drivers_updated_at
  before update on public.drivers
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- vehicles
-- -----------------------------------------------------------------------------

create table if not exists public.vehicles (
  id            uuid primary key default gen_random_uuid(),
  driver_id     uuid not null references public.drivers (id) on delete restrict,
  brand         text not null check (char_length(btrim(brand)) between 1 and 60),
  model         text not null check (char_length(btrim(model)) between 1 and 60),
  plate         text not null check (char_length(btrim(plate)) between 6 and 10),
  color         text not null check (char_length(btrim(color)) between 1 and 40),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  version       integer not null default 1 check (version >= 1)
);

-- Um veículo ativo por motorista (MASTER_SPEC.md §6).
create unique index if not exists ux_vehicles_one_active_per_driver
  on public.vehicles (driver_id)
  where is_active;

-- Placa única, sem diferenciar maiúsculas.
create unique index if not exists ux_vehicles_plate
  on public.vehicles (upper(btrim(plate)));

drop trigger if exists trg_vehicles_updated_at on public.vehicles;
create trigger trg_vehicles_updated_at
  before update on public.vehicles
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- passengers
-- -----------------------------------------------------------------------------

create table if not exists public.passengers (
  id            uuid primary key default gen_random_uuid(),
  name          text not null check (char_length(btrim(name)) between 1 and 120),
  phone         text check (phone is null or char_length(phone) <= 32),
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  version       integer not null default 1 check (version >= 1)
);

comment on table public.passengers is
  'Passageiros fictícios. Não usar dados de pessoas reais (MASTER_SPEC.md §3).';

drop trigger if exists trg_passengers_updated_at on public.passengers;
create trigger trg_passengers_updated_at
  before update on public.passengers
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Funções de contexto que dependem de drivers
-- -----------------------------------------------------------------------------

create or replace function public.current_driver_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select d.id
  from public.drivers d
  join public.profiles p on p.id = d.profile_id
  where p.auth_user_id = auth.uid()
    and p.is_active
    and d.is_active
  limit 1
$$;

create or replace function public.is_active_driver()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select public.current_driver_id() is not null
$$;

revoke all on function public.current_driver_id() from public;
revoke all on function public.is_active_driver() from public;
grant execute on function public.current_driver_id() to authenticated;
grant execute on function public.is_active_driver() to authenticated;

-- -----------------------------------------------------------------------------
-- Limite de cinco cadastros
-- -----------------------------------------------------------------------------
-- Protegido por trava de transação: dois cadastros simultâneos não podem
-- ultrapassar o limite (MASTER_SPEC.md §5).

create or replace function public.enforce_catalog_limit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_count integer;
  v_limit constant integer := 5;
begin
  perform pg_advisory_xact_lock(hashtext('public.' || tg_table_name));

  execute format('select count(*) from public.%I', tg_table_name) into v_count;

  if v_count >= v_limit then
    raise exception 'LIMITE_ATINGIDO'
      using errcode = '23514',
            hint = format('O limite de %s registros em %s já foi atingido.', v_limit, tg_table_name);
  end if;

  return new;
end
$$;

drop trigger if exists trg_drivers_limit on public.drivers;
create trigger trg_drivers_limit
  before insert on public.drivers
  for each row
  execute function public.enforce_catalog_limit();

drop trigger if exists trg_passengers_limit on public.passengers;
create trigger trg_passengers_limit
  before insert on public.passengers
  for each row
  execute function public.enforce_catalog_limit();

revoke all on function public.enforce_catalog_limit() from public;

-- -----------------------------------------------------------------------------
-- Índices de consulta
-- -----------------------------------------------------------------------------

create index if not exists ix_drivers_profile on public.drivers (profile_id);
create index if not exists ix_vehicles_driver on public.vehicles (driver_id);
create index if not exists ix_passengers_active on public.passengers (is_active);
