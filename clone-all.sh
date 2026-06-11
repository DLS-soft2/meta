#!/usr/bin/env bash
set -euo pipefail

ORG="https://github.com/DLS-soft2"
REPOS=(
  api-gateway
  order-service
  payment-service
  restaurant-service
  courier-service
  notification-service
  user-service
  ai-service
  frontend
  auth-lib-java
  auth-lib-python
  shared-workflows
  infra
  docs
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

declare -A RESULTS
PIDS=()

for repo in "${REPOS[@]}"; do
  (
    if [ -d "$repo" ]; then
      git -C "$repo" pull --ff-only 2>&1
    else
      git clone "$ORG/$repo.git" 2>&1
    fi
  ) > /tmp/clone_${repo}.log 2>&1 &
  PIDS+=("$!:$repo")
done

PASS=0
FAIL=0
FAILURES=()

for entry in "${PIDS[@]}"; do
  pid="${entry%%:*}"
  repo="${entry#*:}"
  if wait "$pid"; then
    RESULTS[$repo]="ok"
    ((PASS++))
  else
    RESULTS[$repo]="FAILED"
    ((FAIL++))
    FAILURES+=("$repo")
  fi
done

echo ""
echo "==============================="
echo "  Clone Summary"
echo "==============================="
for repo in "${REPOS[@]}"; do
  printf "  %-25s %s\n" "$repo" "${RESULTS[$repo]}"
done
echo "-------------------------------"
echo "  Total: ${#REPOS[@]}  Pass: $PASS  Fail: $FAIL"
echo "==============================="

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "Failed repos:"
  for repo in "${FAILURES[@]}"; do
    echo "  - $repo"
    cat "/tmp/clone_${repo}.log" 2>/dev/null | sed 's/^/    /'
  done
  exit 1
fi
