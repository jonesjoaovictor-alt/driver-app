/**
 * Serviço de localização GPS.
 *
 * Usa Expo Location para obter a posição real do celular.
 * Gerencia permissões e atualizações contínuas durante a operação.
 *
 * Regras (MASTER_SPEC.md §11):
 * - GPS real do Android.
 * - Não rastrear motorista offline.
 * - Respeitar permissões e limitações do Android.
 */

import * as Location from 'expo-location';

export interface LocationReading {
  latitude: number;
  longitude: number;
  accuracy: number | null;
  heading: number | null;
  speed: number | null;
  timestamp: string;
}

let locationSubscription: Location.LocationSubscription | null = null;
let isTracking = false;

/**
 * Solicita permissões de localização.
 */
export async function requestLocationPermissions(): Promise<boolean> {
  const { status } = await Location.requestForegroundPermissionsAsync();
  if (status !== 'granted') {
    return false;
  }

  // Para rastreamento em segundo plano, precisamos também da permissão de background
  const { status: backgroundStatus } =
    await Location.requestBackgroundPermissionsAsync();
  return backgroundStatus === 'granted';
}

/**
 * Verifica se as permissões de localização estão concedidas.
 */
export async function checkLocationPermissions(): Promise<boolean> {
  const { status } = await Location.getForegroundPermissionsAsync();
  return status === 'granted';
}

/**
 * Obtém uma leitura única de localização.
 */
export async function getCurrentLocation(): Promise<LocationReading> {
  let location;
  try {
    location = await Location.getCurrentPositionAsync({
      accuracy: Location.Accuracy.BestForNavigation,
    });
  } catch (err) {
    throw new Error(
      `Falha ao obter localização: ${
        err instanceof Error ? err.message : String(err)
      }`
    );
  }

  return {
    latitude: location.coords.latitude,
    longitude: location.coords.longitude,
    accuracy: location.coords.accuracy ?? null,
    heading: location.coords.heading ?? null,
    speed: location.coords.speed ?? null,
    timestamp: location.timestamp
      ? new Date(location.timestamp).toISOString()
      : new Date().toISOString(),
  };
}

/**
 * Inicia o rastreamento contínuo de localização.
 *
 * @param callback - função chamada a cada nova leitura
 * @param intervalMs - intervalo mínimo entre leituras (ms)
 */
export async function startLocationTracking(
  callback: (reading: LocationReading) => void,
  intervalMs: number = 5000
): Promise<void> {
  if (isTracking) {
    return;
  }

  const hasPermission = await checkLocationPermissions();
  if (!hasPermission) {
    const granted = await requestLocationPermissions();
    if (!granted) {
      throw new Error('Permissão de localização não concedida.');
    }
  }

  try {
    locationSubscription = await Location.watchPositionAsync(
      {
        accuracy: Location.Accuracy.BestForNavigation,
        distanceInterval: 0,
        timeInterval: intervalMs,
      },
      (locationEvent) => {
        const { coords, timestamp } = locationEvent;
        callback({
          latitude: coords.latitude,
          longitude: coords.longitude,
          accuracy: coords.accuracy ?? null,
          heading: coords.heading ?? null,
          speed: coords.speed ?? null,
          timestamp: new Date(timestamp).toISOString(),
        });
      }
    );

    isTracking = true;
  } catch (err) {
    throw new Error(
      `Falha ao iniciar rastreamento: ${
        err instanceof Error ? err.message : String(err)
      }`
    );
  }
}

/**
 * Para o rastreamento contínuo de localização.
 */
export async function stopLocationTracking(): Promise<void> {
  if (locationSubscription) {
    await locationSubscription.remove();
    locationSubscription = null;
  }
  isTracking = false;
}

export { isTracking };
