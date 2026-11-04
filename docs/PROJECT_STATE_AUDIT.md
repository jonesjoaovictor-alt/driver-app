# PROJECT_STATE_AUDIT — Relatório de Auditoria Técnica do DRIVER APP

**Data da auditoria:** 2026-11-04  
**Diretório do projeto:** `C:\A`  
**Plataforma:** Android exclusivamente (ADR-020)  
**Modo:** Auditoria somente leitura — nenhuma alteração foi realizada.

---

## 1. IDENTIFICAÇÃO DO PROJETO

| Item | Valor |
|------|-------|
| Nome | DRIVER APP |
| Repositório remoto | `https://github.com/jonesjoaovictor-alt/driver-app.git` |
| Branch | `main` |
| Último commit | `2c89cc8` |
| Push remoto | Concluído |
| Plataforma alvo | Android exclusivamente |
| Versão do app | 0.1.0 |
| Pacote Android | `com.jonesjoaovictor.driverapp` |
| Scheme | `driverapp` |

---

## 2. ESTADO ATUAL DO AMBIENTE

### Ferramentas instaladas e validadas

| Ferramenta | Versão | Caminho | Status |
|------------|--------|---------|--------|
| Node.js | 26.13.0 (LTS) | `C:\Users\joao.castro.IND\DevTools\NodeJS\node-v26.13.0-win-x64` | Instalado |
| npm | 11.20.0 (`npm.cmd`) | — | Instalado |
| Git | 2.55.0.windows.3 | — | Instalado |
| JDK | 17.0.21+9 (Eclipse Temurin) | `C:\Program Files\Eclipse Adoptium\jdk-17.0.21.9-hotspot` | Instalado, JAVA_HOME configurado |
| Android SDK | — | `C:\Users\joao.castro.IND\DevTools\Android\Sdk` | Instalado |
| Android Command-line Tools | sdkmanager 22.0 | — | Instalado |
| Android Platform Tools | adb 37.0.1 | — | Instalado |
| Android NDK | 27.1.12297006 | — | Instalado |
| Expo CLI | Via `npx` | — | Não global |

### Versões da stack do projeto

| Componente | Versão |
|------------|--------|
| Expo SDK | ~58.0.23 |
| React Native | 0.88.1 |
| React | 19.3.0 |
| TypeScript | ~6.0.3 |
| `@types/react` | ~19.3.0 |
| minSdk / targetSdk / compileSdk | 24 / 36 / 37 |
| Java toolchain | 17 |

### Validações anteriores confirmadas

- `npm.cmd run typecheck`: concluído sem erros.
- `npx.cmd expo-doctor`: 20/20 verificações aprovadas.
- `git status`: limpo (sem alterações pendentes).
- `git push origin main`: concluído (commit `2c89cc8` no remoto).

---

## 3. ESTADO DA COMPILAÇÃO ANDROID

Conforme informado pelo usuário:

- O APK debug foi gerado com sucesso: `BUILD SUCCESSFUL in 2m 11s`.
- Caminho do APK: `C:\A\android\app\build\outputs\apk\debug\app-debug.apk`.
- Arquiteturas configuradas: `reactNativeArchitectures=arm64-v8a,x86_64` (para contornar problema de caminhos longos no CMake/Ninja).
- O APK foi instalado no emulador `DRIVER_ANDROID_36`.
- O autolinking Android foi validado.
- O `expo prebuild` foi executado.

**Nota:** A pasta `android/` está no `.gitignore` e não é versionada. O estado de build acima é informação fornecida pelo usuário; não há arquivos de build no repositório Git.

---

## 4. ESTADO DA INSTALAÇÃO E EXECUÇÃO

### Dependências instaladas

O `package.json` contém:

**Dependencies:**
- `@supabase/supabase-js` ^2.118.0
- `@maplibre/maplibre-react-native` ^11.5.1
- `@react-navigation/native` ^7.5.1
- `@react-navigation/stack` ^7.12.1
- `expo` ~58.0.23
- `expo-location` ^58.0.20
- `expo-notifications` ^58.1.8
- `expo-sqlite` ^58.0.15
- `expo-status-bar` ~58.0.4
- `expo-task-manager` ^58.0.13
- `react` 19.3.0
- `react-native` 0.88.1
- `react-native-gesture-handler` (via `expo install`)
- `react-native-safe-area-context` ^5.11.1
- `react-native-screens` ^4.30.1

**DevDependencies:**
- `@types/react` ~19.3.0
- `typescript` ~6.0.3

### Execução do aplicativo

- Metro iniciado com: `npx.cmd expo start --dev-client --localhost`
- Resultado confirmado: `Android Bundled 10347ms index.ts (1182 modules)`
- ADB reverse configurado: `adb reverse tcp:8081 tcp:8081`
- O aplicativo alcançou a etapa de execução do JavaScript.

### Erro encontrado na execução

```
EXPO_PUBLIC_SUPABASE_URL e EXPO_PUBLIC_SUPABASE_ANON_KEY são obrigatórias.
```

Este erro ocorre porque o arquivo `.env` não existe e as variáveis de ambiente do Supabase não estão definidas.

---

## 5. DIAGNÓSTICO DO ERRO SUPABASE

### Causa identificada

O cliente Supabase em `src/services/supabase/client.ts` lança uma exceção se as variáveis `EXPO_PUBLIC_SUPABASE_URL` e `EXPO_PUBLIC_SUPABASE_ANON_KEY` não estiverem definidas:

```typescript
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'EXPO_PUBLIC_SUPABASE_URL e EXPO_PUBLIC_SUPABASE_ANON_KEY são obrigatórios. ' +
    'Copie .env.example para .env e preencha com os valores do projeto Supabase.'
  );
}
```

### Arquivos envolvidos

| Arquivo | Função |
|---------|--------|
| `src/services/supabase/client.ts` | Inicializa o cliente Supabase; valida as variáveis de ambiente. |
| `.env.example` | Contém os nomes das variáveis (exemplo, sem valores reais). |
| `.env` | **Não existe** — precisa ser criado com valores reais do projeto Supabase. |

### Informações que faltam

- URL do projeto Supabase (`EXPO_PUBLIC_SUPABASE_URL`).
- Chave anon pública do Supabase (`EXPO_PUBLIC_SUPABASE_ANON_KEY`).
- O projeto Supabase ainda não foi criado (nenhuma migração aplicada).
- Não existe projeto Supabase vinculado ao app neste momento.

### Caminho recomendado para resolver

1. Criar um projeto no Supabase (painel web).
2. Obter a URL do projeto e a chave anon pública.
3. Copiar `.env.example` para `.env` e preencher com os valores reais.
4. **Nunca commitar o `.env`** (já está no `.gitignore`).
5. Apenas então o aplicativo conseguirá inicializar o cliente Supabase e prosseguir além da tela de erro.

---

## 6. AUDITORIA DO APLICATIVO

### Estrutura de diretórios (código-fonte)

```
src/
├── app/
│   ├── navigation/
│   │   ├── RootNavigator.tsx
│   │   └── types.ts
│   └── providers/
│       └── AuthProvider.tsx
├── components/        (não existe — vazio)
├── database/
│   └── local/
│       └── sqlite.ts
├── hooks/
│   ├── useLocation.ts
│   └── useRides.ts
├── screens/
│   ├── auth/
│   │   └── LoginScreen.tsx
│   └── driver/
│       └── DriverScreen.tsx
├── services/
│   ├── supabase/
│   │   └── client.ts
│   ├── location.ts
│   ├── notifications.ts
│   ├── realtime.ts
│   └── rides.ts
├── types/
│   └── database.ts
└── constants/
    └── app.ts
```

### Banco de dados (Supabase — migrações escritas, não aplicadas)

