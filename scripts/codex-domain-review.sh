#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${1:-}"
OUT_FILE="${2:-}"

[[ -z "$DOMAIN" || -z "$OUT_FILE" ]] && {
  echo "Usage: codex-domain-review.sh <domain> <output-file>"
  exit 1
}

SKIP_MARKER='{"agent":"codex-'"$DOMAIN"'","filesReviewed":[],"findings":[],"missingTests":[],"summary":"skipped — codex unavailable"}'

command -v codex >/dev/null 2>&1 || {
  echo "$SKIP_MARKER" > "$OUT_FILE"
  exit 0
}

mkdir -p "$(dirname "$OUT_FILE")"

DIFF="$(git diff main)"
FILE_LIST="$(git diff --name-only main)"

[[ -z "$DIFF" ]] && {
  echo "$SKIP_MARKER" > "$OUT_FILE"
  exit 0
}

PROMPT_FILE="$(mktemp -t codex-domain-review.XXXXXX)"
trap 'rm -f "$PROMPT_FILE"' EXIT

{
  cat <<EOF
You are a senior code reviewer. Focus your review on the **$DOMAIN** domain.

## Changed files
$FILE_LIST

## Output format

Return ONLY valid JSON (no markdown fences, no commentary):
{
  "agent": "codex-$DOMAIN",
  "filesReviewed": ["file1.ts"],
  "findings": [
    {
      "severity": "critical|high|medium|low",
      "confidence": 90,
      "file": "file1.ts",
      "line": 42,
      "issue": "Description of the issue",
      "recommendation": "Specific fix suggestion",
      "category": "category-name"
    }
  ],
  "missingTests": [],
  "summary": "Summary of findings"
}

If no issues found, return empty findings array with summary "No issues found".

## Diff
$DIFF
EOF
} > "$PROMPT_FILE"

TIMEOUT_MARKER='{"agent":"codex-'"$DOMAIN"'","filesReviewed":[],"findings":[],"missingTests":[],"summary":"skipped — codex timed out"}'

if ! timeout 120 codex exec \
  --skip-git-repo-check \
  --sandbox read-only \
  --output-last-message "$OUT_FILE" \
  - < "$PROMPT_FILE" 2>/dev/null; then
  echo "$TIMEOUT_MARKER" > "$OUT_FILE"
  exit 0
fi

# Validate JSON output
if [[ -f "$OUT_FILE" ]] && ! jq empty "$OUT_FILE" 2>/dev/null; then
  RAW="$(cat "$OUT_FILE")"
  cat <<EOF > "$OUT_FILE"
{"agent":"codex-$DOMAIN","filesReviewed":[],"findings":[],"missingTests":[],"summary":"codex returned malformed output","rawOutput":$(echo "$RAW" | jq -Rs .)}
EOF
fi
