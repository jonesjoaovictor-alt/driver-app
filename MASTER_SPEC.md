# DRIVER APP --- ESPECIFICAÇÃO MESTRE DE ENGENHARIA

**Versão:** 1.1.0\
**Status:** Especificação consolidada — revisão de auditoria\
**Revisão:** 2026-11-03\
**Decisões detalhadas:** `docs/DECISIONS.md` (ADRs)\
**Plataforma:** Android\
**Finalidade inicial:** Testes controlados\
**Documento canônico:** `MASTER_SPEC.md`

------------------------------------------------------------------------

## 1. Missão do projeto

Construir um aplicativo Android de transporte inspirado na experiência
de utilização da Uber, com arquitetura, código e identidade próprios. A
Uber é somente referência de experiência: não acessar, modificar ou
editar o site original da Uber.

O projeto deverá ser seguro, organizado, documentado, testável e
independente da memória de qualquer IA. O desenvolvimento deve priorizar
integridade dos dados, segurança, persistência, compatibilidade Android
e manutenção.

A IA deverá atuar como engenheira de software: analisar requisitos,
antecipar falhas, explicar riscos, implementar em etapas e testar o que
entregar.

## 2. Isolamento obrigatório

O projeto ficará em uma pasta independente chamada `driver-app`.

É proibido: - Modificar o site original da Uber. - Alterar o projeto JCS
Soluções Elétricas. - Modificar, excluir, mover ou sobrescrever arquivos
de outros projetos. - Executar comandos destrutivos sem autorização. -
Alterar configurações globais do Windows sem necessidade e
autorização. - Presumir que o terminal está no diretório correto.

Antes de qualquer alteração, confirmar o diretório, verificar o estado
do Git e identificar os arquivos envolvidos. Se houver risco de atingir
outro projeto, parar e pedir orientação.

Não executar `git reset --hard`, `git clean -fd`, `git checkout .` ou
equivalentes sem autorização expressa.

## 3. Decisões funcionais definitivas

  -----------------------------------------------------------------------
  Item                                Decisão
  ----------------------------------- -----------------------------------
  Nome                                DRIVER APP

  Plataforma                          Android

  Aplicativo                          Um único aplicativo

  Interface padrão                    Motorista

  Administração                       Oculta dentro do aplicativo

  Acesso administrativo               Sete toques no logotipo, seguidos
                                      de autenticação

  Papel duplo (admin e motorista)     Não permitido na versão 1

  Cadastro público de contas          Desativado no Supabase Auth

  Criação de conta de motorista       Pela administração, via Edge
                                      Function no servidor (seção 5)

  Motoristas                          Máximo de 5

  Passageiros fictícios               Máximo de 5

  Veículos                            Carros

  Veículos ativos                     1 por motorista

  Corridas ativas                     1 por motorista e 1 por passageiro

  GPS                                 GPS real do celular

  Localização em segundo plano        Sim, respeitando permissões e
                                      limitações Android

  Mapa                                MapLibre

  Navegação                           Waze por Deep Links

  Backend                             Supabase

  Banco                               PostgreSQL

  Autenticação                        Supabase Auth

  Tempo real                          Supabase Realtime

  Persistência local                  SQLite

  Histórico de viagens                Não implementar

  Pagamentos                          Não implementar

  Finalidade                          Testes controlados

  Testes                              Aparelho Android físico
  -----------------------------------------------------------------------

A administração não terá botão visível na navegação comum. O gesto
secreto apenas revela a tela de login; não é mecanismo de segurança. O
backend deverá validar o papel administrativo.

Não haverá aplicativo separado para passageiros nesta versão.
Passageiros serão registros fictícios criados e reutilizados pela
administração, sem login.

## 4. Experiência do motorista

A tela padrão do aplicativo será a do motorista. Deverá oferecer: -
Login e logout. - Identificação do motorista e do veículo. - Estado
online/offline. - Indicadores de conexão e GPS. - Mapa e posição
atual. - Recebimento de solicitações. - Aceitar ou recusar
solicitações. - Visualizar passageiro, embarque e destino. - Confirmar
chegada, iniciar e finalizar corrida. - Abrir navegação no Waze. -
Recuperar o estado da corrida ao reabrir o aplicativo.

Estados do motorista: `offline`, `online`, `busy`.

-   Offline: não recebe solicitações.
-   Online: pode receber solicitações.
-   Busy: possui corrida ativa.
-   Ao concluir a corrida, poderá voltar a ficar online.

A disponibilidade deverá ser validada pelo backend, não apenas pela
interface.

## 5. Administração

