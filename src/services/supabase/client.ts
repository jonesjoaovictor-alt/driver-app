import { createClient } from '@supabase/supabase-js';
import type { Database } from '../../types/database';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'EXPO_PUBLIC_SUPABASE_URL e EXPO_PUBLIC_SUPABASE_ANON_KEY são obrigatórios. ' +
    'Copie .env.example para .env e preencha com os valores do projeto Supabase.'
  );
}

/**
 * Cliente Supabase para o aplicativo do motorista.
 *
 * Usa apenas a chave anon (pública). O service_role NUNCA deve estar no app.
 * Todas as operações críticas passam por RPCs no servidor.
 */
export const supabase = createClient<Database>(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: false,
  },
});

export default supabase;
