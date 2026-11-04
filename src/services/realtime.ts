/**
 * Serviço de Realtime do Supabase.
 *
 * Gerencia inscrições em canais para receber atualizações de corridas
 * em tempo real (novas solicitações, mudanças de estado).
 *
 * Regras (MASTER_SPEC.md §14):
 * - Realtime é mecanismo de notificação, não fonte única da verdade.
 * - Implementar reconexão, recuperação por consulta, prevenção de
 *   inscrições duplicadas, encerramento de canais antigos.
 * - Reconciliar após reconexão consultando o servidor.
 */

import { supabase } from './supabase/client';
import type { ActiveRide } from '../types/database';

type RideStatusChangeHandler = (ride: ActiveRide) => void;
type NewRideHandler = (ride: ActiveRide) => void;

let ridesChannel: ReturnType<typeof supabase.channel> | null = null;
let locationsChannel: ReturnType<typeof supabase.channel> | null = null;

/**
 * Inscreve no canal de corridas ativas do motorista.
 *
 * @param driverId - ID do motorista
 * @param onStatusChange - callback quando uma corrida muda de estado
 * @param onNewRide - callback quando surge uma nova oferta disponível
 */
export async function subscribeToRides(
  driverId: string,
  onStatusChange?: RideStatusChangeHandler,
  onNewRide?: NewRideHandler
): Promise<void> {
  // Evita inscrições duplicadas
  if (ridesChannel) {
    await unsubscribeFromRides();
  }

  ridesChannel = supabase.channel(`rides:${driverId}`);

  // Inscreve nas mudanças de estado das corridas do motorista
  ridesChannel
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'active_rides',
        filter: `driver_id=eq.${driverId}`,
      },
      (payload) => {
        const ride = payload.new as ActiveRide;
        onStatusChange?.(ride);
      }
    )
    .subscribe((status) => {
      if (status === 'SUBSCRIBED') {
        console.log(`[Realtime] Inscrito em rides:${driverId}`);
      } else if (status === 'CHANNEL_ERROR') {
        console.error(`[Realtime] Erro no canal rides:${driverId}`);
      }
    });

  // Inscreve em novas ofertas (corridas requested sem motorista)
  if (onNewRide) {
    const offersChannel = supabase.channel('available_rides');

    offersChannel
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'active_rides',
          filter: "status=eq.requested",
        },
        (payload) => {
          const ride = payload.new as ActiveRide;
          // Só notifica se a corrida não tem motorista (oferta disponível)
          if (!ride.driver_id) {
            onNewRide(ride);
          }
        }
      )
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') {
          console.log('[Realtime] Inscrito em available_rides');
        }
      });

    // Guarda referência para cleanup
    (ridesChannel as any)._offersChannel = offersChannel;
  }
}

/**
 * Inscreve no canal de localizações ao vivo dos motoristas.
 *
 * @param driverId - ID do motorista (para a própria localização)
 * @param onLocationUpdate - callback quando a localização muda
 */
export async function subscribeToLocations(
  driverId: string,
  onLocationUpdate: (latitude: number, longitude: number) => void
): Promise<void> {
  if (locationsChannel) {
    await unsubscribeFromLocations();
  }

  locationsChannel = supabase.channel(`locations:${driverId}`);

  locationsChannel
    .on(
      'postgres_changes',
      {
        event: 'UPDATE',
        schema: 'public',
        table: 'driver_live_locations',
        filter: `driver_id=eq.${driverId}`,
      },
      (payload) => {
        const row = payload.new as {
          latitude: number;
          longitude: number;
        };
        onLocationUpdate(row.latitude, row.longitude);
      }
    )
    .subscribe((status) => {
      if (status === 'SUBSCRIBED') {
        console.log(`[Realtime] Inscrito em locations:${driverId}`);
      }
    });
}

/**
 * Encerra a inscrição no canal de corridas.
 */
export async function unsubscribeFromRides(): Promise<void> {
  if (ridesChannel) {
    const offersChannel = (ridesChannel as any)._offersChannel;
    if (offersChannel) {
      await supabase.removeChannel(offersChannel);
    }
    await supabase.removeChannel(ridesChannel);
    ridesChannel = null;
  }
}

/**
 * Encerra a inscrição no canal de localizações.
 */
export async function unsubscribeFromLocations(): Promise<void> {
  if (locationsChannel) {
    await supabase.removeChannel(locationsChannel);
    locationsChannel = null;
  }
}

/**
 * Encerra todas as inscrições Realtime.
 */
export async function unsubscribeAll(): Promise<void> {
  await unsubscribeFromRides();
  await unsubscribeFromLocations();
}

/**
 * Reconcilia o estado após reconexão.
 * Consulta o servidor e adota o estado oficial.
 */
export async function reconcileAfterReconnect(): Promise<ActiveRide | null> {
  const { data, error } = await supabase
    .from('active_rides')
    .select('*')
    .maybeSingle();

  if (error) {
    throw new Error(`Falha na reconciliação: ${error.message}`);
  }

  return (data as ActiveRide | null) ?? null;
}
