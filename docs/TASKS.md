## FASE 3 — Backend e segurança · `[x]` (escrito, pronto para aplicar)

Migrações escritas e revisadas. Próximo passo: criar projeto Supabase e aplicar.

-   [x] `0001_profiles.sql` — enums, perfis, contexto, proteção de papel
-   [x] `0002_catalogs.sql` — cadastros, limites de 5, contexto de motorista
-   [x] `0003_active_rides.sql` — corridas, índices únicos, travas
-   [x] `0004_ride_operations.sql` — recibos e limpeza
-   [x] `0005_driver_locations.sql` — localização ao vivo
-   [x] `0006_rls.sql` — RLS, grants e policies
-   [x] `0007_rpc.sql` — funções de transição (accept, cancel, complete, etc.)
-   [ ] `0008_seed.sql` — dados fictícios (5 motoristas, 5 passageiros, 5 veículos)
-   [ ] Criar projeto Supabase
-   [ ] Aplicar migrações 0001 a 0007 na ordem
-   [ ] Desativar cadastro público
-   [ ] Edge Function `admin-create-driver`
-   [ ] Executar matriz de testes de segurança
-   [ ] Agendar limpeza de `ride_operations`
-   [ ] Documentar backup do esquema