A administração poderá: - Criar, editar, consultar, ativar e desativar
motoristas. - Cadastrar e vincular carros aos motoristas. - Criar,
editar, consultar, ativar e desativar passageiros fictícios. - Definir
embarque e destino. - Informar preço estimado de teste. - Criar
solicitações. - Consultar corridas ativas. - Cancelar solicitações
conforme as regras.

Limites de cinco motoristas e cinco passageiros devem ser impostos no
banco/backend, inclusive diante de cadastros simultâneos. Não confiar em
bloqueios somente na interface.

O primeiro administrador deverá ser provisionado por procedimento seguro
no Supabase ou ambiente confiável. Nunca permitir autoelevação de papel
pelo aplicativo. Nunca inserir `service_role` no cliente.

O cadastro público de contas no Supabase Auth deverá estar desativado.
Nenhuma conta é criada pelo próprio usuário no aplicativo.

### Criação de contas de motorista

Criar uma conta de autenticação exige credencial administrativa, que não
pode existir no aplicativo. O caminho oficial será uma Edge Function
(`admin-create-driver`) executada no servidor, que:

1. Valida o JWT do solicitante e confirma que o papel é `admin` no banco,
   nunca no metadata editável.
2. Cria o usuário no Auth com `service_role`, que existe somente no
   servidor.
3. Chama uma função SQL transacional que cria `profiles` e `drivers`.
4. Se o passo 3 falhar, remove o usuário do Auth criado no passo 2, para
   não deixar conta órfã.

O provisionamento manual pelo painel do Supabase é contingência
documentada, não o fluxo normal. O procedimento deverá constar em
`docs/SECURITY.md` na FASE 3.

### Cancelamento

Quem pode cancelar depende do estado da corrida. A matriz completa está na
seção 7. Nenhum cancelamento altera dados de cadastro.

Cadastros com dependências ativas não devem ser excluídos de forma que
corrompa dados. Preferir desativação lógica. Passageiros desativados não
poderão gerar novas solicitações, mas dados necessários a uma corrida já
ativa deverão ser preservados. Não permitir trocar ou excluir veículo
durante corrida ativa.

## 6. Regras de negócio

-   Máximo de 5 motoristas cadastrados.
-   Máximo de 5 passageiros fictícios cadastrados.
-   Um veículo ativo por motorista.
-   Uma corrida ativa por motorista.
-   Uma corrida ativa por passageiro.
-   Uma solicitação só pode ser aceita por um motorista.
-   Não permitir corrida nova para motorista ou passageiro já ocupado.
-   Não excluir cadastros com dependências ativas.
-   O preço estimado será armazenado em unidade monetária mínima
    (centavos), como inteiro, nunca como ponto flutuante.
-   Coordenadas devem ser validadas: latitude entre -90 e 90; longitude
    entre -180 e 180. Rejeitar valores inválidos, `NaN` e strings.
-   Timestamps do banco em UTC (`timestamptz`); interface converte para
    horário local.

As restrições críticas devem ser garantidas no PostgreSQL por
constraints, índices únicos parciais, transações e funções protegidas,
conforme necessário.

## 7. Arquitetura das corridas e persistência

**Regra central: uma corrida ativa não pode desaparecer antes de o
servidor confirmar seu encerramento.**

A tabela `active_rides` conterá somente corridas não concluídas e não
canceladas.

Estados ativos: `requested`, `accepted`, `driver_arriving`, `arrived`,
`in_progress`.

`completed` e `cancelled` são estados terminais de operação: não são
gravados em `active_rides`. Após confirmação transacional, o registro é
removido da tabela. Não haverá tabela de histórico.

Fluxo normal:
`requested → accepted → driver_arriving → arrived → in_progress → completed`

Transições de cancelamento permitidas:

-   `requested → cancelled` (somente administração).
-   `accepted`, `driver_arriving`, `arrived → cancelled` (administração ou
    motorista da corrida).
-   `in_progress → cancelled` (somente administração).

Recusa de solicitação não é estado persistido. O botão "recusar" apenas
oculta a oferta naquele aparelho, naquela sessão. A solicitação permanece
`requested` e disponível aos demais motoristas. Se o aplicativo for
reaberto, a oferta pode reaparecer. Essa limitação é aceita para no
máximo cinco motoristas e evita criar tabela de recusas.

As transições deverão ser validadas no backend. Não permitir iniciar
corrida cancelada, concluir corrida não iniciada, reabrir corrida
encerrada ou pular estados sem regra autorizada.

### Campos conceituais de `active_rides`

