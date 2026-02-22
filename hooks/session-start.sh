#!/usr/bin/env bash
# SessionStart hook for workflows plugin

set -euo pipefail

# Detect Codex availability
if command -v codex &>/dev/null; then
    engine_status="**Engines:** Claude + Codex (dual-engine mode)"
else
    engine_status="**Engines:** Claude only (install Codex for dual-engine cross-validation)"
fi

# Check if legacy skills directory exists and build warning
warning_message=""
legacy_skills_dir="${HOME}/.config/workflows/skills"
if [ -d "$legacy_skills_dir" ]; then
    warning_message="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER: **WARNING:** Workflows now uses Claude Code's skills system. Custom skills in ~/.config/workflows/skills will not be read. Move custom skills to ~/.claude/skills instead. To make this message go away, remove ~/.config/workflows/skills</important-reminder>"
fi

# shellcheck source=../lib/escape-json.sh
source "$(cd "$(dirname "$0")" && pwd)/../lib/escape-json.sh"

warning_escaped=$(escape_for_json "$warning_message")

# Output context injection as JSON with lightweight skill list
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have workflows. Use the Skill tool to invoke any skill BEFORE responding.\n\n${engine_status}\n\n**Available skills:**\n- **planning** — Use before implementing non-trivial features (researches approaches with Context7, Serper, GitHub MCPs)\n- **research** — Use for deep research requiring 20+ sources with confidence tracking (uses agent teams)\n- **review** — Use after implementing features to catch bugs, a11y issues, and missing tests (uses agent teams)\n\nIf there is a reasonable chance (20%+) a skill applies, invoke it.${warning_escaped}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
