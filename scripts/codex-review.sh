#!/usr/bin/env bash
set -euo pipefail

AGENT_TYPE="${1:-}"
DIFF_FILE="${2:-}"
OUT_FILE="${3:-}"

[[ -z "$AGENT_TYPE" || -z "$DIFF_FILE" || -z "$OUT_FILE" ]] && {
  echo "Usage: codex-review.sh <agent-type> <diff-file> <output-file>"
  exit 1
}

command -v codex >/dev/null 2>&1 || {
  echo "codex CLI not found — skipping codex review for $AGENT_TYPE"
  exit 0
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_FILE="$SCRIPT_DIR/../agents/${AGENT_TYPE}.md"

[[ ! -f "$AGENT_FILE" ]] && {
  echo "Agent file not found: $AGENT_FILE"
  exit 0
}
[[ ! -f "$DIFF_FILE" ]] && {
  echo "Diff file not found: $DIFF_FILE"
  exit 0
}

mkdir -p "$(dirname "$OUT_FILE")"

PROMPT_FILE="$(mktemp -t "codex-review-${AGENT_TYPE}.XXXXXX")"
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  # Strip YAML frontmatter (opening --- through closing ---), keep the body
  awk 'BEGIN{fm=0} /^---$/{fm++; next} fm>=2{print}' "$AGENT_FILE"

  printf '\n=== DIFF ===\n'
  cat "$DIFF_FILE"

  printf '\n=== OUTPUT FORMAT ===\n'
  cat <<'PROMPT'
Return your findings as a JSON array. Each finding must have these fields:
- severity: "critical" | "high" | "medium" | "low"
- file: file path
- line: line number
- issue: short description
- recommendation: suggested fix
- confidence: 0-100
- source: "codex"

Return ONLY the JSON array, no markdown fences or surrounding text.
PROMPT
} > "$PROMPT_FILE"

codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  --output-last-message "$OUT_FILE" \
  - < "$PROMPT_FILE"
