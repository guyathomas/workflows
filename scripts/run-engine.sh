#!/usr/bin/env bash
set -euo pipefail

# Generalized engine runner. Spawns an external AI engine with a prompt file
# and captures JSON output. Gracefully handles missing binaries, timeouts,
# and malformed output.
#
# Usage: run-engine.sh <engine> <prompt-file> <output-file> [--timeout <seconds>]
#
# Engines: codex (others can be added later)
# Exit: always 0 — failures are encoded as JSON markers in output-file.

ENGINE="${1:-}"
PROMPT_FILE="${2:-}"
OUT_FILE="${3:-}"
TIMEOUT=120

# Validate required args before parsing optional flags
[[ -z "$ENGINE" || -z "$PROMPT_FILE" || -z "$OUT_FILE" ]] && {
  echo "Usage: run-engine.sh <engine> <prompt-file> <output-file> [--timeout <seconds>]" >&2
  exit 1
}

# Allowlist engines before any binary probing
ALLOWED_ENGINES="codex"
if ! echo "$ALLOWED_ENGINES" | tr ' ' '\n' | grep -qx "$ENGINE"; then
  echo "Unknown engine: $ENGINE (allowed: $ALLOWED_ENGINES)" >&2
  exit 1
fi

shift 3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --timeout) [[ -n "${2:-}" ]] || { echo "--timeout requires a value" >&2; exit 1; }; TIMEOUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

marker() {
  jq -n --arg engine "$ENGINE" --arg status "$1" \
    '{engine: $engine, status: $status, output: null}' > "$OUT_FILE"
}

# Ensure output directory exists
mkdir -p "$(dirname "$OUT_FILE")"

# Check engine binary
command -v "$ENGINE" >/dev/null 2>&1 || {
  marker "skipped — $ENGINE not installed"
  exit 0
}

# Validate prompt file
[[ -f "$PROMPT_FILE" ]] || {
  marker "skipped — prompt file not found"
  exit 0
}

# Engine-specific execution (|| true prevents set -e from exiting)
rc=0
case "$ENGINE" in
  codex)
    timeout "$TIMEOUT" codex exec \
      --skip-git-repo-check \
      --sandbox workspace-write \
      --config sandbox_workspace_write.network_access=true \
      --output-last-message "$OUT_FILE" \
      - < "$PROMPT_FILE" 2>/dev/null || rc=$?
    ;;
  *)
    marker "skipped — unknown engine $ENGINE"
    exit 0
    ;;
esac

if [[ $rc -ne 0 ]]; then
  marker "skipped — $ENGINE timed out or failed"
  exit 0
fi

# Validate JSON output
if [[ -s "$OUT_FILE" ]] && ! jq empty "$OUT_FILE" 2>/dev/null; then
  RAW="$(cat "$OUT_FILE")"
  jq -n --arg engine "$ENGINE" --arg raw "$RAW" \
    '{engine: $engine, status: "malformed output", output: null, rawOutput: $raw}' > "$OUT_FILE"
fi

exit 0
