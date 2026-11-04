# Retomar amanhã — outra máquina

Página única de retomada. Se você só puder ler um arquivo antes de começar,
leia este.

**Gerado em:** 2026-11-04
**Último commit:** `72ecb24`
**Fase atual:** 1B concluída · próxima: **2A — prova do MapLibre**

---

## 1. Em 30 segundos

1. Clonar o repositório.
2. Rodar três comandos de verificação.
3. Colar o resultado aqui.
4. Se estiver tudo certo, instalar o ferramental Android.
5. Provar o mapa **antes** de qualquer tela.

## 2. Primeira coisa a rodar

```powershell
git clone https://github.com/jonesjoaovictor-alt/driver-app.git
cd driver-app
npm.cmd install
```

Depois:

```powershell
npm.cmd run typecheck
npx.cmd expo-doctor
java -version
adb devices
```

**Esperado:** TypeScript sem erro · `20/20 checks` · Java 17 · o celular
aparecendo como `device`.

## 3. O que me enviar para eu continuar

Cole a saída dos cinco comandos acima. Se algum falhar, mande a mensagem de
erro completa — é diagnóstico, não é teste de você.

## 4. O que já está decidido (não precisa decidir de novo)

| Assunto | Decisão |
|---|---|
| Pasta do projeto | `driver-app` |
| Repositório | GitHub privado `jonesjoaovictor-alt/driver-app` |
| Stack | Expo SDK 58.0.23 · RN 0.88.1 · React 19.3.0 · TypeScript 6.0.3 |
| Node | 26.13.0 LTS — é suportado, não trocar |
| Pacote Android | `com.jonesjoaovictor.driverapp` |
| Scheme | `driverapp` |
| `minSdk` / `targetSdk` / `compileSdk` | 24 / 36 / 37 |
| JDK na máquina de build | 17 (toolchain do RN 0.88) |
| Mapa | MapLibre 11.5.1 + OpenFreeMap — **sujeito à prova** |
| Ordem | Prova do mapa antes de qualquer tela |
| Escopo proibido | Backend, GPS, login, pagamentos, histórico |

Lista completa: `docs/DECISIONS.md`.

## 5. O que ainda não foi feito (e por quê)

| Item | Bloqueio real |
|---|---|
| Prova do MapLibre | precisa de Development Build em aparelho físico |
| Telas do produto | dependem da prova do mapa |
| Supabase, tabelas, RLS | fase 3, ainda não autorizada |
| GPS e permissões | fase 7 |
| Waze | fase 8 |

Nada disso é esquecimento. É sequência.

## 6. Armadilhas que já custaram tempo

| Armadilha | Solução |
|---|---|
| `npm` e `npx` no PowerShell falham | usar `npm.cmd` e `npx.cmd` |
| `create-expo-app` puxa SDK 57 por padrão | `--template blank-typescript@latest` |
| `newArchEnabled` quebra o schema | não usar no SDK 58 |
| Arquivo corrompido com mesmo tamanho passa no `git status` | rodar `git diff` após interrupção estranha |
| Pasta `Documents\driveapp` ainda travada | é a antiga, vazia; ignorar |

## 7. Comandos por fase, para não improvisar

```powershell
# verificar o repositório
git status
git log --oneline -5

# verificar o projeto
npm.cmd run typecheck
npx.cmd expo-doctor

# prova do mapa (somente após JDK 17 + SDK + celular)
npx.cmd expo install "@maplibre/maplibre-react-native"
npx.cmd expo prebuild --platform android
npx.cmd expo run:android --device
```

Detalhes e critério de aceite: `docs/BUILD_MACHINE.md`.

## 8. Regra de ouro

Se este documento e o `MASTER_SPEC.md` discordarem, **o `MASTER_SPEC.md`
vence** — e este arquivo precisa ser corrigido.

Se o código e o `MASTER_SPEC.md` discordarem, **pare** e aponte. Não
conserte em silêncio.