-   `id`
-   `passenger_id` (obrigatório, sempre definido na criação)
-   `driver_id` (nulo enquanto `requested`; definido na aceitação)
-   `vehicle_id` (nulo enquanto `requested`; definido na aceitação)
-   `pickup_latitude`
-   `pickup_longitude`
-   `pickup_label`
-   `destination_latitude`
-   `destination_longitude`
-   `destination_label`
-   `estimated_fare_cents`
-   `status`
-   `created_at`
-   `accepted_at`
-   `arrived_at`
-   `started_at`
-   `cancelled_at`
-   `cancelled_by` (nulo, `admin` ou `driver`)
-   `cancel_reason`
-   `updated_at`
-   `version`

Em `requested`, `driver_id` e `vehicle_id` devem ser nulos, pois a
solicitação ainda não pertence a ninguém. A restrição de uma corrida ativa
por motorista só se aplica a linhas com `driver_id` preenchido.

O estado terminal não fica registrado na linha, porque a linha é removida.
A prova técnica da operação fica em `ride_operations`.

A modelagem final deverá ser implementada por migrações SQL versionadas.

### Persistência

O servidor Supabase/PostgreSQL é a fonte oficial. SQLite mantém uma
cópia local mínima para recuperação.

A corrida deverá permanecer recuperável após: - Minimização e fechamento
normal do aplicativo. - Interrupção do processo. - Perda temporária de
internet. - Reinicialização do celular, desde que os dados e o servidor
permaneçam disponíveis.

Não excluir por timeout, fechamento, falha de rede, reinicialização ou
erro de sincronização. Não prometer recuperação após desinstalação,
limpeza dos dados ou perda definitiva do banco.

### Conclusão e cancelamento

Conclusão ou cancelamento autorizado deverá ser uma operação
transacional no servidor: 1. Autenticar o usuário. 2. Verificar se ele
tem autorização para aquela corrida. 3. Validar o estado atual. 4.
Executar a transição e remover o registro ativo na mesma transação. 5.
Confirmar o resultado. 6. Somente depois da confirmação, limpar a cópia
local.

Se a resposta se perder, o cliente não deverá repetir cegamente nem
apagar o cache. Deverá consultar o servidor e reconciliar o estado. Usar
identificador de operação/idempotência e mecanismo mínimo de recibo
técnico, sem criar histórico de viagens.

### Recibos de operação

A tabela `ride_operations` existe exclusivamente para impedir duplicação de
aceitação, conclusão e cancelamento. Ela não é histórico de viagens.

Conteúdo: `id`, `ride_id` (uuid simples, sem chave estrangeira), `operation`,
`actor_profile_id`, `idempotency_key` (único), `created_at`, `expires_at`.

Regras:

-   Nenhuma coordenada, trajeto, nome, telefone ou preço é gravado.
-   Sem chave estrangeira para `active_rides`, porque a corrida é removida
    antes dos recibos.
-   Retenção de 30 dias, com limpeza por rotina agendada.
-   Uma operação repetida com a mesma `idempotency_key` devolve o mesmo
    resultado, sem novo efeito.

Se o servidor não encontrar corrida ativa após uma resposta perdida,
reconciliar com a fonte oficial e não ressuscitar a cópia SQLite antiga.

### Sem histórico

Não criar `ride_history`, `completed_rides`, histórico de trajetos,
histórico de localização ou tabela permanente de eventos de corrida.
Logs técnicos mínimos podem existir para diagnóstico, sem conteúdo
sensível, sem trajetos e com retenção limitada. Changelog de
desenvolvimento não é histórico de viagens.

## 8. Concorrência e integridade

O backend deverá impedir: - Dois motoristas aceitando a mesma
solicitação. - Um motorista aceitando duas corridas. - Um passageiro
recebendo duas corridas. - Conclusões duplicadas. - Atualizações antigas
sobrescrevendo estados novos. - Cancelamento incompatível com início da
corrida.

A aceitação será atômica. Utilizar transações PostgreSQL, índices únicos
parciais e controle de versão/concorrência. Não confiar em bloqueios do
frontend.

A separação entre estado do motorista (`offline`, `online`, `busy`) e
estado da corrida é obrigatória.

### Heartbeat e estado obsoleto

Um aplicativo encerrado à força não avisa o servidor. Sem detecção, o
motorista ficaria `busy` para sempre e a corrida ficaria presa.

O aplicativo envia sinal de vida (`last_seen_at`) a cada 30 segundos
enquanto estiver `online` ou `busy`. Uma rotina agendada no servidor marca
como `offline` o motorista sem sinal há mais de 120 segundos.

Regras:

-   Marcar como `offline` nunca cancela nem conclui corrida.
-   Corrida de motorista sem sinal permanece ativa e visível à
    administração, que decide o encerramento.
