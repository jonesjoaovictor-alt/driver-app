-- =============================================================================
-- 0001 — Enums, perfis e funções de contexto
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
-- Aplicar somente quando existir projeto Supabase e após revisão da FASE 3.
--
-- Regras de origem:
--   MASTER_SPEC.md §9 (profiles), §10 (segurança)
--   ADR-004 (is_active x availability), ADR-006 (papel único)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Enums
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type where typname = 'profile_role') then
    create type public.profile_role as enum ('admin', 'driver');
  end if;

  if not exists (select 1 from pg_type where typname = 'driver_availability') then
    create type public.driver_availability as enum ('offline', 'online', 'busy');
  end if;

  if not exists (select 1 from pg_type where typname = 'ride_status') then
    create type public.ride_status as enum (
      'requested',
      'accepted',
      'driver_arriving',
      'arrived',
      'in_progress'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'ride_operation_type') then
    create type public.ride_operation_type as enum (
      'accept', 'arrive', 'start', 'complete', 'cancel'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'cancel_actor') then
    create type public.cancel_actor as enum ('admin', 'driver');
  end if;
end
$$;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------

create table if not exists public.profiles (
  id            uuid primary key default gen_random_uuid(),
  auth_user_id  uuid not null unique references auth.users (id) on delete cascade,
  full_name     text not null check (char_length(btrim(full_name)) between 1 and 120),
  phone         text check (phone is null or char_length(phone) <= 32),
  role          public.profile_role not null default 'driver',
  is_active     boolean not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  version       integer not null default 1 check (version >= 1)
);

comment on table public.profiles is
  'Perfil de acesso. role e is_active são imutáveis pelo cliente (ADR-006).';
comment on column public.profiles.auth_user_id is
  'Vínculo com auth.users. Nunca exposto ao cliente.';

-- -----------------------------------------------------------------------------
-- Atualização automática de updated_at
-- -----------------------------------------------------------------------------
-- version NÃO é incrementada aqui de propósito: cada operação de negócio
-- incrementa explicitamente dentro da sua transação, o que permite detectar
-- escrita concorrente (MASTER_SPEC.md §8).

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Funções de contexto
-- -----------------------------------------------------------------------------
-- Todas são security definer porque leem tabelas protegidas por RLS.
-- O search_path fixo impede sequestro de função por schema malicioso.

create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select p.id
  from public.profiles p
  where p.auth_user_id = auth.uid()
    and p.is_active
  limit 1
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.profiles p
    where p.auth_user_id = auth.uid()
      and p.role = 'admin'
      and p.is_active
  )
$$;

-- is_active_driver() e current_driver_id() dependem da tabela drivers e são
-- criadas na migração 0002, imediatamente após a tabela existir.

-- -----------------------------------------------------------------------------
-- Proteção de campos sensíveis do perfil
-- -----------------------------------------------------------------------------
-- O cliente pode editar nome e telefone. Não pode mudar papel, vínculo de
-- autenticação nem reativar a própria conta.

create or replace function public.protect_profile_fields()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.auth_user_id is distinct from old.auth_user_id
     or new.role is distinct from old.role
     or new.is_active is distinct from old.is_active then
    if not public.is_admin() then
      raise exception 'ALTERACAO_NAO_PERMITIDA'
        using errcode = '42501',
              hint = 'Somente a administração altera papel, vínculo ou ativação.';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists trg_profiles_protect on public.profiles;
create trigger trg_profiles_protect
  before update on public.profiles
  for each row
  execute function public.protect_profile_fields();

-- -----------------------------------------------------------------------------
-- Permissões de execução
-- -----------------------------------------------------------------------------

revoke all on function public.current_profile_id() from public;
revoke all on function public.is_admin() from public;
revoke all on function public.protect_profile_fields() from public;

grant execute on function public.current_profile_id() to authenticated;
grant execute on function public.is_admin() to authenticated;
