#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
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

LMLOG="http://127.0.0.1:${LMLOG_SERVE_PORT:-8090}"
SAMPLE="../lmlog/examples/console-sample.log"

restore_gogate() {
  docker compose start gogate >/dev/null 2>&1 || true
}
trap restore_gogate EXIT

echo "==> uploading a sample log"
JOB_JSON="$(curl -fsS -X POST "${LMLOG}/api/v1/jobs" \
  -H "Authorization: Bearer ${LMLOG_API_TOKEN:?LMLOG_API_TOKEN is required}" \
  -F "file=@${SAMPLE};type=text/plain")"
JOB_ID="$(jq -r '.job_id' <<<"${JOB_JSON}")"
for _ in $(seq 1 60); do
  JOB="$(curl -fsS "${LMLOG}/api/v1/jobs/${JOB_ID}" -H "Authorization: Bearer ${LMLOG_API_TOKEN}")"
  STATUS="$(jq -r '.status' <<<"${JOB}")"
  [[ "${STATUS}" == "completed" ]] && break
  [[ "${STATUS}" == "failed" ]] && { echo "job failed: ${JOB}" >&2; exit 1; }
  sleep 1
done
[[ "${STATUS}" == "completed" ]] || { echo "job did not complete" >&2; exit 1; }

SIGNATURE="$(curl -fsS "${LMLOG}/api/v1/snapshots/${JOB_ID}/errors?limit=1" \
  -H "Authorization: Bearer ${LMLOG_API_TOKEN}" | jq -r '.items[0].signature // empty')"
[[ -n "${SIGNATURE}" ]] || { echo "no error clusters in the sample log" >&2; exit 1; }

echo "==> stopping gogate"
docker compose stop gogate >/dev/null

PAYLOAD="$(jq -nc --arg snapshot "${JOB_ID}" --arg signature "${SIGNATURE}" \
  '{snapshot_id: $snapshot, signature: $signature, use_llm: true, refresh: true}')"
EXPLAIN="$(curl -fsS -X POST "${LMLOG}/api/v1/explain" \
  -H "Authorization: Bearer ${LMLOG_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${PAYLOAD}")"
SOURCE="$(jq -r '.source' <<<"${EXPLAIN}")"

echo "==> explain source=${SOURCE} (expected heuristic)"
jq -r '.text' <<<"${EXPLAIN}" | head -n 6

if [[ "${SOURCE}" != "heuristic" ]]; then
  echo "expected heuristic fallback while gogate is down" >&2
  exit 1
fi
