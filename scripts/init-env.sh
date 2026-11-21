#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p .secrets
chmod 700 .secrets
if [[ ! -f .secrets/runtime.env ]]; then
  : > .secrets/runtime.env
  chmod 600 .secrets/runtime.env
fi

# gogate only needs its own settings plus the OTel endpoint. Do not hand it the
# console/lmlog tokens or the Grafana password from the shared .env.
write_gogate_env() {
  grep -E '^(GOGATE_[A-Z0-9_]+|OTEL_[A-Z0-9_]+)=' .env > .secrets/gogate.env || true
  chmod 600 .secrets/gogate.env
}

if [[ -f .env ]]; then
  write_gogate_env
  echo "==> .env already exists; leaving it unchanged"
  exit 0
fi

gen() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "${1:-32}"
  else
    python3 -c "import secrets; print(secrets.token_hex(${1:-32}))"
  fi
}

set_value() {
  local key="$1"
  local value="$2"
  sed -i "s|^${key}=.*|${key}=${value}|" .env
}

cp .env.example .env

postgres_password="$(gen 24)"
redis_password="$(gen 24)"
gogate_admin_token="$(gen 32)"
gogate_pepper="$(gen 32)"
lmlog_token="$(gen 32)"
console_token="$(gen 32)"
console_secret="$(gen 32)"
grafana_password="$(gen 24)"

set_value POSTGRES_PASSWORD "$postgres_password"
sed -i "s|replace-with-a-random-postgres-password|${postgres_password}|g" .env
set_value GOGATE_REDIS_PASSWORD "$redis_password"
set_value GOGATE_ADMIN_TOKEN "$gogate_admin_token"
set_value GOGATE_API_KEY_PEPPER "$gogate_pepper"
set_value LMLOG_API_TOKEN "$lmlog_token"
set_value CONSOLE_AUTH_TOKEN "$console_token"
set_value CONSOLE_SESSION_SECRET "$console_secret"
set_value GF_SECURITY_ADMIN_PASSWORD "$grafana_password"

chmod 600 .env .secrets/runtime.env
write_gogate_env
echo "==> wrote .env with random local secrets"
echo "==> run 'make up' to pull the model, start the stack and create gateway keys"
