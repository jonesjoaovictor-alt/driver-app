import { createStackNavigator } from '@react-navigation/stack';
import type { RootStackParamList } from './types';
import { LoginScreen } from '../../screens/auth/LoginScreen';
import { DriverScreen } from '../../screens/driver/DriverScreen';

const Stack = createStackNavigator<RootStackParamList>();

export function RootNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="Driver" component={DriverScreen} />
    </Stack.Navigator>
  );
}