-   Somente a administração libera um motorista `busy` sem corrida ativa
    correspondente (estado inconsistente).
-   `busy` só é atribuído pela aceitação no backend, nunca pelo cliente.
-   Motorista com corrida ativa não pode mudar para `offline` pela
    interface.

## 9. Banco de dados proposto

Tabelas iniciais:

### `profiles`

-   `id`
-   `auth_user_id`
-   `full_name`
-   `phone`
-   `role`
-   `is_active`
-   `created_at`
-   `updated_at`
-   `version`

Papéis iniciais: `driver` e `admin`. O papel administrativo deve ser
protegido por fonte confiável no banco/backend, nunca por metadata
livremente alterável pelo cliente. Um perfil tem exatamente um papel; não
existe papel duplo na versão 1.

### `drivers`

-   `id`
-   `profile_id`
-   `is_active` (cadastro ativo ou desativado)
-   `availability` (`offline`, `online`, `busy`)
-   `last_seen_at`
-   `created_at`
-   `updated_at`
-   `version`

`is_active` e `availability` são coisas diferentes e não devem ser
confundidas. `is_active` responde "este motorista pode operar?". A
disponibilidade responde "ele está recebendo solicitações agora?".
Desativar o cadastro deve forçar `offline`.

### `vehicles`

-   `id`
-   `driver_id`
-   `brand`
-   `model`
-   `plate`
-   `color`
-   `is_active`
-   `created_at`
-   `updated_at`
-   `version`

### `passengers`

-   `id`
-   `name`
-   `phone`
-   `is_active`
-   `created_at`
-   `updated_at`
-   `version`

Passageiros são fictícios. Dados reais de pessoas não devem ser usados
nestes cadastros.

### `active_rides`

Somente corridas ativas, conforme seção 7.

### `ride_operations`

Recibos de idempotência, conforme seção 7. Não é histórico de viagens.

### `driver_live_locations`

Uma linha por motorista, atualizada por upsert: - `driver_id` -
`latitude` - `longitude` - `accuracy` - `heading` - `speed` -
`recorded_at` - `updated_at`

Não inserir uma linha por leitura GPS. Não armazenar histórico de
localização. Ao ficar `offline`, a linha do motorista é removida, não
apenas marcada como antiga.

### Restrições que devem existir no PostgreSQL

-   Índice único parcial em `active_rides (driver_id)` onde `driver_id` não
    é nulo: uma corrida ativa por motorista.
-   Índice único em `active_rides (passenger_id)`: uma corrida ativa por
    passageiro, inclusive quando ainda está `requested`.
-   `CHECK` de latitude entre -90 e 90 e longitude entre -180 e 180 em
    `active_rides` e `driver_live_locations`.
-   `CHECK (estimated_fare_cents >= 0)`.
-   `CHECK` de `char_length` máximo nos rótulos e nomes.
-   Limite de cinco em `drivers` e cinco em `passengers`, garantido por
    função transacional com `pg_advisory_xact_lock`, para resistir a
    cadastros simultâneos.
-   Nenhuma exclusão física de `drivers`, `passengers` ou `vehicles` com
    dependências: usar `is_active`.

Toda alteração do banco deverá ser registrada em migração SQL
versionada. Não modificar migrações já aplicadas sem avaliar impacto.

## 10. Segurança

-   Usar Supabase Auth.
-   Habilitar RLS nas tabelas expostas.
-   Motorista acessa somente seus dados e corridas permitidas.
-   Motorista só atualiza sua própria localização.
-   Administração exige papel validado no backend.
-   Usuário não pode alterar seu próprio papel.
-   Não confiar apenas em role armazenada no cliente ou metadata
    editável.
-   Revisar policies e grants.
-   Não colocar `service_role`, senha administrativa ou chave privada no
    aplicativo.
-   Não registrar tokens, senhas ou dados sensíveis em logs.
-   Coletar apenas dados necessários.
-   Aplicar princípios de privacidade e LGPD.

Operações críticas devem passar por funções/RPC transacionais quando
isso reduzir exposição e garantir integridade.

### Visibilidade de solicitações

Um motorista precisa ver solicitações ainda sem dono para poder aceitá-las.
Isso não autoriza acesso aos demais dados do passageiro.

-   O acesso é feito por uma `view` de ofertas (`available_rides`) que
    expõe apenas: `id`, `pickup_label`, `destination_label`, coordenadas,
    `estimated_fare_cents`, `created_at`.
-   A `view` só retorna linhas com `status = 'requested'` e `driver_id` nulo.
-   Política de `SELECT` direto em `active_rides` para motorista cobre
    apenas linhas com `driver_id` igual ao seu.
