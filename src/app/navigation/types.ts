/**
 * Tipos de navegação do aplicativo.
 *
 * Define as telas e parâmetros de cada uma, garantindo type safety na
 * navegação entre telas.
 */

export type RootStackParamList = {
  // Telas de autenticação
  Login: undefined;
  // Tela principal do motorista
  Driver: undefined;
  // Administração (oculta, por gesto secreto)
  AdminLogin: undefined;
  Admin: undefined;
};
