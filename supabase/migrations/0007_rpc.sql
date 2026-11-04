-- =============================================================================
-- 0007 — Funções RPC de transição de corrida
-- =============================================================================
-- STATUS: escrito, NÃO aplicado, mas logicamente consistente.
--
-- Estas funções são o único caminho para modificar `active_rides`.
-- Nenhum `UPDATE` ou `INSERT` direto é permitido pelas policies (0006_rls.sql).
-- Todas as transições validam estado, versão e autorização.
--
-- Cada função retorna o `id` da corrida afetada, para o cliente poder
-- reconciliar o SQLite se necessário. Se a transição for inválida, a função
-- lança um erro e nenhuma linha é alterada.
--
-- Todas as funções usam `set search_path = public, pg_temp` para evitar
-- sequestro de schema. Operações críticas validam `version` para detectar
-- escrita concorrente.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- accept_ride
-- -----------------------------------------------------------------------------
-- Motorista aceita uma solicitação `requested`. Só pode ser chamado uma vez
-- por corrida. O `idempotency_key` serve para repetição segura.
--
-- Pré-condição: corrida `requested`, `driver_id IS NULL`, `vehicle_id IS NULL`.
-- Pós-condição: `driver_id` e `vehicle_id` preenchidos, `status = 'accepted'`.
--
-- Retorna: `id` da corrida afetada.
--
create or replace function public.accept_ride(
  p_ride_id uuid,
  p_idempotency_key uuid,
  p_driver_id uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_driver public.drivers%rowtype;
  v_vehicle public.vehicles%rowtype;
  v_actor_profile_id uuid;
  v_already_processed boolean;
  v_result uuid;
begin
  -- Valida identidade do chamador: só o próprio motorista pode aceitar em nome de si mesmo
  select public.current_driver_id() into v_driver.id;
  if v_driver.id is null or v_driver.id <> p_driver_id then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'O driver_id informado não corresponde ao motorista autenticado.';
  end if;

  -- Idempotência: se já processou esta aceitação com esta chave, retorna sem efeito
  select exists (
    select 1
    from public.ride_operations
    where ride_id = p_ride_id
      and operation = 'accept'
      and idempotency_key = p_idempotency_key
  ) into v_already_processed;

  if v_already_processed then
    return p_ride_id;
  end if;

  -- Busca a corrida travada
  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  -- Validações de estado (todas devem falhar se a corrida não estiver em
  -- `requested` ou se já tiver motorista/veículo).
  if v_ride.status <> 'requested' then
    raise exception 'CORRIDA_NAO_SOLICitada'
      using errcode = '42501',
            detail = 'A corrida já está em estado ' || v_ride.status || ', não em requested.';
  end if;

  if v_ride.driver_id is not null then
    raise exception 'CORRIDA_JÁ_TEM_MOTORISTA'
      using errcode = '42501',
            detail = 'Esta corrida já tem motorista atribuído.';
  end if;

  if v_ride.vehicle_id is not null then
    raise exception 'CORRIDA_JÁ_TEM_VEICULO'
      using errcode = '42501',
            detail = 'Esta corrida já tem veículo atribuído.';
  end if;

  -- Verifica se o motorista está ativo e online
  select * into v_driver
  from public.drivers
  where id = p_driver_id
    for update;

  if not (v_driver.is_active and v_driver.availability = 'online') then
    raise exception 'MOTORISTA_N_O_N_LINE'
      using errcode = '42501',
            detail = 'O motorista não está online ou está inativo.';
  end if;

  -- Busca o veículo ativo do motorista (um veículo ativo por motorista)
  select * into v_vehicle
  from public.vehicles
  where driver_id = p_driver_id
    and is_active = true
  limit 1;

  if not found then
    raise exception 'MOTORISTA_SEM_VEICULO'
      using errcode = '42501',
            detail = 'O motorista não possui um veículo ativo vinculado.';
  end if;

  -- Obtém o profile_id do motorista para o recibo de operação
  select p.id into v_actor_profile_id
  from public.profiles p
  join public.drivers d on d.profile_id = p.id
  where d.id = p_driver_id;

  -- Aplica a transição atômica
  update public.active_rides
  set driver_id = p_driver_id,
      vehicle_id = v_vehicle.id,
      status = 'accepted',
      accepted_at = now(),
      version = version + 1
  where id = p_ride_id
    and version = v_ride.version;  -- otimista: se outra transação atualizou, aborta

  if not found then
    raise exception 'CONCORRENCIA' using errcode = '40001';
  end if;

  get diagnostics v_result = rows_affected;
  if v_result = 0 then
    raise exception 'NAO_FOI_POSSÍVEL_ACEITAR' using errcode = '42501';
  end if;

  -- Grava recibo de idempotência da aceitação
  insert into public.ride_operations (
    ride_id,
    operation,
    actor_profile_id,
    idempotency_key
  )
  values (
    p_ride_id,
    'accept',
    v_actor_profile_id,
    p_idempotency_key
  );

  return p_ride_id;
end
$$;

-- -----------------------------------------------------------------------------
-- mark_driver_arriving
-- -----------------------------------------------------------------------------
-- Motorista sinaliza que está chegando ao embarque. Apenas o motorista da
-- corrida pode chamar.
--
create or replace function public.mark_driver_arriving(
  p_ride_id uuid,
  p_driver_id uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_actor_driver_id uuid;
begin
  -- Valida identidade do chamador
  select public.current_driver_id() into v_actor_driver_id;
  if v_actor_driver_id is null or v_actor_driver_id <> p_driver_id then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'O driver_id informado não corresponde ao motorista autenticado.';
  end if;

  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  if v_ride.driver_id <> p_driver_id then
    raise exception 'NAO_E_MOTORISTA_DA_CORRIDA'
      using errcode = '42501';
  end if;

  if v_ride.status <> 'accepted' then
    raise exception 'CORRIDA_NAO_Aceita'
      using errcode = '42501',
            detail = 'Somente corridas aceitas podem ser marcadas como chegando.';
  end if;

  update public.active_rides
  set status = 'driver_arriving',
      version = version + 1
  where id = p_ride_id
    and version = v_ride.version;

  if not found then
    raise exception 'CONCORRENCIA';
  end if;

  return p_ride_id;
end
$$;

-- -----------------------------------------------------------------------------
-- mark_arrived
-- -----------------------------------------------------------------------------
-- Motorista sinaliza que chegou ao embarque.
--
create or replace function public.mark_arrived(
  p_ride_id uuid,
  p_driver_id uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_actor_driver_id uuid;
begin
  -- Valida identidade do chamador
  select public.current_driver_id() into v_actor_driver_id;
  if v_actor_driver_id is null or v_actor_driver_id <> p_driver_id then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'O driver_id informado não corresponde ao motorista autenticado.';
  end if;

  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  if v_ride.driver_id <> p_driver_id then
    raise exception 'NAO_E_MOTORISTA_DA_CORRIDA';
  end if;

  if v_ride.status <> 'driver_arriving' then
    raise exception 'ESTADO_INCORRETO'
      using errcode = '42501',
            detail = 'A corrida deve estar em driver_arriving.';
  end if;

  update public.active_rides
  set status = 'arrived',
      arrived_at = now(),
      version = version + 1
  where id = p_ride_id
    and version = v_ride.version;

  if not found then
    raise exception 'CONCORRENCIA';
  end if;

  return p_ride_id;
end
$$;

-- -----------------------------------------------------------------------------
-- start_ride
-- -----------------------------------------------------------------------------
-- Motorista sinaliza que a corrida começou (o passageiro embarcou).
--
create or replace function public.start_ride(
  p_ride_id uuid,
  p_driver_id uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_actor_driver_id uuid;
begin
  -- Valida identidade do chamador
  select public.current_driver_id() into v_actor_driver_id;
  if v_actor_driver_id is null or v_actor_driver_id <> p_driver_id then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'O driver_id informado não corresponde ao motorista autenticado.';
  end if;

  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  if v_ride.driver_id <> p_driver_id then
    raise exception 'NAO_E_MOTORISTA_DA_CORRIDA';
  end if;

  if v_ride.status <> 'arrived' then
    raise exception 'ESTADO_INCORRETO'
      using errcode = '42501',
            detail = 'A corrida deve estar em arrived.';
  end if;

  update public.active_rides
  set status = 'in_progress',
      started_at = now(),
      version = version + 1
  where id = p_ride_id
    and version = v_ride.version;

  if not found then
    raise exception 'CONCORRENCIA';
  end if;

  return p_ride_id;
end
$$;

-- -----------------------------------------------------------------------------
-- complete_ride
-- -----------------------------------------------------------------------------
-- Motorista conclui a corrida. Este é o ponto onde o recibo de idempotência
-- entra em ação. Se o cliente perder a resposta do servidor, ele pode
-- repetir a chamada com a mesma `idempotency_key` e obter o mesmo resultado
-- sem efeito colateral.
--
create or replace function public.complete_ride(
  p_ride_id uuid,
  p_driver_id uuid,
  p_idempotency_key uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_already_processed boolean;
  v_actor_driver_id uuid;
  v_actor_profile_id uuid;
begin
  -- Valida identidade do chamador
  select public.current_driver_id() into v_actor_driver_id;
  if v_actor_driver_id is null or v_actor_driver_id <> p_driver_id then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'O driver_id informado não corresponde ao motorista autenticado.';
  end if;

  -- Obtém o profile_id do motorista para o recibo
  select p.id into v_actor_profile_id
  from public.profiles p
  join public.drivers d on d.profile_id = p.id
  where d.id = p_driver_id;

  -- Verifica idempotência antes de tocar na corrida.
  select exists (
    select 1
    from public.ride_operations
    where ride_id = p_ride_id
      and operation = 'complete'
      and actor_profile_id = v_actor_profile_id
      and idempotency_key = p_idempotency_key
  ) into v_already_processed;

  if v_already_processed then
    -- Já processou: retorna o id sem fazer nada novo. Isso é o "mesmo resultado".
    return p_ride_id;
  end if;

  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  if v_ride.driver_id <> p_driver_id then
    raise exception 'NAO_E_MOTORISTA_DA_CORRIDA';
  end if;

  if v_ride.status <> 'in_progress' then
    raise exception 'ESTADO_INCORRETO'
      using errcode = '42501',
            detail = 'A corrida deve estar em in_progress.';
  end if;

  -- Transição: remove a corrida ativa e grava recibo
  begin
    -- 1. Remove a corrida ativa
    delete from public.active_rides where id = p_ride_id;

    -- 2. Grava recibo de idempotência (sem coordenada, sem preço, sem nome)
    insert into public.ride_operations (
      ride_id,
      operation,
      actor_profile_id,
      idempotency_key
    )
    values (
      p_ride_id,
      'complete',
      v_actor_profile_id,
      p_idempotency_key
    );

    -- 3. Opcional: atualizar last_seen do motorista (não é obrigatório aqui,
    --    pode ser feito por heartbeat separado)
    update public.drivers
    set last_seen_at = now()
    where id = p_driver_id;
  exception
    when unique_violation then
      -- Chave duplicada de idempotência: outra thread/já processou. Ignora.
      -- A corrida já foi removida ou o recibo já existe. Retorna id.
      return p_ride_id;
  end;

  return p_ride_id;
end
$$;

-- -----------------------------------------------------------------------------
-- cancel_ride
-- -----------------------------------------------------------------------------
-- Cancela uma corrida. Quem pode cancelar depende do estado (matriz em
-- ADR-008). Esta função implementa a versão "admin cancela" + "motorista
-- cancela em states permitidos".
--
create or replace function public.cancel_ride(
  p_ride_id uuid,
  p_driver_id uuid,
  p_reason text,
  p_actor text  -- 'admin' ou 'driver'
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_actor_is_admin boolean;
  v_actor_profile_id uuid;
  v_cancel_actor public.cancel_actor;
begin
  -- Verifica se o ator é admin
  v_actor_is_admin := public.is_admin();

  -- Se não é admin, valida identidade do chamador
  if not v_actor_is_admin then
    declare
      v_actor_driver_id uuid;
    begin
      select public.current_driver_id() into v_actor_driver_id;
      if v_actor_driver_id is null or v_actor_driver_id <> p_driver_id then
        raise exception 'MOTORISTA_NAO_AUTENTICADO'
          using errcode = '42501',
                detail = 'O driver_id informado não corresponde ao motorista autenticado.';
      end if;

      -- Obtém o profile_id do motorista
      select p.id into v_actor_profile_id
      from public.profiles p
      join public.drivers d on d.profile_id = p.id
      where d.id = p_driver_id;
    end;
  else
    -- Admin: obtém o profile_id do admin autenticado
    select public.current_profile_id() into v_actor_profile_id;
  end if;

  -- Define o ator do cancelamento para o campo cancelled_by (enum cancel_actor)
  if v_actor_is_admin then
    v_cancel_actor := 'admin'::public.cancel_actor;
  else
    v_cancel_actor := 'driver'::public.cancel_actor;
  end if;

  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  -- Validação por estado e ator (ADR-008)
  if v_actor_is_admin then
    -- Admin pode cancelar qualquer corrida em estado não-terminal
    if v_ride.status in ('completed', 'cancelled') then
      raise exception 'CORRIDA_JÁ_TERMINADA'
        using errcode = '42501';
    end if;
  else
    -- Motorista só pode cancelar em estados iniciais
    if not (v_ride.status = 'requested') then
      raise exception 'CANCELAMENTO_EM_ESTADO_INCORRETO'
        using errcode = '42501',
              detail = 'Motoristas só podem cancelar solicitações (status requested).';
    end if;
  end if;

  -- Registra cancelamento antes de remover
  update public.active_rides
  set status = 'cancelled',
      cancelled_at = now(),
      cancelled_by = v_cancel_actor,
      cancel_reason = p_reason,
      version = version + 1
  where id = p_ride_id
    and version = v_ride.version;

  if not found then
    raise exception 'CONCORRENCIA';
  end if;

  -- Grava recibo técnico (com idempotency_key para repetição segura)
  insert into public.ride_operations (
    ride_id,
    operation,
    actor_profile_id,
    idempotency_key
  )
  values (
    p_ride_id,
    'cancel',
    v_actor_profile_id,
    gen_random_uuid()
  );

  return p_ride_id;
end
$$;

-- -----------------------------------------------------------------------------
-- list_available_rides
-- -----------------------------------------------------------------------------
-- Função que substitui a `view` da ADR-019. Retorna ofertas `requested`
-- sem motorista, para o motorista poder escolher.
-- Nunca expõe dados do passageiro.
--
create or replace function public.list_available_rides()
returns table (
  id uuid,
  pickup_label text,
  destination_label text,
  pickup_latitude numeric(9, 6),
  pickup_longitude numeric(9, 6),
  destination_latitude numeric(9, 6),
  destination_longitude numeric(9, 6),
  estimated_fare_cents integer,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  return query
  select
    a.id,
    a.pickup_label,
    a.destination_label,
    a.pickup_latitude,
    a.pickup_longitude,
    a.destination_latitude,
    a.destination_longitude,
    a.estimated_fare_cents,
    a.created_at
  from public.active_rides a
  where a.status = 'requested'
    and a.driver_id is null;
end
$$;

revoke all on function public.list_available_rides() from public;
grant execute on function public.list_available_rides() to authenticated;

-- -----------------------------------------------------------------------------
-- set_availability
-- -----------------------------------------------------------------------------
-- Motorista define sua própria disponibilidade. 'busy' só é atribuído pelo
-- backend na aceitação, nunca pelo cliente (MASTER_SPEC.md §8).
--
create or replace function public.set_availability(
  p_availability public.driver_availability
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
  v_actor_driver_id uuid;
begin
  -- Valida identidade do chamador
  select public.current_driver_id() into v_actor_driver_id;
  if v_actor_driver_id is null then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'Motorista não autenticado.';
  end if;

  -- 'busy' só é definido pelo backend na aceitação da corrida
  if p_availability = 'busy' then
    raise exception 'DISPONIBILIDADE_BUSY_PROIBIDA'
      using errcode = '42501',
            detail = 'O cliente não pode definir availability como busy.';
  end if;

  select id into v_driver_id
  from public.drivers
  where id = v_actor_driver_id
    for update;

  update public.drivers
  set availability = p_availability,
      last_seen_at = now(),
      version = version + 1
  where id = v_driver_id;
end
$$;

revoke all on function public.set_availability() from public;
grant execute on function public.set_availability() to authenticated;

-- -----------------------------------------------------------------------------
-- upsert_location
-- -----------------------------------------------------------------------------
-- Motorista atualiza sua própria localização ao vivo. Upsert: uma linha por
-- motorista. Não armazena histórico de trajetos (MASTER_SPEC.md §9, §11).
--
create or replace function public.upsert_location(
  p_latitude numeric(9, 6),
  p_longitude numeric(9, 6),
  p_accuracy numeric(8, 2),
  p_heading numeric(6, 2),
  p_speed numeric(8, 2),
  p_recorded_at timestamptz
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
begin
  -- Valida identidade do chamador
  select public.current_driver_id() into v_driver_id;
  if v_driver_id is null then
    raise exception 'MOTORISTA_NAO_AUTENTICADO'
      using errcode = '42501',
            detail = 'Motorista não autenticado.';
  end if;

  -- Valida coordenadas (defesa em profundidade, além do CHECK da tabela)
  if p_latitude < -90 or p_latitude > 90 then
    raise exception 'LATITUDE_INVALIDA' using errcode = '23514';
  end if;
  if p_longitude < -180 or p_longitude > 180 then
    raise exception 'LONGITUDE_INVALIDA' using errcode = '23514';
  end if;

  insert into public.driver_live_locations (
    driver_id, latitude, longitude, accuracy, heading, speed, recorded_at
  )
  values (
    v_driver_id, p_latitude, p_longitude, p_accuracy, p_heading, p_speed, p_recorded_at
  )
  on conflict (driver_id) do update
  set latitude = excluded.latitude,
      longitude = excluded.longitude,
      accuracy = excluded.accuracy,
      heading = excluded.heading,
      speed = excluded.speed,
      recorded_at = excluded.recorded_at,
      updated_at = now();
end
$$;

revoke all on function public.upsert_location() from public;
grant execute on function public.upsert_location() to authenticated;

-- -----------------------------------------------------------------------------
-- create_ride (admin)
-- -----------------------------------------------------------------------------
-- Administração cria uma solicitação de corrida. Exige passageiro ativo e
-- livre (sem corrida ativa). Respeita o limite de uma corrida ativa por
-- passageiro via índice único em active_rides(passenger_id).
--
create or replace function public.create_ride(
  p_passenger_id uuid,
  p_pickup_latitude numeric(9, 6),
  p_pickup_longitude numeric(9, 6),
  p_pickup_label text,
  p_destination_latitude numeric(9, 6),
  p_destination_longitude numeric(9, 6),
  p_destination_label text,
  p_estimated_fare_cents integer
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_actor_profile_id uuid;
  v_ride_id uuid;
begin
  -- Apenas admin
  if not public.is_admin() then
    raise exception 'APENAS_ADMIN' using errcode = '42501';
  end if;

  select public.current_profile_id() into v_actor_profile_id;

  -- Verifica passageiro ativo
  if not exists (
    select 1 from public.passengers
    where id = p_passenger_id and is_active = true
  ) then
    raise exception 'PASSAGEIRO_INATIVO_OU_INEXISTENTE' using errcode = '23514';
  end if;

  -- Insere a corrida (o índice único em passenger_id impede duplicidade)
  insert into public.active_rides (
    passenger_id, pickup_latitude, pickup_longitude, pickup_label,
    destination_latitude, destination_longitude, destination_label,
    estimated_fare_cents, status
  )
  values (
    p_passenger_id, p_pickup_latitude, p_pickup_longitude, p_pickup_label,
    p_destination_latitude, p_destination_longitude, p_destination_label,
    p_estimated_fare_cents, 'requested'
  )
  returning id into v_ride_id;

  return v_ride_id;
end
$$;

revoke all on function public.create_ride() from public;
grant execute on function public.create_ride() to authenticated;

-- -----------------------------------------------------------------------------
-- create_driver (admin)
-- -----------------------------------------------------------------------------
-- Administração cria o cadastro operacional de um motorista vinculado a um
-- profile existente. Respeita o limite de 5 via trigger trg_drivers_limit.
--
create or replace function public.create_driver(
  p_profile_id uuid
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_driver_id uuid;
begin
  -- Apenas admin
  if not public.is_admin() then
    raise exception 'APENAS_ADMIN' using errcode = '42501';
  end if;

  -- Verifica se o profile existe e é ativo
  if not exists (
    select 1 from public.profiles
    where id = p_profile_id and is_active = true and role = 'driver'
  ) then
    raise exception 'PROFILE_INVALIDO' using errcode = '23514';
  end if;

  -- Não permite driver duplicado para o mesmo profile
  if exists (
    select 1 from public.drivers where profile_id = p_profile_id
  ) then
    raise exception 'DRIVER_JA_EXISTENTE' using errcode = '23514';
  end if;

  insert into public.drivers (profile_id, is_active, availability)
  values (p_profile_id, true, 'offline')
  returning id into v_driver_id;

  return v_driver_id;
end
$$;

revoke all on function public.create_driver() from public;
grant execute on function public.create_driver() to authenticated;

-- -----------------------------------------------------------------------------
-- create_passenger (admin)
-- -----------------------------------------------------------------------------
-- Administração cria um passageiro fictício. Respeita o limite de 5 via
-- trigger trg_passengers_limit.
--
create or replace function public.create_passenger(
  p_name text,
  p_phone text
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_passenger_id uuid;
begin
  -- Apenas admin
  if not public.is_admin() then
    raise exception 'APENAS_ADMIN' using errcode = '42501';
  end if;

  insert into public.passengers (name, phone, is_active)
  values (p_name, p_phone, true)
  returning id into v_passenger_id;

  return v_passenger_id;
end
$$;

revoke all on function public.create_passenger() from public;
grant execute on function public.create_passenger() to authenticated;

-- -----------------------------------------------------------------------------
-- set_role (admin)
-- -----------------------------------------------------------------------------
-- Administração altera o papel de um perfil. Nunca permite que o próprio
-- usuário eleve seu papel (protegido também pelo trigger protect_profile_fields).
--
create or replace function public.set_role(
  p_profile_id uuid,
  p_role public.profile_role
)
returns void
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
begin
  -- Apenas admin
  if not public.is_admin() then
    raise exception 'APENAS_ADMIN' using errcode = '42501';
  end if;

  -- Não permite autoelevação/alteração do próprio papel
  if p_profile_id = public.current_profile_id() then
    raise exception 'AUTO_ELEVACAO_PROIBIDA' using errcode = '42501';
  end if;

  update public.profiles
  set role = p_role,
      version = version + 1
  where id = p_profile_id;
end
$$;

revoke all on function public.set_role() from public;
grant execute on function public.set_role() to authenticated;

-- -----------------------------------------------------------------------------
-- create_driver_account (transacional, usada pela Edge Function admin-create-driver)
-- -----------------------------------------------------------------------------
-- Cria profile + driver em uma única transação. Chamada com security definer
-- para superar RLS (não há policy de INSERT em profiles para authenticated).
-- Se qualquer passo falhar, o PostgreSQL faz rollback automático e a Edge
-- Function remove o usuário do Auth para não deixar conta órfã (ADR-005).
--
create or replace function public.create_driver_account(
  p_auth_user_id uuid,
  p_full_name text,
  p_phone text
)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_profile_id uuid;
  v_driver_id uuid;
begin
  -- Insere o profile vinculado ao auth_user_id
  insert into public.profiles (
    auth_user_id, full_name, phone, role, is_active
  )
  values (
    p_auth_user_id, p_full_name, p_phone, 'driver', true
  )
  returning id into v_profile_id;

  -- Insere o cadastro operacional do motorista (offline por padrão)
  -- O trigger trg_drivers_limit impõe o limite de 5
  insert into public.drivers (
    profile_id, is_active, availability
  )
  values (
    v_profile_id, true, 'offline'
  )
  returning id into v_driver_id;

  return v_driver_id;
end
$$;

revoke all on function public.create_driver_account() from public;
grant execute on function public.create_driver_account() to authenticated;

-- -----------------------------------------------------------------------------
-- Funções auxiliares (opcional, para uso interno)
-- -----------------------------------------------------------------------------

-- Retorna o perfil do motorista que está na corrida ativa, se houver.
create or replace function public.ride_driver_profile(p_ride_id uuid)
returns uuid
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select profile_id
  from public.drivers
  where id = (select driver_id from public.active_rides where id = p_ride_id)
$$;

-- Retorna valor total gasto em corridas completadas por um motorista (para
-- fins de painel admin). Só existe após a primeira conclusão.
create or replace function public.total_fare_by_driver(p_driver_id uuid)
returns integer
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(sum(estimated_fare_cents), 0)
  from public.active_rides a
  where a.driver_id = p_driver_id
    and a.status = 'completed';  -- note: active_rides não terá completed; use ride_operations ou view separada
$$;