| Arquivo | Conteúdo | Aplicado |
|---------|----------|----------|
| `supabase/migrations/0001_profiles.sql` | Enums, profiles, funções de contexto, proteção de papel | Não |
| `supabase/migrations/0002_catalogs.sql` | drivers, vehicles, passengers, limites de 5, contexto de driver | Não |
| `supabase/migrations/0003_active_rides.sql` | corridas ativas, índices únicos, checks de estado, triggers | Não |
| `supabase/migrations/0004_ride_operations.sql` | recibos de idempotência, limpeza de 30 dias | Não |
| `supabase/migrations/0005_driver_locations.sql` | localização ao vivo, função is_location_fresh | Não |
| `supabase/migrations/0006_rls.sql` | RLS, grants, policies por papel | Não |
| `supabase/migrations/0007_rpc.sql` | RPCs de transição (accept, cancel, complete, etc.) — **CORRIGIDO** | Não |
| `supabase/migrations/0008_seed.sql` | dados fictícios (5 passageiros, estrutura 5 motoristas/veículos) | Não |
| `supabase/functions/admin-create-driver/index.ts` | Edge Function para criação de contas de motorista | Não implantada |

**Status do banco:** Nenhuma migração foi aplicada. Não existe projeto Supabase vinculado. O banco está **escrito, mas não criado**.

### Funcionalidades concluídas (código implementado e verificado)

| Funcionalidade | Status | Comentário |
|----------------|--------|------------|
| Projeto Expo SDK 58 TypeScript | ✅ | Compila, `tsc` limpo, `expo-doctor` 20/20 |
| Cliente Supabase (chave anon) | ✅ | Código escrito, aguarda variáveis de ambiente |
| Autenticação (sessão, perfil, motorista) | ✅ | AuthProvider implementado, aguarda Supabase |
| Navegação Login ↔ Driver | ✅ | RootNavigator implementado |
| Tela de login | ✅ | LoginScreen implementada |
| Tela base do motorista | ✅ | DriverScreen com mapa placeholder |
| Chamadas RPC de corrida | ✅ | rides.ts implementado (accept, complete, cancel, etc.) |
| GPS/Location | ✅ | location.ts implementado (permissões, rastreamento) |
| Cache SQLite local | ✅ | sqlite.ts implementado (corrida ativa + fila de posições) |
| Notificação persistente | ✅ | notifications.ts implementado |
| Realtime Supabase | ✅ | realtime.ts implementado (inscrição em canais) |
| Hooks de corrida e GPS | ✅ | useRides.ts e useLocation.ts implementados |
| Tipos do banco de dados | ✅ | database.ts com tipos espelhando as migrações |
| Plugin MapLibre em app.json | ✅ | Configurado com `app.plugin.js` e permissões |
| Edge Function admin-create-driver | ✅ | Código escrito, não implantado |
| Migrações SQL corrigidas | ✅ | 0007_rpc.sql corrigido (sintaxe, tipos, identidade, idempotência) |

### Funcionalidades parciais (estrutura existe, mas depende de backend)

| Funcionalidade | Status | O que falta |
|----------------|--------|-------------|
| Autenticação Supabase | Parcial | Código pronto, mas `.env` sem credenciais; projeto Supabase não criado |
| Mapa MapLibre | Parcial | Dependência instalada, plugin configurado, mas **prova em aparelho físico não executada** (FASE 2A pendente) |
| GPS em segundo plano | Parcial | Código escrito, mas não testado em aparelho físico |
| Notificações persistentes | Parcial | Código escrito, mas não testado em aparelho físico |
| Banco de dados Supabase | Parcial | Migrações escritas, mas nenhuma aplicada |
| Edge Function admin-create-driver | Parcial | Código escrito, não implantada no Supabase |

### Funcionalidades pendentes (não iniciadas)

| Funcionalidade | Fase |
|----------------|------|
| Tela do motorista com mapa real | FASE 2B (após prova do MapLibre) |
| Entrada administrativa por sete toques | FASE 2 |
| Estados de erro visuais | FASE 2 |
| Cadastros de motoristas, veículos, passageiros | FASE 4 |
| Criação de solicitações de corrida | FASE 4 |
| Máquina de estados de corrida | FASE 5 |
| Aceitação atômica com idempotência | FASE 5 |
| Realtime para novas solicitações | FASE 5 |
| Conclusão e cancelamento transacionais | FASE 5 |
| Recuperação de estado após fechamento/reinício | FASE 6 |
| Heartbeat (last_seen_at a cada 30s) | FASE 7 |
| Waze Deep Links | FASE 8 |
| Testes funcionais e de segurança | FASE 9 |

