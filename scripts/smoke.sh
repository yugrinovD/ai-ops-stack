#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi
if [[ ! -f .env ]]; then
  echo ".env is missing; run 'make init-env'" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source ./.env
if [[ -f .secrets/runtime.env ]]; then
  # shellcheck disable=SC1091
  source ./.secrets/runtime.env
fi
set +a

PUBLIC="http://127.0.0.1:${GOGATE_HTTP_PORT:-8080}"
ADMIN="http://127.0.0.1:${GOGATE_ADMIN_PORT:-9090}/admin/v1"
LMLOG="http://127.0.0.1:${LMLOG_SERVE_PORT:-8090}"
CONSOLE="http://127.0.0.1:${CONSOLE_PORT:-3100}"
SAMPLE="../lmlog/examples/console-sample.log"

echo "==> gogate readiness"
curl -fsS "${PUBLIC}/readyz" >/dev/null
echo "    ok"

echo "==> lmlog health"
curl -fsS "${LMLOG}/healthz" | jq -c .

echo "==> ops-console health"
curl -fsS "${CONSOLE}/api/health" | jq -c '{status, services: [.services[] | {name, state}]}'

echo "==> uploading a sample log to lmlog"
JOB_JSON="$(curl -fsS -X POST "${LMLOG}/api/v1/jobs" \
  -H "Authorization: Bearer ${LMLOG_API_TOKEN:?LMLOG_API_TOKEN is required}" \
  -F "file=@${SAMPLE};type=text/plain")"
JOB_ID="$(jq -r '.job_id' <<<"${JOB_JSON}")"
echo "    job ${JOB_ID}"

for _ in $(seq 1 60); do
  JOB="$(curl -fsS "${LMLOG}/api/v1/jobs/${JOB_ID}" -H "Authorization: Bearer ${LMLOG_API_TOKEN}")"
  STATUS="$(jq -r '.status' <<<"${JOB}")"
  [[ "${STATUS}" == "completed" ]] && break
  [[ "${STATUS}" == "failed" ]] && { echo "job failed: ${JOB}" >&2; exit 1; }
  sleep 1
done
[[ "${STATUS}" == "completed" ]] || { echo "job did not complete" >&2; exit 1; }

ERRORS="$(curl -fsS "${LMLOG}/api/v1/snapshots/${JOB_ID}/errors?limit=1" \
  -H "Authorization: Bearer ${LMLOG_API_TOKEN}")"
SIGNATURE="$(jq -r '.items[0].signature // empty' <<<"${ERRORS}")"
[[ -n "${SIGNATURE}" ]] || { echo "no error clusters in the sample log" >&2; exit 1; }

PAYLOAD="$(jq -nc --arg snapshot "${JOB_ID}" --arg signature "${SIGNATURE}" \
  '{snapshot_id: $snapshot, signature: $signature, use_llm: true, refresh: true}')"
EXPLAIN="$(curl -fsS -X POST "${LMLOG}/api/v1/explain" \
  -H "Authorization: Bearer ${LMLOG_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}")"

SOURCE="$(jq -r '.source' <<<"${EXPLAIN}")"
MODEL="$(jq -r '.model // "-"' <<<"${EXPLAIN}")"
echo "==> explain source=${SOURCE} model=${MODEL}"
jq -r '.text' <<<"${EXPLAIN}" | head -n 8

echo "==> gogate usage for the lmlog tenant (may be empty right after the request)"
curl -fsS "${ADMIN}/usage?tenant_id=$(curl -fsS "${ADMIN}/tenants" -H "Authorization: Bearer ${GOGATE_ADMIN_TOKEN}" | jq -r '.[] | select(.name=="lmlog") | .id')" \
  -H "Authorization: Bearer ${GOGATE_ADMIN_TOKEN}" | jq -c '.[0] // "no rows yet"' || true

if [[ "${SMOKE_REQUIRE_LLM:-1}" == "1" && "${SOURCE}" != "llm" ]]; then
  echo "expected source=llm; set SMOKE_REQUIRE_LLM=0 to allow heuristic fallback" >&2
  exit 1
fi
