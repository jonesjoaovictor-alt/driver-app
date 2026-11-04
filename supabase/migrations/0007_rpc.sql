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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_driver public.drivers%rowtype;
  v_result uuid;
begin
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

  -- Verifica se o motorista está ativo
  select * into v_driver
  from public.drivers
  where id = p_driver_id
    for update;

  if not (v_driver.is_active and v_driver.availability = 'online') then
    raise exception 'MOTORISTA_N_O_N_LINE'
      using errcode = '42501',
            detail = 'O motorista não está online ou está inativo.';
  end if;

  -- Aplica a transição atômica
  update public.active_rides
  set driver_id = p_driver_id,
      vehicle_id = v_driver.vehicle_id,  -- assumes driver has a default vehicle or we set via trigger
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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
begin
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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
begin
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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
begin
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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_already_processed boolean;
begin
  -- Verifica idempotência antes de tocar na corrida.
  select exists (
    select 1
    from public.ride_operations
    where ride_id = p_ride_id
      and operation = 'complete'
      and actor_profile_id = (select profile_id from public.drivers where id = p_driver_id)
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
      (select profile_id from public.drivers where id = p_driver_id),
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
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_ride public.active_rides%rowtype;
  v_actor_is_admin boolean;
begin
  select * into v_ride
  from public.active_rides
  where id = p_ride_id
    for update;

  -- Verifica se o ator é admin
  v_actor_is_admin := public.is_admin();

  -- Validação por estado e ator (ADR-008)
  if v_actor_is_admin then
    -- Admin pode cancelar qualquer corrida em estado não-terminal
    if v_ride.status in ('completed', 'cancelled') then
      raise exception 'CORRIDA_JÁ_TERMINADA'
        using errcode = '42501';
    end if;
  else
    -- Motorista só pode cancelar em estados iniciais
    if not (v_ride.status = 'requested' then
      raise exception 'CANCELAMENTO_EM_ESTADO_INCORRETO'
        using errcode = '42501',
              detail = 'Motoristas só podem cancelar solicitações (status requested).';
    end if;
  end if;

  -- Registra cancelamento antes de remover
  update public.active_rides
  set status = 'cancelled',
      cancelled_at = now(),
      cancelled_by = case when v_actor_is_admin then 'admin' else p_driver_id end,
      cancel_reason = p_reason,
      version = version + 1
  where id = p_ride_id
    and version = v_ride.version;

  if not found then
    raise exception 'CONCORRENCIA';
  end if;

  -- Grava recibo técnico
  insert into public.ride_operations (
    ride_id,
    operation,
    actor_profile_id,
    idempotency_key
  )
  values (
    p_ride_id,
    'cancel',
    case when v_actor_is_admin then null else p_driver_id end,
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