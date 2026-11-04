import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Dimensions,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
  StatusBar,
} from 'react-native';
import { useAuth } from '../../app/providers/AuthProvider';

const { width } = Dimensions.get('window');

export function DriverScreen() {
  const { profile, driver, signOut, refreshDriver } = useAuth();
  const [isOnline, setIsOnline] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    setIsOnline(driver?.availability === 'online');
  }, [driver]);

  const handleToggleAvailability = async () => {
    if (!driver) return;
    // A RPC set_availability será implementada no backend; aqui apenas
    // atualizamos o estado local e solicitamos refresh.
    setRefreshing(true);
    await refreshDriver();
    setRefreshing(false);
  };

  const handleLogout = async () => {
    await signOut();
  };

  if (!profile || !driver) {
    return null; // O AuthProvider mostra loading enquanto carrega
  }

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />

      {/* Header: identificação do motorista e veículo */}
      <View style={styles.header}>
        <View style={styles.headerInfo}>
          <Text style={styles.headerName}>{profile.full_name}</Text>
          <Text style={styles.headerRole}>Motorista • {driver.availability}</Text>
        </View>
        <TouchableOpacity
          style={styles.logoutButton}
          onPress={handleLogout}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
        >
          <Text style={styles.logoutText}>Sair</Text>
        </TouchableOpacity>
      </View>

      {/* Disponibilidade online/offline */}
      <View style={styles.availabilityRow}>
        <View style={styles.availabilityIndicator}>
          <View
            style={[
              styles.dot,
              isOnline ? styles.dotOnline : styles.dotOffline,
            ]}
          />
          <Text style={styles.availabilityText}>
            {isOnline ? 'Online' : 'Offline'}
          </Text>
        </View>
        <TouchableOpacity
          style={styles.toggleButton}
          onPress={handleToggleAvailability}
          disabled={refreshing}
        >
          <Text style={styles.toggleText}>
            {refreshing ? 'Atualizando...' : 'Alternar disponibilidade'}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Mapa (placeholder até a prova do MapLibre na FASE 2A) */}
      <View style={styles.mapContainer}>
        <View style={styles.mapPlaceholder}>
          <Text style={styles.mapPlaceholderText}>
            Mapa — aguardando prova do MapLibre (FASE 2A)
          </Text>
          <Text style={styles.mapPlaceholderSub}>
            Tela do motorista — posição, embarque e destino serão exibidos aqui
          </Text>
        </View>
      </View>

      {/* Status da corrida */}
      <View style={styles.rideCard}>
        <Text style={styles.rideCardTitle}>Corrida ativa</Text>
        <Text style={styles.rideCardStatus}>Nenhuma corrida ativa no momento</Text>
        <View style={styles.rideActions}>
          <TouchableOpacity style={styles.actionButton}>
            <Text style={styles.actionText}>Aceitar solicitação</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.actionButtonSecondary}>
            <Text style={styles.actionTextSecondary}>Iniciar navegação (Waze)</Text>
          </TouchableOpacity>
        </View>
      </View>

      {refreshing && (
        <View style={styles.loadingOverlay}>
          <ActivityIndicator size="small" color="#3B82F6" />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 16,
  },
  headerInfo: {
    flex: 1,
  },
  headerName: {
    color: '#F8FAFC',
    fontSize: 20,
    fontWeight: '700',
  },
  headerRole: {
    color: '#94A3B8',
    fontSize: 14,
    marginTop: 2,
  },
  logoutButton: {
    padding: 8,
  },
  logoutText: {
    color: '#F87171',
    fontSize: 14,
    fontWeight: '600',
  },
  availabilityRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingBottom: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#334155',
  },
  availabilityIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  dot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  dotOnline: {
    backgroundColor: '#22C55E',
  },
  dotOffline: {
    backgroundColor: '#64748B',
  },
  availabilityText: {
    color: '#F8FAFC',
    fontSize: 16,
    fontWeight: '600',
  },
  toggleButton: {
    backgroundColor: '#1E293B',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
  },
  toggleText: {
    color: '#94A3B8',
    fontSize: 14,
  },
  mapContainer: {
    flex: 1,
    marginHorizontal: 16,
    marginBottom: 16,
  },
  mapPlaceholder: {
    flex: 1,
    backgroundColor: '#1E293B',
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#334155',
  },
  mapPlaceholderText: {
    color: '#64748B',
    fontSize: 14,
    fontWeight: '600',
    textAlign: 'center',
    marginBottom: 4,
  },
  mapPlaceholderSub: {
    color: '#94A3B8',
    fontSize: 12,
    textAlign: 'center',
  },
  rideCard: {
    backgroundColor: '#1E293B',
    borderRadius: 16,
    padding: 20,
    marginHorizontal: 16,
    marginBottom: 24,
    borderWidth: 1,
    borderColor: '#334155',
  },
  rideCardTitle: {
    color: '#F8FAFC',
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 8,
  },
  rideCardStatus: {
    color: '#94A3B8',
    fontSize: 14,
    marginBottom: 16,
  },
  rideActions: {
    flexDirection: 'row',
    gap: 10,
  },
  actionButton: {
    backgroundColor: '#22C55E',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 10,
    flex: 1,
  },
  actionText: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
    textAlign: 'center',
  },
  actionButtonSecondary: {
    backgroundColor: '#3B82F6',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 10,
    flex: 1,
  },
  actionTextSecondary: {
    color: '#FFFFFF',
    fontSize: 14,
    fontWeight: '700',
    textAlign: 'center',
  },
  loadingOverlay: {
    position: 'absolute',
    left: 0,
    top: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    justifyContent: 'center',
    alignItems: 'center',
  },
});
