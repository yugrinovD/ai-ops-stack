#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
owner="${REPO_OWNER:-yugrinovD}"
repos=(gogate lmlog ops-console ledger)

for repo in "${repos[@]}"; do
  target="${root}/../${repo}"
  if [[ -d "${target}/.git" ]]; then
    echo "==> ${repo}: already present at ${target}"
    continue
  fi
  echo "==> cloning ${owner}/${repo} into ${target}"
  git clone "https://github.com/${owner}/${repo}.git" "${target}"
done

echo "All repositories are in place."
