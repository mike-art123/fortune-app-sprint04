# BakhtNegar — Production Deployment Runbook (Railway API + Cloudflare Pages web)

> **Status: NOT PASS yet.** This environment has no Railway/Cloudflare tooling, no
> network egress, and cannot handle secrets, so the live deploy and health checks
> were **not executed here**. The repo is now correctly configured for deployment
> (commits below); the steps that earn a PASS are the dashboard actions + the live
> checks in §7, which must be run by an operator with the real secrets.

Deploy commits (local — push via GitHub Desktop → "Push origin"):
`66505b4` API binds platform `PORT` · `fcc821c` monorepo-root Railway build · `b28e155` Cloudflare Pages workflow.

---

## 1. Phase 1 findings (evidence-based)

| Question | Answer | Evidence |
|---|---|---|
| Railway Root Directory | **`/` (repo root)** — NOT `/apps/api` | Root `package.json` `workspaces:[apps/api,…]`; the only `package-lock.json` is at root; `apps/api` has no lockfile → `npm ci` only works from root. |
| Depends on root workspace install | **Yes** | `@fortune/api` is a workspace; deps hoist to root `node_modules`. |
| Install | `npm ci` (repo root) | root lockfile |
| Prisma generate | `npm --workspace apps/api run prisma:generate` | apps/api script |
| Migration (prod) | `prisma migrate deploy` (via `apps/api` `prisma:deploy`) — **never** `prisma:migrate` (=`migrate dev`) | apps/api/package.json |
| Build | `npm run api:build` → `apps/api/dist` | `nest build` |
| Start | `node apps/api/dist/main.js` | `start:prod` |
| Health endpoint | `GET /api/v1/health/live` (liveness); `GET /api/v1/health/ready` (Postgres+Redis) | health.controller.ts; global prefix `api` + URI v`1` |
| Port | app binds **`PORT`** (now) → falls back to `APP_PORT` | fixed in `66505b4`; `bootstrap.ts app.listen(port,host)` |

**All of install/generate/migrate/build/start are now baked into the root `Dockerfile` + `railway.json`** — Railway just needs Root Directory `/` and the variables.

## 2. Railway — service configuration (project `perpetual-embrace`, env `production`, service `fortune-app-sprint04`)

1. **Settings → Source → Root Directory:** change `/apps/api` → **`/`** (empty / root).
2. **Settings → Build:** Railway auto-detects the root `Dockerfile` (and `railway.json` pins builder = `DOCKERFILE`, healthcheck path `/api/v1/health/live`). No custom install/build/start needed — the image + `railway.json` handle install, `prisma migrate deploy`, and start.
3. **Settings → Networking:** **Generate Domain** (public HTTPS). Railway injects `PORT`; the app now binds it. Note the domain, e.g. `https://fortune-app-sprint04-production.up.railway.app`.

## 3. Railway — variables (API service → Variables)

Reference variables (keep server-to-server on the private network). **Confirm the exact Redis var names in the Redis service → Variables tab** and match the reference source name to your Redis service's actual name.

| App variable | Value | Kind |
|---|---|---|
| `NODE_ENV` | `production` | plain |
| `APP_NAME` | `bakhtnegar-api` | plain |
| `APP_HOST` | `0.0.0.0` | plain |
| `API_PREFIX` | `api` | plain |
| `API_VERSION` | `1` | plain |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | reference *(already set)* |
| `REDIS_HOST` | `${{Redis.REDISHOST}}` | reference |
| `REDIS_PORT` | `${{Redis.REDISPORT}}` | reference |
| `REDIS_USERNAME` | `${{Redis.REDISUSER}}` | reference *(omit if service has none)* |
| `REDIS_PASSWORD` | `${{Redis.REDISPASSWORD}}` | reference |
| `REDIS_TLS` | `false` | plain *(private-network Redis is non-TLS)* |
| `QUEUE_PREFIX` | `fortune` | plain |
| `LOG_LEVEL` | `info` | plain |
| `ENABLE_PRETTY_LOGS` | `false` | plain |
| `SWAGGER_ENABLED` | `false` | plain *(set `true` only if you also want public docs; CORS then required)* |
| `CORS_ALLOWED_ORIGINS` | `https://<pages-domain>` | plain — **set after §5** |
| `REQUEST_TIMEOUT_MS` | `30000` | plain |
| `RATE_LIMIT_TTL_SECONDS` | `60` | plain |
| `RATE_LIMIT_MAX` | `120` | plain |
| `JWT_ISSUER` | `fortune-app` | plain |
| `JWT_AUDIENCE` | `fortune-clients` | plain |
| `JWT_PUBLIC_KEY` | *(paste `deploy-secrets/jwt_public.pem`, full PEM)* | plain |
| `JWT_PRIVATE_KEY` | *(paste `deploy-secrets/jwt_private.pem`, full PEM)* | **secret** |
| `TELEGRAM_BOT_TOKEN` | *(from @BotFather)* | **secret — you enter** |
| `TELEGRAM_BOT_USERNAME` | `bakhtnegarbot` | plain |
| `FEATURE_FLAGS_SOURCE` | `env` | plain |
| `LLM_BASE_URL` | e.g. `https://api.openai.com/v1` | plain |
| `LLM_API_KEY` | *(provider key)* | **secret — you enter** |
| `LLM_MODEL` | e.g. `gpt-4o-mini` | plain |
| `LLM_TIMEOUT_MS` | `20000` | plain |
| `LLM_MAX_RETRIES` | `1` | plain |
| `WALLET_STARTER_COINS` | `30` | plain |
| `WALLET_READING_COST` | `5` | plain |

