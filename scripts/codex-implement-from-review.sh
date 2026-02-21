#!/usr/bin/env bash
set -euo pipefail

PLAN_FILE="${1:-}"
REVIEW_FILE="${2:-}"
FOCUS="${3:-Correctness first, then tests, then ergonomics.}"

[[ -z "$PLAN_FILE" || -z "$REVIEW_FILE" ]] && {
  echo "Usage: codex-implement-from-review.sh <plan-file> <review-file> [focus]"
  exit 1
}
[[ ! -f "$PLAN_FILE" ]] && {
  echo "Plan file not found: $PLAN_FILE"
  exit 1
}
[[ ! -f "$REVIEW_FILE" ]] && {
  echo "Review file not found: $REVIEW_FILE"
  exit 1
}
command -v codex >/dev/null 2>&1 || {
  echo "codex CLI not found on PATH"
  exit 1
}

PROMPT_FILE="$(mktemp -t codex-implement.XXXXXX)"
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  cat <<'PROMPT'
You are implementing a change in an existing codebase.

You must:
- Follow the plan, incorporating the plan review recommendations.
- Resolve open questions with reasonable decisions and document them in code/comments/docs.
- Prefer small, readable diffs; avoid unrelated refactors.
- Add or adjust tests consistent with the test plan.
- Update docs/changelog when behavior changes.
- End with a concise change summary and test results.
PROMPT

  printf '\nFocus: %s\n' "$FOCUS"
  printf '\n=== PLAN ===\n'
  cat "$PLAN_FILE"
  printf '\n=== PLAN REVIEW ===\n'
  cat "$REVIEW_FILE"
} > "$PROMPT_FILE"

codex exec \
  --full-auto \
  - < "$PROMPT_FILE"