-   Nenhuma escrita direta do motorista em `active_rides` é permitida. Toda
    transição passa por RPC.
-   O aceite é atômico em `accept_ride`, com `UPDATE ... WHERE id = ? AND
    driver_id IS NULL AND status = 'requested'` e verificação de linhas
    afetadas.

## 11. GPS e localização em segundo plano

Utilizar GPS real do Android.

Tecnologias a avaliar: - Expo Location. - Expo TaskManager. - Android
Foreground Service. - Notificação persistente. - Permissões de
localização.

Metas iniciais configuráveis: - Aproximadamente 5 segundos quando
online. - Aproximadamente 3 segundos durante corrida.

São metas de teste, não garantias. Medir precisão, bateria, dados e
estabilidade.

Verificar permissões conforme a versão Android, incluindo quando
aplicável: - `ACCESS_FINE_LOCATION` - `ACCESS_COARSE_LOCATION` -
`FOREGROUND_SERVICE` - `FOREGROUND_SERVICE_LOCATION` -
`ACCESS_BACKGROUND_LOCATION` - Permissão de notificações aplicável.

Respeitar solicitação progressiva de permissões e explicar sua
finalidade.

Expo Go não deve ser presumido suficiente. Utilizar Development Build
quando necessário.

O Android e fabricantes podem limitar serviços em segundo plano. Não
prometer rastreamento após force-stop nas configurações. Após
reinicialização, recuperar a corrida do servidor; retomada automática do
GPS deverá respeitar os mecanismos e limitações do Android e ser testada
em aparelho físico.

Não rastrear motorista offline. Não compartilhar localização sem
autorização. Informar quando a posição estiver desatualizada. Ao ficar
`offline`, apagar a linha de `driver_live_locations` do motorista.

## 12. Mapa e navegação

Utilizar MapLibre React Native e avaliar OpenFreeMap como fonte inicial
de tiles, verificando termos, limites, disponibilidade e adequação.

MapLibre é renderizador de mapas, não serviço automático de
geocodificação ou roteamento. Inicialmente, a administração define
embarque e destino tocando no mapa para capturar as coordenadas, além de
digitar o rótulo. Não é aceitável exigir que o administrador digite
latitude e longitude manualmente. Escolher provedor de
geocodificação/rota separadamente e somente após avaliação.

A atribuição exigida pela fonte de tiles deve ser exibida no mapa.

MapLibre React Native é módulo nativo e depende de Development Build. É o
maior risco técnico da stack. Antes de construir as telas definitivas,
executar uma prova isolada de mapa na FASE 2. Se não funcionar na versão
atual do Expo, a decisão sobre a camada de mapa deve ser revista antes de
avançar.

O mapa deverá mostrar: - Posição do motorista. - Embarque. - Destino.

Utilizar Waze Deep Links para abrir navegação. Tratar Waze não
instalado, link inválido e falha de abertura. Confirmações de chegada,
início e conclusão ocorrem no DRIVER APP. Não depender do Waze para
atualizar o estado interno nem presumir retorno de ETA/rota.

## 13. Funcionamento offline

Quando a conexão cair: - Manter corrida ativa visível. - Exibir estado
offline. - Preservar último estado confirmado. - Não declarar operações
remotas como concluídas. - Não apagar dados locais. - Não sobrescrever
estado oficial com cópia antiga.

Aceitar, iniciar, cancelar e concluir exigem validação do servidor. Sem
internet, informar que não foi possível confirmar a ação. Navegação
externa pode continuar se já estiver disponível, mas o estado oficial só
muda após validação.

Ao reconectar: 1. Validar autenticação. 2. Consultar corrida ativa no
servidor. 3. Comparar com cópia local. 4. Adotar estado oficial. 5.
Corrigir SQLite. 6. Restabelecer Realtime. 7. Retomar GPS, se permitido.

Para posições GPS pendentes, usar fila limitada e descartar leituras
antigas quando apropriado; não criar histórico de trajetos.

### Cópia local mínima

O SQLite guarda somente o necessário para reabrir o aplicativo e
reconciliar com o servidor:

-   Uma única corrida ativa: `id`, `status`, `version`, `driver_id`,
    `vehicle_id`, coordenadas e rótulos de embarque e destino,
    `estimated_fare_cents`, timestamps de servidor.
-   Uma fila limitada de posições pendentes, com descarte das mais antigas.
-   Nenhum nome ou telefone de passageiro.
-   Nenhum token em texto claro fora do armazenamento seguro do sistema.

A cópia local nunca é fonte de verdade. Ela é substituída integralmente
pelo estado do servidor na reconciliação. Se o servidor não tiver corrida
ativa, a cópia local é apagada, não ressuscitada.

