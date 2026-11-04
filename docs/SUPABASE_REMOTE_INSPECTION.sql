-- =============================================================================
-- SUPABASE_REMOTE_INSPECTION.sql
-- Auditoracao remota via SQL Editor do painel Supabase (apenas leitura).
-- Execucao: Painel Supabase > SQL Editor > Executar.
-- AVISO: So consultas de leitura (SELECT). Nenhum INSERT, UPDATE, DELETE,
-- DROP, ALTER, CREATE ou TRUNCATE.
-- PostgreSQL 17 compatibilidade.
-- =============================================================================

-- 1. Listar tabelas existentes nos schemas relevantes
SELECT table_name, table_schema
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. Listar enums e tipos personalizados
SELECT typname, elemtype, typowner
FROM pg_type
WHERE typtype = 'e'
  AND schema = 'public'
ORDER BY typname;

-- 3. Listar funções (funções)
SELECT proname, prosrc, prosqlsecurity, pronargs
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY proname;

-- 4. Listar triggers
SELECT tgname, tgrelid::regclass, tgtype, tgenabled
FROM pg_trigger
WHERE tgrelid::regclass IN (
  'profiles', 'drivers', 'vehicles', 'passengers',
  'active_rides', 'ride_operations', 'driver_live_locations'
)
ORDER BY tgname;

-- 5. Listar constraints (check, unique, foreign key)
SELECT conname, contype, inhcount, probefk
FROM pg_constraint
WHERE connamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
ORDER BY conname;

-- 6. Listar indices
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY indexname;

-- 7. Listar policies RLS por tabela
SELECT polname, polcmd, polroles, polqual, polwithcheck
FROM pg_policy
WHERE polschema = 'public'
ORDER BY polname, tablename;

-- 8. Estado de RLS por tabela
SELECT relname, relrowsecurity, relforcerowsecurity, relhastriggers
FROM pg_class
WHERE relname IN (
  'profiles', 'drivers', 'vehicles', 'passengers',
  'active_rides', 'ride_operations', 'driver_live_locations'
)
RELATIVE reloptions
ORDER BY relname;

-- 9. GRANT e REVOKE efetivos
SELECT grantee, privilege_type, is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name IN (
    'profiles', 'drivers', 'vehicles', 'passengers',
    'active_rides', 'ride_operations', 'driver_live_locations'
  )
ORDER BY grantee, privilege_type;

-- 10. Extensões instaladas
SELECT extname, extversion
FROM pg_extension
ORDER BY extname;

-- 11. Objetos relacionados ao histórico de migrations
-- Verificar se existe tabela ou registro de migrations aplicadas
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%migrat%'
  OR table_name LIKE '%supabase%';

-- 12. Estado de dados nas tabelas relevantes (apenas contagens, sem dados pessoais)
SELECT 
  (SELECT count(*) FROM public.profiles) AS profiles_count,
  (SELECT count(*) FROM public.drivers) AS drivers_count,
  (SELECT count(*) FROM public.vehicles) AS vehicles_count,
  (SELECT count(*) FROM public.passengers) AS passengers_count,
  (SELECT count(*) FROM public.active_rides) AS active_rides_count,
  (SELECT count(*) FROM public.ride_operations) AS ride_operations_count,
  (SELECT count(*) FROM public.driver_live_locations) AS driver_live_locations_count;