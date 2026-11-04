import { StatusBar } from 'expo-status-bar';
import { NavigationContainer } from '@react-navigation/native';
import { AuthProvider } from './src/app/providers/AuthProvider';
import { RootNavigator } from './src/app/navigation/RootNavigator';

/**
 * Ponto de entrada do aplicativo DRIVER APP.
 *
 * Envolve a navegação com AuthProvider para gerenciar a sessão do Supabase.
 * O estado inicial é a tela de Login; após autenticação bem-sucedida, o
 * usuário é direcionado para a tela do motorista.
 *
 * NOTA: A navegação condicional entre Login e Driver com base na sessão
 * será implementada após a conexão com Supabase ser testada. Por enquanto,
 * o RootNavigator renderiza as duas telas disponíveis.
 */
export default function App() {
  return (
    <AuthProvider>
      <NavigationContainer>
        <StatusBar style="light" />
        <RootNavigator />
      </NavigationContainer>
    </AuthProvider>
  );
}