## 14. Realtime

Supabase Realtime será usado para novas solicitações, alterações de
estado e atualizações autorizadas de localização.

Realtime é mecanismo de notificação, não fonte única da verdade.
Implementar reconexão, recuperação por consulta, prevenção de inscrições
duplicadas, encerramento de canais antigos e reconciliação após
reconexão.

## 15. Tratamento de erros

Tratar explicitamente: - Falha de login e sessão expirada. - Usuário
desativado ou sem permissão. - Falta de internet/backend/banco. - GPS
desligado ou permissão negada. - Localização imprecisa ou
desatualizada. - Mapa indisponível. - Waze não instalado. - Solicitação
duplicada ou já aceita. - Motorista/passageiro ocupado. - Veículo
desativado. - Corrida cancelada. - Conflito de estado. - Falha de
sincronização ou SQLite. - Erro de compilação ou dependência
incompatível.

Cada erro deverá ter identificação, mensagem clara, tratamento e
estratégia de recuperação. Não usar exceções vazias, esconder erros ou
informar sucesso sem confirmação.

## 16. Stack e compatibilidade

Stack planejada:

  -----------------------------------------------------------------------
  Área                                Tecnologia
  ----------------------------------- -----------------------------------
  Aplicativo                          React Native

  Framework                           Expo Development Build

  Linguagem                           TypeScript

  Backend                             Supabase

  Banco                               PostgreSQL

  Autenticação                        Supabase Auth

  Tempo real                          Supabase Realtime

  Segurança                           RLS

  Persistência local                  Expo SQLite

  Mapa                                MapLibre React Native

  Tiles                               OpenFreeMap, após validação

  GPS                                 Expo Location

  Tarefas em segundo plano            Expo TaskManager, conforme
                                      compatibilidade

  Navegação                           Waze Deep Links

  Versionamento                       Git
  -----------------------------------------------------------------------

Antes de instalar dependências, verificar Node.js, npm, JDK, Android
Studio, SDK, ADB e matriz de compatibilidade Expo/React Native/MapLibre.
Usar `npx expo install` quando aplicável e executar `npx expo-doctor`.
Não fixar versões cegamente nem atualizar dependências sem
justificativa.

Usar a versão LTS do Node.js homologada pelo Expo. Verificado em
2026-11-04: Node 26.13.0 é LTS (Lithium) e o Expo 58 declara suporte a
`^26.0.0`. A regra continua valendo para versões futuras: conferir
`npm view expo engines` e o calendário oficial antes de trocar o runtime.

`minSdkVersion` 24, `targetSdkVersion` 36 e `compileSdkVersion` 37, com
toolchain Java 17, conforme o React Native 0.88.1. Esses valores ficam
registrados em `docs/ENVIRONMENT.md` e mudam apenas com nova ADR.

## 17. Estrutura de pastas proposta

``` text
driver-app/
├── MASTER_SPEC.md
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── package.json
├── package-lock.json
├── app.json
├── eas.json
├── tsconfig.json
├── .gitignore
├── .env.example
├── PROMPTS/
│   ├── MASTER_PROMPT.md
│   ├── PHASE_0.md
│   └── PHASE_1.md
├── AI_LOG/
│   ├── SESSION_INDEX.md
│   └── AAAA-MM-DD/
│       ├── PROMPT.md
│       └── RESPONSE.md
├── src/
│   ├── app/
│   │   ├── navigation/
│   │   ├── providers/
│   │   └── bootstrap/
│   ├── screens/
│   │   ├── auth/
│   │   ├── driver/
│   │   └── admin/
│   ├── components/
│   ├── features/
│   │   ├── authentication/
│   │   ├── drivers/
│   │   ├── passengers/
│   │   ├── vehicles/
│   │   ├── rides/
│   │   ├── location/
│   │   ├── navigation/
│   │   └── administration/
│   ├── services/
│   │   ├── supabase/
│   │   ├── realtime/
│   │   ├── location/
│   │   ├── navigation/
│   │   └── connectivity/
│   ├── database/local/
│   ├── repositories/
│   ├── hooks/
│   ├── types/
│   ├── utils/
│   ├── constants/
│   └── theme/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DATABASE.md
│   ├── SECURITY.md
│   ├── GPS.md
│   ├── RIDES.md
│   ├── OFFLINE.md
│   ├── MAPS.md
│   ├── UI_DESIGN.md
│   ├── TESTING.md
│   ├── DECISIONS.md
│   ├── TASKS.md
│   ├── AI_HANDOFF.md
│   ├── ENVIRONMENT.md
│   ├── DEPLOYMENT.md
│   └── TROUBLESHOOTING.md
├── tests/
│   ├── unit/
│   ├── integration/
│   └── acceptance/
└── assets/
    ├── icons/
    ├── images/
    └── fonts/
```

