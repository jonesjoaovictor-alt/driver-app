-- =============================================================================
-- 0008 — Seed de desenvolvimento (dados fictícios)
-- =============================================================================
-- STATUS: a escrever, NÃO aplicado, NÃO testado.
--
-- Regras de origem:
--   MASTER_SPEC.md §3 (máximo 5 motoristas, 5 passageiros fictícios),
--   §5 (passageiros são registros fictícios, sem dados reais),
--   §9 (tabelas), ADR-006 (papel único)
--
-- Todos os dados são fictícios. Não usar nomes, telefones ou placas de
-- pessoas reais. Os triggers de limite (trg_drivers_limit,
-- trg_passengers_limit) impedem que mais de 5 registros sejam inseridos.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Profis de administração (primeiro admin)
-- -----------------------------------------------------------------------------
-- O primeiro administrador deve ser provisionado manualmente no painel do
-- Supabase (docs/SECURITY.md §6). Este seed NÃO cria admin automaticamente
-- para evitar expor credenciais. Insere apenas perfis de motorista para
-- demonstração.

-- -----------------------------------------------------------------------------
-- Passageiros fictícios (máximo 5)
-- -----------------------------------------------------------------------------
-- Dados fictícios, sem relação com pessoas reais.

insert into public.passengers (name, phone, is_active)
values
  ('Passageiro Fictício 1', '(11) 90000-0001', true),
  ('Passageiro Fictício 2', '(11) 90000-0002', true),
  ('Passageiro Fictício 3', '(11) 90000-0003', true),
  ('Passageiro Fictício 4', '(11) 90000-0004', true),
  ('Passageiro Fictício 5', '(11) 90000-0005', true)
on conflict do nothing;

-- -----------------------------------------------------------------------------
-- Motoristas e veículos (máximo 5 de cada)
-- -----------------------------------------------------------------------------
-- Os profiles de motorista devem existir previamente (criados via Edge
-- Function admin-create-driver ou provisionamento manual). Este seed insere
-- apenas registros de drivers e vehicles vinculados a profiles que devem ser
-- criados separadamente.
--
-- Exemplo de estrutura (descomentar e ajustar quando houver profiles criados):
--
-- insert into public.drivers (profile_id, is_active, availability)
-- values
--   ('<profile_uuid_driver_1>', true, 'offline'),
--   ('<profile_uuid_driver_2>', true, 'offline'),
--   ('<profile_uuid_driver_3>', true, 'offline'),
--   ('<profile_uuid_driver_4>', true, 'offline'),
--   ('<profile_uuid_driver_5>', true, 'offline')
-- on conflict do nothing;
--
-- insert into public.vehicles (driver_id, brand, model, plate, color, is_active)
-- values
--   ('<driver_uuid_1>', 'Fiat', 'Mobi', 'ABC1234', 'Prata', true),
--   ('<driver_uuid_2>', 'Volkswagen', 'Gol', 'DEF5678', 'Preto', true),
--   ('<driver_uuid_3>', 'Chevrolet', 'Onix', 'GHI9012', 'Branco', true),
--   ('<driver_uuid_4>', 'Ford', 'Ka', 'JKL3456', 'Vermelho', true),
--   ('<driver_uuid_5>', 'Toyota', 'Yaris', 'MNO7890', 'Azul', true)
-- on conflict do nothing;

comment on table public.passengers is
  'Passageiros fictícios de seed. Dados não reais.';
comment on table public.drivers is
  'Cadastros de motorista de seed. Vincular a profiles reais via admin-create-driver.';
comment on table public.vehicles is
  'Veículos de seed. Vincular a drivers reais via admin-create-driver.';
