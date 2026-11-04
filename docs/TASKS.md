## FASE 2 — Interface · [x] base + serviços criados · próxima: 2A (prova do MapLibre)

Tela de login, navegação, tela base do motorista, cliente Supabase,
AuthProvider, camada de serviços e hooks criados. `tsc --noEmit` limpo,
`expo-doctor` 20/20.

- [x] src/types/database.ts — tipos do banco + funções RPC
- [x] src/services/supabase/client.ts — cliente Supabase (chave anon)
- [x] src/app/providers/AuthProvider.tsx — sessão, perfil, motorista
- [x] src/app/navigation/RootNavigator.tsx — navegação Login ↔ Driver
- [x] src/screens/auth/LoginScreen.tsx — tela de login
- [x] src/screens/driver/DriverScreen.tsx — tela base do motorista (disponibilidade, mapa placeholder, corrida ativa)
- [x] App.tsx — AuthProvider + NavigationContainer
- [x] src/services/rides.ts — chamadas RPC (accept, complete, cancel, etc.)
- [x] src/services/location.ts — GPS, permissões, rastreamento contínuo
- [x] src/database/local/sqlite.ts — cache local (corrida ativa + fila posições)
- [x] src/services/notifications.ts — notificação persistente (serviço de localização)
- [x] src/services/realtime.ts — inscrição Supabase Realtime (corridas, localizações)
- [x] src/hooks/useRides.ts — hook de corridas com cache SQLite
- [x] src/hooks/useLocation.ts — hook de GPS com fila de pendentes
- [ ] Prova do MapLibre (FASE 2A) — pendente na máquina de build
- [ ] Tela do motorista com mapa real (após prova do MapLibre)
- [ ] Entrada administrativa por sete toques
- [ ] Estados de erro visuais

## FASE 3 — Backend e segurança · [x] escritas · pendente: aplicar

- [x] `0001_profiles.sql` — enums, perfis, contexto, proteção de papel
- [x] `0002_catalogs.sql` — cadastros, limites de 5, contexto de motorista
- [x] `0003_active_rides.sql` — corridas, índices únicos, travas
- [x] `0004_ride_operations.sql` — recibos e limpeza
- [x] `0005_driver_locations.sql` — localização ao vivo
- [x] `0006_rls.sql` — RLS, grants e policies
- [x] `0007_rpc.sql` — funções de transição — CORRIGIDO (sintaxe, tipos, identidade, idempotência, RPCs faltantes)
- [x] `0008_seed.sql` — dados fictícios (5 passageiros, estrutura 5 motoristas/veículos)
- [x] Edge Function `admin-create-driver` (escrita)
- [ ] Criar projeto Supabase
- [ ] Aplicar migrações 0001 a 0008 na ordem
- [ ] Desativar cadastro público
- [ ] Executar matriz de testes de segurança (`docs/SECURITY.md` §10)
- [ ] Agendar limpeza de `ride_operations`
- [ ] Documentar backup do esquema

## FASE 4 — Administração · não iniciada

- [ ] Cadastros de motoristas, veículos, passageiros
- [ ] Criação de solicitações de corrida
- [ ] Consulta de corridas ativas

## FASE 5 — Corridas · não iniciada

- [ ] Máquina de estados (requested → accepted → driver_arriving → arrived → in_progress)
- [ ] Aceitação atômica com idempotência
- [ ] Concorrência (dois motoristas, mesma corrida)
- [ ] Realtime para novas solicitações
- [ ] Conclusão e cancelamento transacionais

## FASE 6 — Persistência/offline · não iniciada

- [ ] Recuperação de estado após fechamento/reinício (usa SQLite já criado)
- [ ] Reconciliação com servidor (usa realtime.ts já criado)

## FASE 7 — GPS/mapa · não iniciada

- [ ] Prova do MapLibre (FASE 2A — pré-requisito obrigatório)
- [ ] Permissões de localização (useLocation já criado)
- [ ] Serviço em segundo plano + notificação persistente (notifications.ts já criado)
- [ ] Heartbeat (last_seen_at a cada 30s)

## FASE 8 — Navegação · não iniciada

- [ ] Waze Deep Links
- [ ] Tratamento de Waze não instalado

## FASE 9 — Testes · não iniciada

- [ ] Testes funcionais, segurança, concorrência, recuperação
- [ ] Teste em aparelho Android físico

## FASE 10 — Consolidação · não iniciada

- [ ] Revisão, documentação, segurança, versão de teste
