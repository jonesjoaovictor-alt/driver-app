# Segurança

Documento de apoio ao `MASTER_SPEC.md` §10. Escrito antes da FASE 3 para que
a implementação não invente política no meio do caminho.

**Status:** desenho. Nada foi aplicado em banco ainda.

## 1. Modelo de confiança

```text
NÃO CONFIÁVEL                    CONFIÁVEL
APK instalado                    Servidor Supabase
· usuário pode alterar o app     · service_role
· pode ler o bundle              · JWT assinado
· pode chamar a API direto       · funções SQL
· pode reescrever o SQLite       · Edge Functions
```

Toda regra crítica vive à direita. O aplicativo é conveniência, não
segurança.

## 2. Papéis

| Papel | Como existe | O que pode |
|---|---|---|
| `anon` | sem login | nada além do mínimo do Supabase Auth |
| `authenticated` / `driver` | login de motorista | próprios dados, próprias corridas, própria localização |
| `authenticated` / `admin` | login administrativo | cadastros, corridas, liberação de estado |
| `service_role` | **somente servidor** | cria contas, limpeza agendada |

`role` fica em `profiles`, não em metadata do JWT. Metadata pode ser
alterada pelo próprio usuário em alguns fluxos; tabela com RLS e grant
restrito, não.

## 3. Matriz de acesso

| Tabela | Driver | Admin | Cliente escreve direto? |
|---|---|---|---|
| `profiles` | lê o próprio, edita nome/telefone | lê e edita todos | sim, com trigger protegendo `role`/`is_active` |
| `drivers` | lê o próprio | lê e edita todos | admin sim; motorista não (usa RPC) |
| `vehicles` | lê os próprios | tudo | admin |
| `passengers` | **nada** | tudo | admin |
| `active_rides` | lê as próprias | tudo | **não** — só RPC |
| `ride_operations` | nada | lê | **não** |
| `driver_live_locations` | lê a própria | tudo | **não** — só RPC |

O motorista nunca lê nome ou telefone de passageiro.

## 4. Ofertas sem dono

Problema: o motorista precisa ver corridas `requested` sem motorista para
aceitar, mas não pode ver dados do passageiro.

Solução (ADR-019): função `list_available_rides()`, `security definer`, que
retorna só `id`, rótulos, coordenadas, valor e `created_at`, e exige
motorista ativo. Não é `view`, para não depender de comportamento implícito
de RLS.

## 5. Criação de contas

Nenhum usuário se cadastra. `signUp` público desativado.

Fluxo oficial (ADR-005):

```text
Admin autenticado
   └─ Edge Function admin-create-driver
        ├─ valida JWT e confirma role=admin NO BANCO
        ├─ cria usuário no Auth com service_role
        ├─ chama função SQL que cria profiles + drivers
        └─ se falhar, apaga o usuário do Auth (compensação)
```

Por que não no cliente: criar usuário no Auth exige `service_role`, que
ignora RLS por completo. Se essa chave entrar no APK, qualquer pessoa extrai
e passa a controlar o banco.

## 6. Primeiro administrador

Procedimento manual, uma única vez, no painel do Supabase. Ordem:

1. Criar o usuário no Auth (e-mail e senha forte, e-mail confirmado).
2. Inserir a linha em `profiles` com `role = 'admin'` via SQL Editor.
3. Conferir: `select id, role, is_active from profiles;`
4. Nunca repetir isso pelo aplicativo.

Sem esse passo, o sistema fica sem administrador e a criação de motoristas
não pode começar. É o único ponto que exige acesso humano ao painel.

## 7. Segredos

| Segredo | Onde pode existir |
|---|---|
| `SUPABASE_ANON_KEY` | no APK (é pública por projeto) |
| `SUPABASE_URL` | no APK |
| `SUPABASE_SERVICE_ROLE_KEY` | **somente** no servidor / Edge Function |
| senha do banco | **somente** no painel |
| keystore de assinatura | fora do repositório, com backup |

`.env` nunca é versionado. `.env.example` só tem nomes e valores falsos.

## 8. Proibições explícitas

-   Papel definido por metadata do JWT.
-   `service_role` no aplicativo.
-   RLS desabilitada em tabela exposta.
-   Policy `using (true)` em tabela com dado pessoal.
-   Função `security definer` sem `set search_path`.
-   Log de token, senha, coordenada ou telefone.
-   `DELETE` físico de cadastro com dependência.
-   Confiar em checagem feita só no frontend.

## 9. Checklist de revisão da FASE 3

Antes de considerar o backend pronto:

-   [ ] RLS habilitada em todas as tabelas de `public`
-   [ ] `anon` sem acesso a nenhuma tabela do produto
-   [ ] `signUp` público desativado
-   [ ] Papel validado no banco em toda função administrativa
-   [ ] `service_role` ausente do APK e do repositório
-   [ ] Toda função `security definer` com `search_path` fixo
-   [ ] Limite de 5 testado com inserções simultâneas
-   [ ] Aceitação testada com dois motoristas ao mesmo tempo
-   [ ] Motorista A não lê corrida de B (teste negativo real)
-   [ ] `ride_operations` sem dado pessoal
-   [ ] Retenção de 30 dias agendada e verificada

## 10. Testes de segurança obrigatórios

Executar com dois usuários reais, não com simulação.

| Teste | Esperado |
|---|---|
| Driver A consulta `active_rides` de B | zero linhas |
| Driver A chama `accept_ride` já aceita | erro, sem efeito |
| Driver altera o próprio `role` | erro `42501` |
| Usuário sem login consulta tabela | erro de permissão |
| Admin cria o sexto motorista | erro `LIMITE_ATINGIDO` |
| Motorista lê `passengers` | zero linhas |
| Motorista chama RPC de corrida alheia | erro |

Teste que não foi executado não conta como aprovado.
