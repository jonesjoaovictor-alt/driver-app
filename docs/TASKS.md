## FASE 2 — Interface · [x] base criada · próxima: 2A (prova do MapLibre)

Tela de login, navegação, tela base do motorista, cliente Supabase e
AuthProvider criados. `tsc --noEmit` limpo, `expo-doctor` 20/20.

- [x] src/types/database.ts — tipos do banco espelhando as migrações
- [x] src/services/supabase/client.ts — cliente Supabase (chave anon)
- [x] src/app/providers/AuthProvider.tsx — sessão, perfil, motorista
- [x] src/app/navigation/RootNavigator.tsx — navegação Login ↔ Driver
- [x] src/screens/auth/LoginScreen.tsx — tela de login
- [x] src/screens/driver/DriverScreen.tsx — tela base do motorista (disponibilidade, mapa placeholder, corrida ativa)
- [x] App.tsx — envelve com AuthProvider + NavigationContainer
- [ ] Prova do MapLibre (FASE 2A) — pendente na máquina de build
- [ ] Tela do motorista com mapa real (após prova do MapLibre)
- [ ] Entrada administrativa por sete toques
- [ ] Estados de erro visuais

## FASE 3 — Backend e segurança · [x] escritas · pendente: aplicar

Migrações escritas, corrigidas e revisadas. `0007_rpc.sql` corrigido (sintaxe,
tipos, validação de identidade, idempotência, RPCs faltantes).

- [x] `0001_profiles.sql` — enums, perfis, contexto, proteção de papel
- [x] `0002_catalogs.sql` — cadastros, limites de 5, contexto de motorista
- [x] `0003_active_rides.sql` — corridas, índices únicos, travas
- [x] `0004_ride_operations.sql` — recibos e limpeza
- [x] `0005_driver_locations.sql` — localização ao vivo
- [x] `0006_rls.sql` — RLS, grants e policies
- [x] `0007_rpc.sql` — funções de transição (accept, cancel, complete, etc.) — CORRIGIDO
- [x] `0008_seed.sql` — dados fictícios (5 motoristas, 5 passageiros, 5 veículos)
- [ ] Criar projeto Supabase
- [ ] Aplicar migrações 0001 a 0008 na ordem
- [ ] Desativar cadastro público
- [x] Edge Function `admin-create-driver` (escrita)
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

- [ ] SQLite local (cópia mínima da corrida ativa)
- [ ] Recuperação de estado após fechamento/reinício
- [ ] Reconciliação com servidor

## FASE 7 — GPS/mapa · não iniciada

- [ ] Prova do MapLibre (FASE 2A — pré-requisito)
- [ ] Permissões de localização
- [ ] Serviço em segundo plano + notificação persistente
- [ ] Heartbeat (last_seen_at a cada 30s)

## FASE 8 — Navegação · não iniciada

- [ ] Waze Deep Links
- [ ] Tratamento de Waze não instalado

## FASE 9 — Testes · não iniciada

- [ ] Testes funcionais, segurança, concorrência, recuperação
- [ ] Teste em aparelho Android físico

## FASE 10 — Consolidação · não iniciada

- [ ] Revisão, documentação, segurança, versão de teste
