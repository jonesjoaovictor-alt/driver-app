-- =============================================================================
-- 0003 — Corridas ativas
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
--
-- Regras de origem:
--   MASTER_SPEC.md §6 (validações), §7 (estados e campos),
--                   §8 (concorrência), ADR-003 (nulos em requested),
--                   ADR-008 (matriz de cancelamento)
--
-- A tabela guarda SOMENTE corridas não terminadas. Conclusão e cancelamento
-- removem a linha. Não existe tabela de histórico (MASTER_SPEC.md §7).
-- =============================================================================

create table if not exists public.active_rides (
  id                     uuid primary key default gen_random_uuid(),
  passenger_id           uuid not null references public.passengers (id) on delete restrict,
  driver_id              uuid references public.drivers (id) on delete restrict,
  vehicle_id             uuid references public.vehicles (id) on delete restrict,

  pickup_latitude        numeric(9, 6) not null check (pickup_latitude between -90 and 90),
  pickup_longitude       numeric(9, 6) not null check (pickup_longitude between -180 and 180),
  pickup_label           text not null check (char_length(btrim(pickup_label)) between 1 and 120),

  destination_latitude   numeric(9, 6) not null check (destination_latitude between -90 and 90),
  destination_longitude  numeric(9, 6) not null check (destination_longitude between -180 and 180),
  destination_label      text not null check (char_length(btrim(destination_label)) between 1 and 120),

  estimated_fare_cents   integer not null check (estimated_fare_cents >= 0),

  status                 public.ride_status not null default 'requested',

  created_at             timestamptz not null default now(),
  accepted_at            timestamptz,
  arrived_at             timestamptz,
  started_at             timestamptz,

  cancelled_at           timestamptz,
  cancelled_by           public.cancel_actor,
  cancel_reason          text check (cancel_reason is null or char_length(cancel_reason) <= 280),

  updated_at             timestamptz not null default now(),
  version                integer not null default 1 check (version >= 1),

  -- Motorista e veículo existem juntos ou não existem (ADR-003).
  constraint ck_rides_driver_vehicle_together
    check ((driver_id is null) = (vehicle_id is null)),

  -- Em requested, ninguém está atribuído.
  constraint ck_rides_requested_unassigned
    check (status <> 'requested' or driver_id is null),

  -- Fora de requested, sempre há motorista.
  constraint ck_rides_assigned_when_active
    check (status = 'requested' or driver_id is not null),

  -- Timestamps coerentes com o estado.
  constraint ck_rides_accepted_at
    check (accepted_at is null or accepted_at >= created_at),
  constraint ck_rides_started_at
    check (started_at is null or (accepted_at is not null and started_at >= accepted_at)),
  constraint ck_rides_arrived_at
    check (arrived_at is null or (accepted_at is not null and arrived_at >= accepted_at)),

  -- dados de cancelamento aparecem juntos
  constraint ck_rides_cancel_fields
    check (
      (cancelled_at is null and cancelled_by is null)
      or (cancelled_at is not null and cancelled_by is not null)
    )
);

comment on table public.active_rides is
  'Somente corridas não terminadas. Conclusão e cancelamento removem a linha.';

-- Uma corrida ativa por passageiro, inclusive antes de ser aceita.
create unique index if not exists ux_active_rides_passenger
  on public.active_rides (passenger_id);

-- Uma corrida ativa por motorista. Parcial porque requested não tem motorista.
create unique index if not exists ux_active_rides_driver
  on public.active_rides (driver_id)
  where driver_id is not null;

create index if not exists ix_active_rides_status
  on public.active_rides (status);

create index if not exists ix_active_rides_created
  on public.active_rides (created_at);

drop trigger if exists trg_active_rides_updated_at on public.active_rides;
create trigger trg_active_rides_updated_at
  before update on public.active_rides
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Atribuição imutável
-- -----------------------------------------------------------------------------
-- Motorista e veículo são definidos na aceitação e não mudam depois.
-- Trocar veículo durante corrida ativa é proibido (MASTER_SPEC.md §5).

create or replace function public.protect_ride_assignment()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if old.driver_id is not null and new.driver_id is distinct from old.driver_id then
    raise exception 'TROCA_DE_MOTORISTA_PROIBIDA' using errcode = '42501';
  end if;

  if old.vehicle_id is not null and new.vehicle_id is distinct from old.vehicle_id then
    raise exception 'TROCA_DE_VEICULO_PROIBIDA' using errcode = '42501';
  end if;

  return new;
end
$$;

drop trigger if exists trg_active_rides_protect_assignment on public.active_rides;
create trigger trg_active_rides_protect_assignment
  before update on public.active_rides
  for each row
  execute function public.protect_ride_assignment();

revoke all on function public.protect_ride_assignment() from public;

-- -----------------------------------------------------------------------------
-- Cadastros não podem ser desativados durante corrida ativa
-- -----------------------------------------------------------------------------

create or replace function public.prevent_deactivation_during_ride()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if new.is_active = false and old.is_active = true then
    if tg_table_name = 'drivers' then
      if exists (select 1 from public.active_rides r where r.driver_id = new.id) then
        raise exception 'MOTORISTA_EM_CORRIDA' using errcode = '23514';
      end if;
      new.availability := 'offline';
    elsif tg_table_name = 'vehicles' then
      if exists (select 1 from public.active_rides r where r.vehicle_id = new.id) then
        raise exception 'VEICULO_EM_CORRIDA' using errcode = '23514';
      end if;
    end if;
  end if;

  return new;
end
$$;

drop trigger if exists trg_drivers_prevent_deactivation on public.drivers;
create trigger trg_drivers_prevent_deactivation
  before update on public.drivers
  for each row
  execute function public.prevent_deactivation_during_ride();

drop trigger if exists trg_vehicles_prevent_deactivation on public.vehicles;
create trigger trg_vehicles_prevent_deactivation
  before update on public.vehicles
  for each row
  execute function public.prevent_deactivation_during_ride();

revoke all on function public.prevent_deactivation_during_ride() from public;

-- -----------------------------------------------------------------------------
-- Passageiro desativado não gera nova solicitação
-- -----------------------------------------------------------------------------

create or replace function public.check_passenger_active()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.passengers p where p.id = new.passenger_id and p.is_active
  ) then
    raise exception 'PASSAGEIRO_INATIVO' using errcode = '23514';
  end if;
  return new;
end
$$;

drop trigger if exists trg_active_rides_passenger_active on public.active_rides;
create trigger trg_active_rides_passenger_active
  before insert on public.active_rides
  for each row
  execute function public.check_passenger_active();

revoke all on function public.check_passenger_active() from public;