Do **not** set `APP_PORT` — the app binds Railway's injected `PORT`. The production env-schema refuses to boot without `TELEGRAM_BOT_TOKEN`, the JWT keypair, and `LLM_BASE_URL`+`LLM_API_KEY` (by design: no mock readings in prod).

**JWT keypair:** paste the two PEM files from `deploy-secrets/` (generated for you, RSA-2048 → RS256). Railway multi-line secret fields accept the PEM as-is (with real newlines). After pasting, **delete the local `deploy-secrets/` folder** (it is git-ignored and must never be committed).

## 4. Deploy the API + verify

Trigger a redeploy (push or "Deploy"). Watch build + runtime logs. On success:
- `prisma migrate deploy` applies `20260719000000_init_identity_entitlements` and `20260720000000_wallet_user_fk`.
- Boot log `api_started {env:'production', port:<PORT>}` and `reading.provider.selected {provider:'ai'}`.

## 5. Cloudflare Pages — Flutter Web (project `bakhtnegar`)

Method: **GitHub Actions + Wrangler** (workflow `.github/workflows/deploy-pages.yml`, added in `b28e155`). Cloudflare Pages doesn't ship Flutter, so CI builds it and Wrangler publishes `apps/mobile/build/web`.

1. Create a Cloudflare Pages project named **`bakhtnegar`** (Workers & Pages → Create → Pages → *Direct upload*/*Connect to Git*; the workflow publishes via Wrangler so a Direct-upload project is fine).
2. Create a Cloudflare **API token** with **Account → Cloudflare Pages → Edit** and note your **Account ID**.
3. In the GitHub repo → Settings:
   - **Secrets:** `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`.
   - **Variables:** `API_BASE_URL` = `https://<railway-api-domain>/api/v1` (from §2.3), `TELEGRAM_BOT_USERNAME` = `bakhtnegarbot`.
4. Push to `main` (or run the workflow manually). It builds the **production** flavor (`-t lib/main_production.dart`, real `API_BASE_URL`), writes `_redirects` (SPA fallback), and deploys. Note the Pages URL, e.g. `https://bakhtnegar.pages.dev`.

> Until `API_BASE_URL` is set, the deploy job is **skipped** (Actions stays green).

**Then close the loop:** set Railway `CORS_ALLOWED_ORIGINS` = the exact Pages origin (`https://bakhtnegar.pages.dev`), redeploy the API, and re-test a browser request.

## 6. Telegram (BotFather) — you perform these

1. @BotFather → `/newapp` → select **@bakhtnegarbot**.
2. Set the **Web App URL** to the Pages URL `https://bakhtnegar.pages.dev` (title, short name, icon as prompted).
3. **Bot Settings → Menu Button → Configure menu button** → same URL (label e.g. «فال»).
4. Open the bot in Telegram, tap the menu button → the Mini App loads → real `initData` is POSTed to `/api/v1/auth/telegram` (no `DEV_TELEGRAM_INITDATA`).

Identities: bot **@bakhtnegarbot** · channel **@BakhtNegar** · group **@BakhtNegarChat**.

## 7. Production validation (the PASS gate)

From the public Railway domain and the Pages URL:
- `GET /api/v1/health/live` → `200 {"status":"ok"}`.
- `GET /api/v1/health/ready` → `200 {"status":"ok","checks":{"database":"up","redis":"up"}}` (DB + Redis reachable, migrations applied).
- A protected route without a token → **401** (contract), no stack trace / SQL / secrets leaked.
- Restart the service once → returns healthy; Postgres + Redis volumes intact.
- In Telegram: launch → auth → Explore → submit a Hafez/Tarot/Dream/Love reading (real LLM, coin debited) → History shows it (persistence). Capture a real recording + logs `reading.ai.succeeded`.

Only when §7 passes end-to-end is this **PASS**.

## 8. What still requires you (secrets / dashboards)
- Enter `TELEGRAM_BOT_TOKEN` and `LLM_API_KEY` directly in Railway (never in chat).
- Paste the JWT PEMs into Railway, then delete `deploy-secrets/`.
- Do the Railway Root Directory change, domain generation, Cloudflare project + token, GitHub secrets/vars, BotFather, and the live checks.