A estrutura pode ser ajustada com justificativa. Não criar arquivos
vazios sem finalidade. Evitar duplicar responsabilidades ou concentrar
todo o aplicativo em um arquivo.

## 18. Git e rastreabilidade

Inicializar Git desde o início. Fazer commits pequenos e identificáveis.
Criar `.gitignore` e `.env.example`. Não versionar `.env`, tokens,
chaves privadas, credenciais ou dados pessoais reais.

Antes de mudanças relevantes, verificar o estado do Git. Não executar
comandos destrutivos sem autorização.

### Repositório remoto

Um repositório apenas local não cumpre o requisito de continuidade entre
computadores. O projeto deve ter um repositório remoto privado (GitHub
privado) e o histórico deve ser enviado a ele ao final de cada etapa
aprovada.

O repositório remoto não substitui backup: `git push` protege o código e a
documentação, não o banco Supabase.

## 19. Design

Criar identidade visual própria. Princípios: - Minimalismo e clareza. -
Mapa como elemento central. - Botões grandes e legíveis. - Hierarquia
visual consistente. - Bom contraste. - Animações leves. - Poucos
elementos desnecessários. - Interface validada em Android físico.

Não copiar ativos protegidos da Uber nem modificar seu site.

## 20. Desempenho, custos e privacidade

Monitorar bateria, GPS, dados, memória, inicialização, recuperação da
corrida, consultas e canais Realtime. Evitar serviços GPS duplicados,
inscrições Realtime duplicadas e consultas excessivas.

Priorizar opções gratuitas para desenvolvimento, mas não presumir
gratuidade permanente. Supabase Free pode ter limites ou pausas; tiles
públicos não garantem SLA. Verificar termos e limites. Não contratar
serviços pagos sem autorização e comparação com alternativas.

Não armazenar histórico de trajetos. Logs técnicos devem ser mínimos,
sem segredos e com retenção limitada. Supabase Free não deve ser tratado
como backup garantido. Documentar backup de esquema/migrações e
recuperação dos cadastros.

## 21. Fora do escopo da versão 1

Não implementar sem autorização: - Aplicativo separado para
passageiro. - Pagamentos, PIX, cartões ou carteira. - Histórico de
viagens. - Avaliações. - Chat. - Cupons ou fidelidade. - Tarifação
dinâmica. - Corridas agendadas. - Relatórios financeiros. - Cadastro
público de motoristas. - Integrações desnecessárias. - Publicação
comercial nas lojas.

## 22. Testes obrigatórios

### Funcionais

-   Login, logout e sessão.
-   Cadastros e limites.
-   Associação de veículos.
-   Criação de solicitação.
-   Aceitação, recusa, chegada, início, conclusão e cancelamento.
-   Recuperação de estado.
-   Motorista que fecha o aplicativo à força e o servidor o marca
    `offline` sem cancelar a corrida.

### Concorrência

-   Dois motoristas tentando aceitar a mesma solicitação.
-   Um motorista tentando aceitar duas corridas.
-   Um passageiro tentando receber duas corridas.
-   Operações repetidas.
-   Conflitos de versão.

### Segurança

-   Motorista acessando dados de outro.
-   Tentativa de elevar o próprio papel.
-   Usuário não autenticado acessando recursos.
-   Ultrapassagem dos limites.
-   Acesso administrativo indevido.

### Recuperação

-   Fechar e reabrir com corrida ativa.
-   Reiniciar telefone.
-   Perder e recuperar internet.
-   Perder resposta após operação executada no servidor.
-   Negar permissão GPS.
-   Desligar GPS.
-   Interromper serviço.
-   Waze ausente.

### GPS

Testar em aparelho Android físico, incluindo tela bloqueada, segundo
plano, economia de bateria, permissões e limitações do fabricante.
Simulação ou compilação bem-sucedida não substitui teste físico.

Não declarar funcionalidade concluída apenas porque o código existe.

## 23. Fases oficiais

**FASE 0 --- Auditoria do ambiente** - Verificar Windows, diretório,
Node.js, npm/`npm.cmd`, Git, JDK, Android Studio, SDK, ADB e celular. -
Verificar compatibilidade. - Não instalar nada. - Entregar relatório e
aguardar aprovação.

**FASE 1 --- Criação e organização** - Criar pasta isolada, Git,
documentos, estrutura e projeto Expo TypeScript. - Não implementar
backend completo nem GPS em segundo plano.

