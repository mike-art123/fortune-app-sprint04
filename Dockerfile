# Production image for the NestJS API (apps/api).
#
# This is a MONOREPO with npm workspaces: the single package-lock.json and the
# workspace links live at the REPOSITORY ROOT, so the Railway "Root Directory"
# must be the repo root (/) and the Docker build context must be the repo root.
# `apps/api` alone has no lockfile — `npm ci` only works from here.

# ---- deps: install the whole workspace from the root lockfile ----
FROM node:20-alpine AS deps
WORKDIR /app
# Copy only manifests first for better layer caching. Every workspace listed in
# the root package.json "workspaces" must be present for `npm ci` to link them.
COPY package.json package-lock.json ./
COPY apps/api/package.json apps/api/package.json
COPY packages/shared_contracts/package.json packages/shared_contracts/package.json
COPY packages/lint_rules/package.json packages/lint_rules/package.json
RUN npm ci

# ---- build: generate Prisma client + compile Nest to dist ----
FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Prisma downloads the correct musl engine here (build runs on alpine, so does
# runtime). api:build == `npm --workspace apps/api run build` == `nest build`.
RUN npm --workspace apps/api run prisma:generate \
 && npm run api:build

# ---- runtime: small non-root image; migrate then start; bind $PORT ----
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -S app && adduser -S app -G app
# node_modules is copied whole so the Prisma CLI (used by `migrate deploy` at
# start) and the generated client both remain available at runtime.
COPY --from=build --chown=app:app /app/node_modules ./node_modules
COPY --from=build --chown=app:app /app/package.json ./package.json
COPY --from=build --chown=app:app /app/apps/api/dist ./apps/api/dist
COPY --from=build --chown=app:app /app/apps/api/prisma ./apps/api/prisma
COPY --from=build --chown=app:app /app/apps/api/package.json ./apps/api/package.json
USER app
EXPOSE 3000
# Liveness probe path is served by the app (global prefix + URI version => /api/v1).
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT:-3000}/api/v1/health/live" || exit 1
# Apply pending migrations (idempotent, production-safe — NOT `migrate dev`),
# then launch. The app binds the platform-injected $PORT (falls back to APP_PORT).
CMD ["sh","-c","./node_modules/.bin/prisma migrate deploy --schema=apps/api/prisma/schema.prisma && node apps/api/dist/main.js"]
