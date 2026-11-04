/**
 * Serviço de corridas.
 *
 * Chama as RPCs do Supabase para transições de corrida. Todas as operações
 * críticas passam pelo servidor; o cliente nunca escreve diretamente em
 * active_rides.
 *
 * Regras (MASTER_SPEC.md §7, §10):
 * - Toda transição de corrida passa por RPC, nunca UPDATE direto.
 * - Validação de identidade é feita no servidor via current_driver_id().
 * - Idempotência via idempotency_key para operações repetidas.
 */

import { supabase } from './supabase/client';
import type { ActiveRide } from '../types/database';

/**
 * Lista ofertas disponíveis (corridas requested sem motorista).
 * Nunca expõe dados do passageiro.
 */
export async function listAvailableRides(): Promise<ActiveRide[]> {
  const { data, error } = await (supabase as any).rpc('list_available_rides');

  if (error) {
    throw new Error(`Falha ao listar ofertas: ${error.message}`);
  }

  return (data ?? []) as ActiveRide[];
}

/**
 * Aceita uma solicitação de corrida.
 *
 * @param rideId - ID da corrida
 * @param idempotencyKey - chave de idempotência para repetição segura
 * @param driverId - ID do motorista autenticado
 */
export async function acceptRide(
  rideId: string,
  idempotencyKey: string,
  driverId: string
): Promise<string> {
  const { data, error } = await (supabase as any).rpc('accept_ride', {
    p_ride_id: rideId,
    p_idempotency_key: idempotencyKey,
    p_driver_id: driverId,
  });

  if (error) {
    throw new Error(`Falha ao aceitar corrida: ${error.message}`);
  }

  return data as string;
}

/**
 * Marca o motorista como chegando ao embarque.
 */
export async function markDriverArriving(
  rideId: string,
  driverId: string
): Promise<string> {
  const { data, error } = await (supabase as any).rpc('mark_driver_arriving', {
    p_ride_id: rideId,
    p_driver_id: driverId,
  });

  if (error) {
    throw new Error(`Falha ao marcar chegada: ${error.message}`);
  }

  return data as string;
}

/**
 * Marca que o motorista chegou ao ponto de embarque.
 */
export async function markArrived(
  rideId: string,
  driverId: string
): Promise<string> {
  const { data, error } = await (supabase as any).rpc('mark_arrived', {
    p_ride_id: rideId,
    p_driver_id: driverId,
  });

  if (error) {
    throw new Error(`Falha ao marcar chegada ao embarque: ${error.message}`);
  }

  return data as string;
}

/**
 * Inicia a corrida (passageiro embarcou).
 */
export async function startRide(
  rideId: string,
  driverId: string
): Promise<string> {
  const { data, error } = await (supabase as any).rpc('start_ride', {
    p_ride_id: rideId,
    p_driver_id: driverId,
  });

  if (error) {
    throw new Error(`Falha ao iniciar corrida: ${error.message}`);
  }

  return data as string;
}

/**
 * Conclui a corrida com idempotência.
 *
 * Se a resposta se perder, o cliente pode repetir com a mesma
 * idempotency_key e obter o mesmo resultado sem efeito colateral.
 */
export async function completeRide(
  rideId: string,
  driverId: string,
  idempotencyKey: string
): Promise<string> {
  const { data, error } = await (supabase as any).rpc('complete_ride', {
    p_ride_id: rideId,
    p_driver_id: driverId,
    p_idempotency_key: idempotencyKey,
  });

  if (error) {
    throw new Error(`Falha ao concluir corrida: ${error.message}`);
  }

  return data as string;
}

/**
 * Cancela uma corrida.
 *
 * @param actor - 'admin' ou 'driver'
 */
export async function cancelRide(
  rideId: string,
  driverId: string,
  reason: string,
  actor: 'admin' | 'driver'
): Promise<string> {
  const { data, error } = await (supabase as any).rpc('cancel_ride', {
    p_ride_id: rideId,
    p_driver_id: driverId,
    p_reason: reason,
    p_actor: actor,
  });

  if (error) {
    throw new Error(`Falha ao cancelar corrida: ${error.message}`);
  }

  return data as string;
}

/**
 * Define a disponibilidade do motorista (online/offline).
 * 'busy' é proibido pelo servidor (só é definido na aceitação).
 */
export async function setAvailability(
  availability: 'offline' | 'online'
): Promise<void> {
  const { error } = await (supabase as any).rpc('set_availability', {
    p_availability: availability,
  });

  if (error) {
    throw new Error(`Falha ao definir disponibilidade: ${error.message}`);
  }
}

/**
 * Consulta a corrida ativa do motorista autenticado.
 */
export async function getMyActiveRide(): Promise<ActiveRide | null> {
  const { data, error } = await supabase
    .from('active_rides')
    .select('*')
    .maybeSingle();

  if (error) {
    throw new Error(`Falha ao consultar corrida ativa: ${error.message}`);
  }

  return (data as ActiveRide | null) ?? null;
}

/**
 * Gera uma chave de idempotência (UUID v4).
 */
export function generateIdempotencyKey(): string {
  return crypto.randomUUID?.() ?? generateFallbackUuid();
}

function generateFallbackUuid(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}