---

## 7. PROBLEMAS CONFIRMADOS

| # | Problema | Severidade | Arquivo/Componente | Consequência |
|---|----------|------------|-------------------|--------------|
| 1 | `.env` não existe; variáveis do Supabase não definidas | CRÍTICO | `src/services/supabase/client.ts` | Aplicação não inicializa o cliente Supabase; erro na execução |
| 2 | Projeto Supabase não criado | CRÍTICO | — | Nenhuma tabela, RLS, RPC ou Edge Function está disponível no servidor |
| 3 | Migrações SQL não aplicadas | CRÍTICO | `supabase/migrations/` | Banco de dados não existe no Supabase |
| 4 | Prova do MapLibre não executada | ALTO | `docs/BUILD_MACHINE.md`, `docs/MAPS.md` | Não se sabe se o MapLibre funciona no Development Build atual |
| 5 | Edge Function admin-create-driver não implantada | ALTO | `supabase/functions/` | Não é possível criar contas de motorista via fluxo oficial |
| 6 | Cadastro público do Supabase não desativado | ALTO | — | Requer ação manual no painel do Supabase |
| 7 | Nenhuma tela administrativa (sete toques) | MÉDIO | — | Não há forma de acessar o modo admin no app |

---

## 8. PENDÊNCIAS

| Item | Prioridade | Fase |
|------|-----------|------|
| Criar `.env` com credenciais do Supabase | Crítica | Antes de qualquer execução conectada |
| Criar projeto Supabase e aplicar migrações 0001-0008 | Crítica | FASE 3 |
| Desativar cadastro público no Supabase Auth | Crítica | FASE 3 |
| Implantar Edge Function admin-create-driver | Alta | FASE 3 |
| Executar prova do MapLibre em aparelho físico | Alta | FASE 2A |
| Executar matriz de testes de segurança | Alta | FASE 3 |
| Criar tela administrativa (sete toques) | Média | FASE 2 |
| Implementar tela do motorista com mapa real | Média | FASE 2B |

---

## 9. PRÓXIMAS ETAPAS RECOMENDADAS

### Sequência técnica priorizada

1. **Resolver o erro Supabase (bloqueador imediato):**
   - Criar projeto no Supabase.
   - Obter `EXPO_PUBLIC_SUPABASE_URL` e `EXPO_PUBLIC_SUPABASE_ANON_KEY`.
   - Criar `.env` a partir de `.env.example` com os valores reais.
   - Verificar se o aplicativo inicializa sem o erro de variáveis ausentes.

2. **Preparar o backend (FASE 3):**
   - Aplicar migrações 0001 a 0008 na ordem no projeto Supabase.
   - Desativar cadastro público no Supabase Auth.
   - Provisionar o primeiro administrador manualmente no painel.
   - Implantar a Edge Function `admin-create-driver`.
   - Executar a matriz de testes de segurança (`docs/SECURITY.md` §10).

3. **Validar o mapa (FASE 2A — pré-requisito para telas):**
   - Na máquina de build, executar `npx.cmd expo prebuild --platform android`.
   - Executar `npx.cmd expo run:android --device` com aparelho físico.
   - Preencher `docs/MAPS.md` com o resultado real.
   - Se aprovado, prosseguir para telas de produto.

4. **Desenvolver telas de produto (FASE 2B em diante):**
   - Tela do motorista com mapa real (substituir o placeholder).
   - Entrada administrativa por sete toques.
   - Estados de erro visuais.

---

## 10. ARQUIVOS IMPORTANTES PARA CONTINUIDADE

