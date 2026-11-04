/**
 * Serviço de notificações persistentes.
 *
 * Exibe notificação durante o serviço de localização, conforme exigido
 * pelo Android para serviços em primeiro plano.
 *
 * Regras (MASTER_SPEC.md §11):
 * - Notificação persistente durante o serviço de localização.
 * - Respeitar permissões de notificação do Android.
 */

import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

let notificationChannelCreated = false;

/**
 * Configura as notificações e cria o canal para o serviço de localização.
 * Deve ser chamado uma vez na inicialização do app.
 */
export async function setupNotifications(): Promise<void> {
  if (Platform.OS !== 'android') {
    return;
  }

  if (notificationChannelCreated) {
    return;
  }

  // Solicita permissão de notificação
  const { status: existingStatus } =
    await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (finalStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') {
    // Sem permissão, não bloqueia o app; apenas não mostra notificação
    return;
  }

  // Cria o canal de notificação para serviço em primeiro plano
  await (Notifications as any).setNotificationChannelAsync('driver-location', {
    name: 'Localização do motorista',
    importance: Notifications.AndroidImportance.DEFAULT,
    vibrationPattern: [0, 0],
    lightColor: '#3B82F6',
    sound: false,
    bypassDnd: false,
  });

  notificationChannelCreated = true;
}

/**
 * Exibe a notificação persistente durante o serviço de localização.
 */
export async function showLocationServiceNotification(): Promise<void> {
  if (!notificationChannelCreated) {
    await setupNotifications();
  }

  await (Notifications as any).presentNotificationAsync({
    title: 'DRIVER APP',
    body: 'Rastreamento de localização ativo',
    android: {
      channelId: 'driver-location',
      ongoing: true, // notificação persistente
      priority: Notifications.AndroidNotificationPriority.DEFAULT,
      sticky: false,
      autoCancel: false,
    },
  });
}

/**
 * Oculta a notificação do serviço de localização.
 * Deve ser chamada quando o motorista fica offline ou encerra o serviço.
 */
export async function hideLocationServiceNotification(): Promise<void> {
  await (Notifications as any).dismissAllNotificationsAsync();
}

/**
 * Verifica se as notificações estão habilitadas.
 */
export async function areNotificationsEnabled(): Promise<boolean> {
  const { status } = await Notifications.getPermissionsAsync();
  return status === 'granted';
}