**FASE 1A --- Fundação documental** - Repositório Git, remote privado,
`AGENTS.md`, `README.md`, `MASTER_SPEC.md` revisado, `docs/DECISIONS.md`,
`docs/ENVIRONMENT.md`, `docs/AUDIT_FASE_0.md`, `docs/TASKS.md`,
`docs/AI_HANDOFF.md`, `PROMPTS/` e `AI_LOG/`. - Não cria código de
aplicativo. - Aprovada antes da FASE 1B.

**FASE 1B --- Projeto Expo** - Criar o projeto Expo TypeScript, fixar
versões suportadas, rodar `expo-doctor` e registrar a matriz de
compatibilidade. - Não constrói telas.

**FASE 2 --- Interface** - Autenticação visual, tela motorista,
navegação, mapa inicial e entrada administrativa oculta.

**FASE 3 --- Backend e segurança** - Supabase Auth, migrações, tabelas,
RLS, papéis, cadastros e limites.

**FASE 4 --- Administração** - Cadastros e criação de solicitações.

**FASE 5 --- Corridas** - Máquina de estados, aceitação atômica,
concorrência, Realtime, conclusão e cancelamento.

**FASE 6 --- Persistência/offline** - SQLite, recuperação e
sincronização.

**FASE 7 --- GPS/mapa** - Permissões, foreground/background, serviço
Android, notificação, MapLibre e testes.

**FASE 8 --- Navegação** - Waze Deep Links e tratamento de falhas.

**FASE 9 --- Testes** - Testes funcionais, segurança, concorrência,
recuperação e aparelho físico.

**FASE 10 --- Consolidação** - Revisão, documentação, segurança, versão
de teste e limitações.

Cada fase exige relatório e aprovação antes de mudanças significativas
na fase seguinte.

## 24. Protocolo de trabalho da IA

Antes de cada tarefa, informar: 1. Objetivo. 2. Contexto. 3. Arquivos
que serão criados. 4. Arquivos que serão modificados. 5. Dependências.
6. Riscos. 7. Resultado esperado. 8. Como será testado.

Executar somente o escopo autorizado. Não reescrever módulos sem
necessidade, não alterar arquitetura silenciosamente e não executar
comandos destrutivos sem autorização.

Se encontrar erro: 1. Parar. 2. Identificar a causa. 3. Explicar em
linguagem simples. 4. Avaliar efeitos colaterais. 5. Propor correção. 6.
Pedir autorização quando houver risco relevante.

## 25. Relatório obrigatório ao final de cada etapa

Apresentar: - O que foi realizado. - Arquivos criados. - Arquivos
modificados. - Dependências instaladas/alteradas. - Testes executados e
resultados reais. - Problemas encontrados e soluções. - Pendências. -
Riscos conhecidos. - Documentação atualizada. - Próxima etapa sugerida.

O responsável pelo projeto está aprendendo programação. Explicar termos
técnicos de maneira simples e não presumir conhecimento avançado.

## 26. Primeira tarefa autorizada --- FASE 0

Ao receber este documento, NÃO desenvolva o aplicativo completo.

Execute exclusivamente uma auditoria de leitura do ambiente.

Verifique: 1. Diretório atual e isolamento do projeto. 2. Node.js e
caminho do executável. 3. npm e `npm.cmd`. 4. Git. 5. JDK. 6. Android
Studio. 7. Android SDK. 8. ADB. 9. Celular Android conectado. 10.
Depuração USB. 11. Versões e compatibilidade da stack.

Não instale nada. Não modifique arquivos. Não altere configurações
globais. Não modifique outros projetos. Não crie arquivos fora do
diretório autorizado.

Entregue um relatório com cada item classificado como: - APROVADO. -
ATENÇÃO. - BLOQUEADO. - NÃO VERIFICADO.

Informe o que está pronto, o que falta, os riscos e os próximos passos.

**Depois do relatório, PARE e aguarde autorização expressa para iniciar
a FASE 1.**

------------------------------------------------------------------------

## Princípios inegociáveis

1.  Integridade dos dados.
2.  Segurança.
3.  Persistência das corridas.
4.  Estabilidade.
5.  Compatibilidade Android.
6.  GPS confiável dentro das limitações do sistema.
7.  Código organizado.
8.  Rastreabilidade.
9.  Continuidade entre diferentes IAs.
10. Boa experiência de uso.

Não sacrificar qualidade por velocidade. Não implementar funcionalidades
não aprovadas. Não modificar projetos externos. Não apagar corrida ativa
antes da confirmação do servidor. Não permitir alterações silenciosas
das decisões deste documento.