| Arquivo | Caminho | Propósito |
|---------|---------|-----------|
| Especificação oficial | `MASTER_SPEC.md` | Regras canônicas do produto |
| Contrato de trabalho | `AGENTS.md` | Regras para IAs e desenvolvedores |
| Handoff de sessão | `docs/AI_HANDOFF.md` | Estado do projeto e próximo passo |
| Tarefas | `docs/TASKS.md` | Backlog por fase |
| Decisões | `docs/DECISIONS.md` | ADRs, incluindo ADR-020 (Android exclusivamente) |
| Segurança | `docs/SECURITY.md` | Matriz de acesso e testes de segurança |
| Banco de dados | `docs/DATABASE.md` | Modelo de dados e status das migrações |
| Máquina de build | `docs/BUILD_MACHINE.md` | Guia de instalação e prova do MapLibre |
| Handoff da máquina | `BUILD_MACHINE_HANDOFF.md` | Estado real da máquina de build (fora do repo) |
| Variáveis de ambiente | `.env.example` | Exemplo de variáveis (criar `.env` a partir disto) |
| Cliente Supabase | `src/services/supabase/client.ts` | Inicialização e validação de credenciais |
| Migrações SQL | `supabase/migrations/0001_*.sql` a `0008_*.sql` | Schema do banco (não aplicadas) |
| Edge Function | `supabase/functions/admin-create-driver/index.ts` | Criação de contas de motorista |

---

## 11. ESTADO DO GIT

| Item | Valor |
|------|-------|
| Branch | `main` |
| Último commit local | `2c89cc8` |
| Último commit remoto | `2c89cc8` (sincronizado) |
| Status do working tree | Limpo (sem alterações pendentes) |
| Arquivos modificados | Nenhum |
| Arquivos não rastreados | Nenhum |
| Diferenças em relação ao último commit | Nenhuma |

---

## 12. HISTÓRICO RESUMIDO DAS DECISÕES TÉCNICAS

| ADR | Decisão | Status |
|-----|---------|--------|
| ADR-001 | Estrutura única de documentação | Aceita |
| ADR-002 | Pasta oficial `driver-app` | Aceita |
| ADR-003 | `driver_id` e `vehicle_id` nulos em `requested` | Aceita |
| ADR-004 | `is_active` e `availability` são coisas diferentes | Aceita |
| ADR-005 | Contas de motorista via Edge Function | Aceita |
| ADR-006 | Cadastro público desativado, papel único | Aceita |
| ADR-007 | Recusa não persistida | Aceita |
| ADR-008 | Matriz de cancelamento | Aceita |
| ADR-009 | Recibos de idempotência em `ride_operations` | Aceita |
| ADR-010 | Ofertas por RPC (substituída por ADR-019) | Substituída |
| ADR-011 | Heartbeat e liberação de estado obsoleto | Aceita |
| ADR-012 | Localização apagada ao ficar offline | Aceita |
| ADR-013 | Cópia local mínima, sem dados pessoais | Aceita |
| ADR-014 | Admin escolhe ponto tocando no mapa | Aceita |
| ADR-015 | Repositório remoto privado obrigatório | Aceita |
| ADR-016 | Node LTS (26.13.0) | Aceita (corrigida) |
| ADR-017 | Expo SDK 58 | Aceita |
| ADR-018 | `src/` cresce por demanda | Aceita |
| ADR-019 | Ofertas por função RPC, não view | Aceita |
| **ADR-020** | **Escopo Android exclusivamente** | **Aceita** |

---

## 13. CONFIRMAÇÃO

- **Nenhuma alteração funcional foi realizada.** Este relatório é somente leitura.
- **Nenhum arquivo do repositório foi modificado.**
- **Nenhuma dependência foi instalada ou removida.**
- **Nenhum build foi gerado.**
- **Nenhuma migration foi aplicada.**
- **Nenhum commit ou push foi executado.**
- **Nenhuma credencial foi criada ou exposta.**
- O relatório foi salvo em: `C:\A\docs\PROJECT_STATE_AUDIT.md`

---

**Próximo passo imediato:** Resolver o erro de variáveis do Supabase (criar `.env` com credenciais reais) antes de qualquer nova execução ou desenvolvimento.
