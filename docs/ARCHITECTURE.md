# Arquitetura

Documento de apoio. As regras canônicas estão em `MASTER_SPEC.md`.

## Visão em camadas

```text
┌──────────────────────────────────────────────────────────┐
│ APLICATIVO ANDROID (um único app)                        │
│                                                          │
│  Tela do motorista          Administração oculta         │
│  (padrão)                   7 toques + login             │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │ UI (React Native + TypeScript)                     │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ Estado / hooks                                     │  │
│  ├────────────────────────────────────────────────────┤  │
│  │ Repositórios                                       │  │
│  ├──────────────────┬──────────────────┬──────────────┤  │
│  │ Supabase client  │ SQLite local     │ Serviços     │  │
│  │ (RPC, Realtime)  │ (cópia mínima)   │ GPS, Waze,   │  │
│  │                  │                  │ conectividade│  │
│  └──────────────────┴──────────────────┴──────────────┘  │
└──────────────────────────────────────────────────────────┘
                           │ HTTPS / WSS
┌──────────────────────────▼───────────────────────────────┐
│ SUPABASE                                                 │
│  Auth          JWT, contas criadas só pela administração  │
│  Postgres      fonte oficial da verdade                  │
│  RLS           barreira de autorização                   │
│  RPC           toda transição de corrida                 │
│  Realtime      aviso de mudança, nunca verdade           │
│  Edge Function criação de contas de motorista            │
└──────────────────────────────────────────────────────────┘
```

## Princípio central

O servidor é a fonte oficial. O aplicativo mantém uma **cópia mínima** para
sobreviver a fechamento, perda de rede e reinício. A cópia nunca vence o
servidor.

```text
ação do motorista
   → chamada RPC
      → servidor valida e transiciona
         → resposta confirmada
            → só então atualiza SQLite e UI
```

Se a resposta não chegar, o app **não** repete cegamente e **não** apaga o
cache: consulta o servidor e reconcilia.

## Fluxo de uma corrida

```text
ADMIN                          SERVIDOR                  MOTORISTA
  │                               │                          │
  ├─ cria solicitação ───────────▶│ active_rides             │
  │                               │ status=requested         │
  │                               │ driver_id=NULL           │
  │                               ├─ Realtime ──────────────▶│ vê oferta
  │                               │                          │ (view restrita)
  │                               │◀── accept_ride ──────────┤
  │                               │ valida, preenche         │
  │                               │ driver_id/vehicle_id     │
  │                               │ status=accepted          │
  │                               │                          │
  │                               │◀── arrive / start ───────┤
  │                               │                          │
  │                               │◀── complete ─────────────┤
  │                               │ transação: recibo +      │
  │                               │ DELETE da linha ativa    │
  │                               │                          │
  │                               ├── confirmação ──────────▶│ limpa SQLite
```

## Pontos de atenção permanentes

| Risco | Mitigação |
|---|---|
| Corrida presa por app morto | Heartbeat 30 s + rotina de 120 s (ADR-011) |
| Dois aceites simultâneos | `UPDATE ... WHERE driver_id IS NULL` + índice único |
| Resposta perdida na conclusão | `idempotency_key` + recibo de 30 dias |
| Estado local obsoleto | Reconciliação sempre a partir do servidor |
| Vazamento de dados | View restrita; sem nome/telefone no aparelho |
| Módulo nativo MapLibre | Prova isolada antes das telas (ADR pendente P-01) |
| GPS limitado pelo Android | Teste em aparelho físico; nunca prometer mais que o sistema |

## O que não existe de propósito

-   Aplicativo de passageiro.
-   Histórico de corridas, trajetos ou localização.
-   Pagamentos.
-   Chat, avaliações, cupons.
-   Cadastro público.

Ver `MASTER_SPEC.md` §21.
