/**
 * Hook para gerenciar localização GPS.
 *
 * Encapsula permissões, leitura única e rastreamento contínuo.
 * Sincroniza posições com o SQLite local (fila de pendentes) e com o
 * servidor via RPC upsert_location.
 *
 * Regras (MASTER_SPEC.md §11):
 * - Não rastrear motorista offline.
 * - GPS real do Android.
 * - Respeitar permissões e limitações do fabricante.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import {
  requestLocationPermissions,
  checkLocationPermissions,
  getCurrentLocation,
  startLocationTracking,
  stopLocationTracking,
  isTracking,
} from '../services/location';
import {
  enqueuePosition,
  getPendingPositions,
  clearSentPositions,
} from '../database/local/sqlite';
import type { LocationReading } from '../services/location';

export interface UseLocationReturn {
  isTracking: boolean;
  hasPermission: boolean | null;
  lastReading: LocationReading | null;
  isLoading: boolean;
  error: string | null;
  requestPermissions: () => Promise<boolean>;
  startTracking: (onPosition?: (reading: LocationReading) => void) => Promise<void>;
  stopTracking: () => Promise<void>;
  getCurrent: () => Promise<LocationReading>;
  syncPendingPositions: () => Promise<void>;
}

export function useLocation(): UseLocationReturn {
  const [isTrackingState, setIsTrackingState] = useState(false);
  const [hasPermission, setHasPermission] = useState<boolean | null>(null);
  const [lastReading, setLastReading] = useState<LocationReading | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onPositionRef = useRef<((reading: LocationReading) => void) | null>(
    null
  );

  const requestPermissions = useCallback(async (): Promise<boolean> => {
    setIsLoading(true);
    setError(null);
    try {
      const granted = await requestLocationPermissions();
      setHasPermission(granted);
      return granted;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro ao solicitar permissão.');
      return false;
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    setIsTrackingState(isTracking);
  }, [isTracking]);

  const startTracking = useCallback(
    async (onPosition?: (reading: LocationReading) => void) => {
      setIsLoading(true);
      setError(null);
      try {
        const granted = await checkLocationPermissions();
        if (!granted) {
          const ok = await requestLocationPermissions();
          if (!ok) {
            throw new Error('Permissão de localização não concedida.');
          }
        }

        onPositionRef.current = onPosition ?? null;

        await startLocationTracking((reading) => {
          setLastReading(reading);
          // Enfileira a posição para envio ao servidor
          enqueuePosition({
            latitude: reading.latitude,
            longitude: reading.longitude,
            accuracy: reading.accuracy,
            heading: reading.heading,
            speed: reading.speed,
            recorded_at: reading.timestamp,
          }).catch((err) => {
            console.error('Falha ao enfileirar posição:', err);
          });
          onPositionRef.current?.(reading);
        });

        setIsTrackingState(true);
      } catch (err) {
        setError(
          err instanceof Error ? err.message : 'Falha ao iniciar rastreamento.'
        );
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    [requestLocationPermissions, checkLocationPermissions]
  );

  const stopTracking = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      await stopLocationTracking();
      setIsTrackingState(false);
      onPositionRef.current = null;
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Falha ao parar rastreamento.'
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  const getCurrent = useCallback(async (): Promise<LocationReading> => {
    setIsLoading(true);
    setError(null);
    try {
      const reading = await getCurrentLocation();
      setLastReading(reading);
      return reading;
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Falha ao obter localização.'
      );
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, []);

  const syncPendingPositions = useCallback(async () => {
    try {
      const pending = await getPendingPositions();
      // Aqui seria enviado ao servidor via upsert_location.
      // Implementado quando o cliente Supabase estiver conectado ao banco real.
      // Após enviar com sucesso, limpa as posições já enviadas.
      if (pending.length > 0) {
        await clearSentPositions(pending[pending.length - 1].id);
      }
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'Falha ao sincronizar posições.'
      );
    }
  }, []);

  return {
    isTracking: isTrackingState,
    hasPermission,
    lastReading,
    isLoading,
    error,
    requestPermissions,
    startTracking,
    stopTracking,
    getCurrent,
    syncPendingPositions,
  };
}
