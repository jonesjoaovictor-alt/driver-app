/**
 * Hook para gerenciar corridas.
 *
 * Encapsula as chamadas às RPCs de corrida e gerencia o estado local
 * da corrida ativa, sincronizando com o SQLite cache.
 *
 * Regras (MASTER_SPEC.md §7, §13):
 * - Toda transição passa por RPC (servidor confirma antes de atualizar UI).
 * - Cópia local só é atualizada após confirmação do servidor.
 * - Se o servidor não tiver corrida ativa, a cópia local é apagada.
 */

import { useCallback, useState } from 'react';
import {
  acceptRide,
  markDriverArriving,
  markArrived,
  startRide,
  completeRide,
  cancelRide,
  setAvailability,
  getMyActiveRide,
  generateIdempotencyKey,
} from '../services/rides';
import {
  saveActiveRide,
  getActiveRideFromCache,
  clearActiveRideFromCache,
} from '../database/local/sqlite';
import { useAuth } from '../app/providers/AuthProvider';

export interface UseRidesReturn {
  activeRide: any | null;
  isLoading: boolean;
  error: string | null;
  loadActiveRide: () => Promise<void>;
  accept: (rideId: string) => Promise<void>;
  markArriving: (rideId: string) => Promise<void>;
  markArrivedAt: (rideId: string) => Promise<void>;
  start: (rideId: string) => Promise<void>;
  complete: (rideId: string) => Promise<void>;
  cancel: (rideId: string, reason: string, actor?: 'admin' | 'driver') => Promise<void>;
  goOnline: () => Promise<void>;
  goOffline: () => Promise<void>;
}

export function useRides(): UseRidesReturn {
  const { driver, refreshDriver } = useAuth();
  const [activeRide, setActiveRide] = useState<any | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loadActiveRide = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      // Tenta o servidor primeiro (fonte oficial)
      const ride = await getMyActiveRide();

      if (ride) {
        await saveActiveRide(ride);
        setActiveRide(ride);
      } else {
        // Servidor não tem corrida ativa; verifica cache local
        const cached = await getActiveRideFromCache();
        if (cached) {
          // Servidor não tem corrida, mas cache local tem.
          // Conforme spec: se servidor não tem, limpa o cache local.
          await clearActiveRideFromCache();
          setActiveRide(null);
        } else {
          setActiveRide(null);
        }
      }
    } catch (err) {
      // Em caso de falha de rede, tenta o cache local
      const cached = await getActiveRideFromCache();
      setActiveRide(cached ?? null);
      setError(
        err instanceof Error ? err.message : 'Falha ao carregar corrida.'
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  const wrapRpc = useCallback(
    async (fn: () => Promise<string>, rideId?: string) => {
      setIsLoading(true);
      setError(null);
      try {
        await fn();
        await refreshDriver();
        await loadActiveRide();
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Erro na operação.');
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    [refreshDriver, loadActiveRide]
  );

  const accept = useCallback(
    async (rideId: string) => {
      if (!driver) throw new Error('Motorista não autenticado.');
      await wrapRpc(
        () =>
          acceptRide(rideId, generateIdempotencyKey(), driver.id),
        rideId
      );
    },
    [driver, wrapRpc]
  );

  const markArriving = useCallback(
    async (rideId: string) => {
      if (!driver) throw new Error('Motorista não autenticado.');
      await wrapRpc(
        () => markDriverArriving(rideId, driver.id),
        rideId
      );
    },
    [driver, wrapRpc]
  );

  const markArrivedAt = useCallback(
    async (rideId: string) => {
      if (!driver) throw new Error('Motorista não autenticado.');
      await wrapRpc(
        () => markArrived(rideId, driver.id),
        rideId
      );
    },
    [driver, wrapRpc]
  );

  const start = useCallback(
    async (rideId: string) => {
      if (!driver) throw new Error('Motorista não autenticado.');
      await wrapRpc(() => startRide(rideId, driver.id), rideId);
    },
    [driver, wrapRpc]
  );

  const complete = useCallback(
    async (rideId: string) => {
      if (!driver) throw new Error('Motorista não autenticado.');
      await wrapRpc(
        () => completeRide(rideId, driver.id, generateIdempotencyKey()),
        rideId
      );
    },
    [driver, wrapRpc]
  );

  const cancel = useCallback(
    async (
      rideId: string,
      reason: string,
      actor: 'admin' | 'driver' = 'driver'
    ) => {
      if (!driver && actor === 'driver') {
        throw new Error('Motorista não autenticado.');
      }
      await wrapRpc(
        () => cancelRide(rideId, driver?.id ?? '', reason, actor),
        rideId
      );
      if (actor === 'driver') {
        await clearActiveRideFromCache();
        setActiveRide(null);
      }
    },
    [driver, wrapRpc]
  );

  const goOnline = useCallback(async () => {
    await setAvailability('online');
    await refreshDriver();
  }, [refreshDriver]);

  const goOffline = useCallback(async () => {
    await setAvailability('offline');
    await refreshDriver();
  }, [refreshDriver]);

  return {
    activeRide,
    isLoading,
    error,
    loadActiveRide,
    accept,
    markArriving,
    markArrivedAt,
    start,
    complete,
    cancel,
    goOnline,
    goOffline,
  };
}
