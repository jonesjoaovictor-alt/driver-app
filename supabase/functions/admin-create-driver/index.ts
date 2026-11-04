import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  // Apenas POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Método não permitido. Use POST.' }),
      { status: 405, headers: { 'Content-Type': 'application/json' } }
    );
  }

  let body: { email: string; password: string; full_name: string; phone?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: 'Corpo da requisição inválido.' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const { email, password, full_name, phone } = body;

  if (!email || !password || !full_name) {
    return new Response(
      JSON.stringify({ error: 'email, password e full_name são obrigatórios.' }),
      { status: 400, headers: { 'Content-Type': 'application/json' } }
    );
  }

  // Cliente Supabase com service_role (somente servidor)
  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // 1. Obtém o usuário autenticado a partir do Bearer token
  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Token de autenticação não fornecido.' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const token = authHeader.replace('Bearer ', '');

  // Verifica quem está chamando (usa o próprio token do solicitante)
  const { data: me, error: meError } = await supabase.auth.getUser(token);
  if (meError || !me.user) {
    return new Response(
      JSON.stringify({ error: 'Não autenticado.' }),
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const callerId = me.user.id;

  // 2. Confirma que o papel é 'admin' NO BANCO (não no metadata do JWT)
  const { data: callerProfile, error: profileError } = await supabase
    .from('profiles')
    .select('role, is_active')
    .eq('auth_user_id', callerId)
    .single();

  if (profileError || !callerProfile || callerProfile.role !== 'admin' || !callerProfile.is_active) {
    return new Response(
      JSON.stringify({ error: 'Apenas administradores ativos podem criar motoristas.' }),
      { status: 403, headers: { 'Content-Type': 'application/json' } }
    );
  }

  // 3. Cria o usuário no Auth com service_role
  const { data: createdUser, error: createUserError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name },
  });

  if (createUserError || !createdUser?.user) {
    return new Response(
      JSON.stringify({ error: 'Falha ao criar usuário no Auth.', details: createUserError?.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const newAuthUserId = createdUser.user.id;

  // 4. Chama função SQL transacional que cria profiles + drivers.
  //    Se falhar, remove o usuário do Auth (não deixa conta órfã).
  const { error: rpcError } = await supabase.rpc('create_driver_account', {
    p_auth_user_id: newAuthUserId,
    p_full_name: full_name,
    p_phone: phone ?? null,
  });

  if (rpcError) {
    // Compensação: remove o usuário do Auth criado no passo 3
    await supabase.auth.admin.deleteUser(newAuthUserId);

    return new Response(
      JSON.stringify({ error: 'Falha ao criar perfil e motorista. Conta do Auth removida.', details: rpcError.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }

  return new Response(
    JSON.stringify({ ok: true, driver_auth_user_id: newAuthUserId }),
    { status: 200, headers: { 'Content-Type': 'application/json' } }
  );
});
