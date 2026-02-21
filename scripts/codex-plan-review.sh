#!/usr/bin/env bash
set -euo pipefail

PLAN_FILE="${1:-}"
OUT_FILE="${2:-PLAN_REVIEW.md}"

[[ -z "$PLAN_FILE" ]] && {
  echo "Usage: codex-plan-review.sh <plan-file> [output-file]"
  exit 1
}
[[ ! -f "$PLAN_FILE" ]] && {
  echo "Plan file not found: $PLAN_FILE"
  exit 1
}
command -v codex >/dev/null 2>&1 || {
  echo "codex CLI not found on PATH"
  exit 1
}

mkdir -p "$(dirname "$OUT_FILE")"

PROMPT_FILE="$(mktemp -t codex-plan-review.XXXXXX)"
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  cat <<'PROMPT'
You are reviewing a software implementation plan.

Return a structured review in markdown with these sections:
1) Summary of what will be built
2) Assumptions & open questions
3) Risks (correctness, security, performance, operability)
4) Missing edge cases
5) Suggested milestones / task breakdown
6) Test plan (unit/integration/e2e)
7) Rollout / migration plan (if relevant)
8) Acceptance criteria checklist

Be concrete and propose improved wording for the plan where needed.
PROMPT

  printf '\n=== PLAN ===\n'
  cat "$PLAN_FILE"
} > "$PROMPT_FILE"

codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  --output-last-message "$OUT_FILE" \
  - < "$PROMPT_FILE"

echo "Wrote plan review to: $OUT_FILE"
