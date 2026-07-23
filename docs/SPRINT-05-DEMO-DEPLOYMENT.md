# Sprint 05 — Phase 3: Runnable Telegram Demo (deployment runbook)

> **Honest status:** this runbook was authored in an environment with **no network
> egress, no hosting, and no access to secrets**, so the deployment and the live
> Telegram→LLM→History flow were **not executed here**. Nothing below is a claim
> that it ran. Follow the numbered steps to stand it up; the final smoke test
> (§6) is the only thing that earns a PASS, and it must be run by an operator with
> the real bot token and LLM key.

Baseline: commit `fe2b391` (P0 complete, CI green — api + mobile incl. `flutter build web`).

---

## 1. Environment variable checklist

### API (`apps/api/.env`) — see `.env.example`
| Variable | Required in prod | Notes |
|---|---|---|
| `NODE_ENV` | yes | set to `production` |
| `APP_HOST` / `APP_PORT` | no (defaults) | `0.0.0.0` / `3000` |
| `API_PREFIX` / `API_VERSION` | no (defaults) | routes served under `/api/v1` |
| `DATABASE_URL` | **yes** | Postgres connection string |
| `REDIS_HOST` / `REDIS_PORT` | **yes** | Redis reachable from the API |
| `CORS_ALLOWED_ORIGINS` | **yes*** | HTTPS origin(s) of the web build; required when Swagger is on |
| `JWT_ISSUER` / `JWT_AUDIENCE` | no (defaults) | `fortune-app` / `fortune-clients` |
| `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` | **yes** | ed25519 or RSA **PEM** (see §5.3) |
| `TELEGRAM_BOT_TOKEN` | **yes** | from @BotFather; verifies `initData` server-side |
| `TELEGRAM_BOT_USERNAME` | no | optional |
| `LLM_BASE_URL` | **yes** | OpenAI-compatible `/v1` base |
| `LLM_API_KEY` | **yes** | server-side secret |
| `LLM_MODEL` / `LLM_TIMEOUT_MS` / `LLM_MAX_RETRIES` | no (defaults) | `gpt-4o-mini` / `20000` / `1` |
| `WALLET_STARTER_COINS` / `WALLET_READING_COST` | no (defaults) | `30` / `5` |

Without `JWT_*`, `TELEGRAM_BOT_TOKEN`, or `LLM_*` the API **refuses to boot in
production** — by design (no mock readings, no ephemeral keys in prod).

### Mobile (build-time `--dart-define`, not a file)
| Define | Required | Notes |
|---|---|---|
| `API_BASE_URL` | **yes** | MUST end with `/api/v1`, e.g. `https://api.example.com/api/v1` |
| `TELEGRAM_BOT_USERNAME` | no | optional |
| `API_CONNECT_TIMEOUT_MS` / `API_RECEIVE_TIMEOUT_MS` | no | defaults 15000 / 20000 |
| `ENABLE_ANALYTICS` / `ENABLE_CRASH_REPORTING` / `ENABLE_DEBUG_MENU` | no | default false |
| `DEV_TELEGRAM_INITDATA` | **NEVER in prod** | honored only in the dev flavor |

## 2. Supported LLM providers (OpenAI-compatible `/chat/completions`, JSON mode)
Any endpoint that accepts `POST {baseUrl}/chat/completions` with a Bearer key and
`response_format: {type: json_object}`:
- **OpenAI** — `https://api.openai.com/v1`
- **Azure OpenAI** — your deployment's OpenAI-compatible URL
- **OpenRouter** — `https://openrouter.ai/api/v1`
- **Together** — `https://api.together.xyz/v1`
- **Groq** — `https://api.groq.com/openai/v1`
- **DeepSeek** — `https://api.deepseek.com/v1`
- **Mistral / Fireworks** — their OpenAI-compatible bases
- **Local** — Ollama (`http://host:11434/v1`) or LM Studio (`http://host:1234/v1`)

Set `LLM_MODEL` to a model the chosen provider serves.

## 3. Build commands + exact output paths

