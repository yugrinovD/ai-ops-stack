#!/usr/bin/env bash
set -euo pipefail

url="${1:?usage: wait-for.sh URL [attempts]}"
attempts="${2:-90}"

for _ in $(seq 1 "${attempts}"); do
  if curl -fsS "${url}" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 2
done

echo "timed out waiting for ${url}" >&2
exit 1
