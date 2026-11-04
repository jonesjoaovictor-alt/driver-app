import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View } from 'react-native';

/**
 * Ponto de entrada provisório da FASE 1B.
 *
 * Não é uma tela do produto. Serve apenas para confirmar que o projeto
 * compila e executa. A navegação e as telas reais entram na FASE 2,
 * conforme MASTER_SPEC.md §23.
 */
export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>DRIVER APP</Text>
      <Text style={styles.subtitle}>FASE 1B — estrutura criada</Text>
      <StatusBar style="light" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0F172A',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  title: {
    color: '#F8FAFC',
    fontSize: 28,
    fontWeight: '700',
    letterSpacing: 1,
  },
  subtitle: {
    color: '#94A3B8',
    fontSize: 14,
    marginTop: 8,
  },
});