### API
```
npm ci
npm --workspace apps/api run prisma:generate
npx --workspace apps/api prisma migrate deploy      # applies migrations to DATABASE_URL
npm run api:build                                   # → apps/api/dist/  (entry: dist/main.js)
```
Run: `cd apps/api && node dist/main.js` (with the API env loaded). Postgres + Redis must be reachable.

### Web (Telegram Mini App)
```
cd apps/mobile
flutter pub get
flutter gen-l10n
flutter build web --release -t lib/main_production.dart \
  --dart-define=API_BASE_URL=https://<API_DOMAIN>/api/v1 \
  --dart-define=TELEGRAM_BOT_USERNAME=<bot_username>
```
Output: **`apps/mobile/build/web/`** — static files to serve over HTTPS.

## 4. Simplest secure deployment path

You need three HTTPS-reachable pieces: a Postgres, a Redis, the API, and the static web.

### 4.1 Database + cache
Use managed Postgres + Redis (e.g. Railway, Neon + Upstash, Fly.io Postgres),
**or** a VPS running the repo's `docker-compose.yml` (Postgres + Redis) behind the API.

### 4.2 API — HTTPS API URL
Deploy `apps/api` to a Node host (Railway / Render / Fly.io / a VPS). Set all §1 API
vars. On boot it runs behind TLS at e.g. `https://api.example.com` (base path `/api/v1`).
Run `prisma migrate deploy` once before first start.

### 4.3 JWT keypair
```
openssl genpkey -algorithm ed25519 -out jwt_private.pem
openssl pkey -in jwt_private.pem -pubout -out jwt_public.pem
```
Put the PEM contents into `JWT_PRIVATE_KEY` / `JWT_PUBLIC_KEY` (preserve newlines;
most PaaS secret editors accept multi-line values).

### 4.4 Web — HTTPS frontend URL
Serve `apps/mobile/build/web/` on a static HTTPS host (**Cloudflare Pages**, Netlify,
Vercel, or an Nginx VPS). Result e.g. `https://app.example.com`. Telegram requires HTTPS.

### 4.5 CORS
On the API set `CORS_ALLOWED_ORIGINS=https://app.example.com` (the web origin). The
web app calls the API cross-origin, so this must match exactly.

### 4.6 Telegram BotFather / Mini App
1. In Telegram open **@BotFather**.
2. `/newbot` (or reuse a bot) → note the **bot token** → set it as `TELEGRAM_BOT_TOKEN` on the API.
3. `/newapp` (or **Bot Settings → Configure Mini App**) → select the bot.
4. Set the **Web App URL** to your frontend: `https://app.example.com`.
5. (Optional) **Bot Settings → Menu Button** → set it to open the Mini App, and/or use the direct link `https://t.me/<bot_username>/<app_short_name>`.

## 5. Verify the complete real flow (§6 of the brief — the PASS gate)
With the API and web deployed and the bot configured, open the Mini App in Telegram and confirm end-to-end:
1. **Launch** the Mini App from the bot (menu button / direct link).
2. **Auth:** the WebApp bridge sends real `initData` to `POST /api/v1/auth/telegram`; a session is established (no `DEV_TELEGRAM_INITDATA`).
3. **Explore** loads the catalog.
4. Select **Hafez / Tarot / Dream / Love**, complete the ritual input, submit.
5. `POST /api/v1/readings` debits a coin, calls the **real LLM** (not the mock), returns a reading.
6. Open **History** → `GET /api/v1/readings` shows the reading (**persistence** confirmed).

Evidence to capture (real, not fabricated): a screen recording or screenshots of steps 1→6, plus the API logs showing `reading.provider.selected {provider: 'ai'}` and `reading.ai.succeeded`.

## 6. What this repo does NOT decide for you
- Which host/provider and domains you use.
- The real bot token and LLM key (secrets — never in git).
- The live Telegram handshake and the real LLM response — these only exist once deployed.

**Do not mark the demo PASS until §5 has actually been executed successfully.**
