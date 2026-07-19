#!/usr/bin/env bash
# Bring up local infra (Postgres + Redis) for development.
set -euo pipefail
docker compose -f docker-compose.yml up -d
echo "Postgres :5432  Redis :6379  — up."
