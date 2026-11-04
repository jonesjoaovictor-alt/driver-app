-- =============================================================================
-- 0006 — Row Level Security
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, NÃO testado.
--
-- Regras de origem: MASTER_SPEC.md §10, ADR-010, ADR-019.
--
-- Princípio: o cliente autenticado quase não escreve direto. Toda transição de
-- corrida passa por RPC (0007). Aqui só definimos o que pode ser LIDO e as
-- poucas escritas de cadastro permitidas à administração.
-- =============================================================================

alter table public.profiles              enable row level security;
alter table public.drivers               enable row level security;
alter table public.vehicles              enable row level security;
alter table public.passengers            enable row level security;
alter table public.active_rides          enable row level security;
alter table public.ride_operations       enable row level security;
alter table public.driver_live_locations enable row level security;

-- -----------------------------------------------------------------------------
-- Grants base
-- -----------------------------------------------------------------------------
-- RLS não substitui GRANT. Sem GRANT, nada é acessível. Com GRANT e RLS, as
-- policies filtram linhas.

revoke all on public.profiles              from anon, authenticated;
revoke all on public.drivers               from anon, authenticated;
revoke all on public.vehicles              from anon, authenticated;
revoke all on public.passengers            from anon, authenticated;
revoke all on public.active_rides          from anon, authenticated;
revoke all on public.ride_operations       from anon, authenticated;
revoke all on public.driver_live_locations from anon, authenticated;

grant select on public.profiles              to authenticated;
grant update on public.profiles              to authenticated;

grant select on public.drivers               to authenticated;
grant update on public.drivers               to authenticated;
grant insert on public.drivers               to authenticated;

grant select, insert, update on public.vehicles to authenticated;
grant delete on public.vehicles                 to authenticated;

grant select, insert, update on public.passengers to authenticated;
grant delete on public.passengers                 to authenticated;

grant select on public.active_rides          to authenticated;
grant select on public.ride_operations       to authenticated;
grant select on public.driver_live_locations to authenticated;

-- -----------------------------------------------------------------------------
-- profiles
-- -----------------------------------------------------------------------------

drop policy if exists profiles_select on public.profiles;
create policy profiles_select
  on public.profiles for select
  to authenticated
  using (id = public.current_profile_id() or public.is_admin());

drop policy if exists profiles_update on public.profiles;
create policy profiles_update
  on public.profiles for update
  to authenticated
  using (id = public.current_profile_id() or public.is_admin())
  with check (id = public.current_profile_id() or public.is_admin());

-- -----------------------------------------------------------------------------
-- drivers
-- -----------------------------------------------------------------------------

drop policy if exists drivers_select on public.drivers;
create policy drivers_select
  on public.drivers for select
  to authenticated
  using (id = public.current_driver_id() or public.is_admin());

drop policy if exists drivers_admin_write on public.drivers;
create policy drivers_admin_write
  on public.drivers for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- vehicles
-- -----------------------------------------------------------------------------

drop policy if exists vehicles_select on public.vehicles;
create policy vehicles_select
  on public.vehicles for select
  to authenticated
  using (driver_id = public.current_driver_id() or public.is_admin());

drop policy if exists vehicles_admin_write on public.vehicles;
create policy vehicles_admin_write
  on public.vehicles for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- passengers
-- -----------------------------------------------------------------------------

drop policy if exists passengers_admin_all on public.passengers;
create policy passengers_admin_all
  on public.passengers for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- active_rides
-- -----------------------------------------------------------------------------
-- O motorista só vê as próprias corridas. Ofertas sem dono são expostas
-- exclusivamente por list_available_rides() (ADR-019).

drop policy if exists active_rides_select on public.active_rides;
create policy active_rides_select
  on public.active_rides for select
  to authenticated
  using (public.is_admin() or driver_id = public.current_driver_id());

drop policy if exists active_rides_admin_write on public.active_rides;
create policy active_rides_admin_write
  on public.active_rides for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- -----------------------------------------------------------------------------
-- ride_operations
-- -----------------------------------------------------------------------------

drop policy if exists ride_operations_admin_select on public.ride_operations;
create policy ride_operations_admin_select
  on public.ride_operations for select
  to authenticated
  using (public.is_admin());

-- -----------------------------------------------------------------------------
-- driver_live_locations
-- -----------------------------------------------------------------------------

drop policy if exists driver_locations_select on public.driver_live_locations;
create policy driver_locations_select
  on public.driver_live_locations for select
  to authenticated
  using (driver_id = public.current_driver_id() or public.is_admin());

-- -----------------------------------------------------------------------------
-- Garantia extra: nenhum cliente autenticado cria perfil
-- -----------------------------------------------------------------------------
-- Perfis são criados pela Edge Function admin-create-driver, que usa
-- service_role no servidor (ADR-005). Não existe policy de INSERT aqui.

comment on policy passengers_admin_all on public.passengers is
  'Passageiro não tem login nesta versão. Somente administração acessa.';
