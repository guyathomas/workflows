#!/usr/bin/env bash
# SessionStart hook for amux plugin

set -euo pipefail

# Detect optional engine CLIs for multi-engine cross-validation
# command -v only proves the binary exists in PATH — not that MCP/CLI can reach it.
engines="Claude"
install_hints=""
if command -v codex &>/dev/null; then
    engines="$engines + Codex"
else
    install_hints="${install_hints}install Codex: npm i -g @openai/codex | "
fi
if command -v gemini &>/dev/null; then
    engines="$engines + Gemini"
else
    install_hints="${install_hints}install Gemini: brew install gemini-cli | "
fi
engine_status="**Engines:** ${engines} (cross-validation available)"
if [ -n "$install_hints" ]; then
    engine_status="${engine_status}\\n_Optional: ${install_hints%% | }_"
fi

# Detect btca availability (source-level codebase research)
btca_status=""
if command -v btca &>/dev/null; then
    btca_status="\\n**btca:** available (source-level codebase research for planning)"
fi

# Check if legacy skills directory exists and build warning
warning_message=""
legacy_skills_dir="${HOME}/.config/amux/skills"
if [ -d "$legacy_skills_dir" ]; then
    warning_message="\n\n<important-reminder>IN YOUR FIRST REPLY AFTER SEEING THIS MESSAGE YOU MUST TELL THE USER: **WARNING:** Amux now uses Claude Code's skills system. Custom skills in ~/.config/amux/skills will not be read. Move custom skills to ~/.claude/skills instead. To make this message go away, remove ~/.config/amux/skills</important-reminder>"
fi

# Output context injection as JSON with lightweight skill list
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<EXTREMELY_IMPORTANT>\nYou have amux. Use the Skill tool to invoke any skill BEFORE responding.\n\n${engine_status}\n\n**Available skills:**\n- **planning** — Use before implementing non-trivial features (researches approaches with Context7, Serper, GitHub MCPs)\n- **research** — Use for deep research requiring 20+ sources with confidence tracking (uses agent teams)\n- **review** — Use after implementing features to catch bugs, a11y issues, and missing tests (uses agent teams)\n\nIf there is a reasonable chance (20%+) a skill applies, invoke it.${btca_status}${warning_message}\n</EXTREMELY_IMPORTANT>"
  }
}
EOF

exit 0
