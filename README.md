# Amux

Research, planning, and code review skills for Claude Code with multi-engine cross-validation (Claude + Codex + Gemini).

## What's Included

### Skills (3)

- **research** — Deep research with 20+ sources and confidence tracking, powered by agent teams with Codex/Gemini cross-validation
- **planning** — Pre-implementation planning that researches approaches using Context7, Serper, GitHub MCPs, and optionally btca for source-level codebase research, with multi-engine evaluation via Codex (MCP) and Gemini (CLI)
- **code-review-pipeline** — Multi-reviewer code review using agent teams (architecture, implementation, tech practices, tests, UI), each cross-validated with Codex and Gemini

### Agents (6)

**Pipeline reviewers (5):** architecture, implementation, tech practices, tests, UI — dispatched by the code-review-pipeline skill based on file types. Each performs Claude analysis and calls Codex (MCP) and Gemini (CLI) for cross-validation.

**Standalone reviewer (1):** code — reviews completed work against the original plan and coding standards. Invoked via `/review-code`.

### Commands (8)

- `/research` — Start a deep research session
- `/code-review-pipeline` — Run the full review pipeline
- `/review-architecture`, `/review-code`, `/review-implementation`, `/review-tech-practices`, `/review-tests`, `/review-ui` — Individual review commands

### Hooks

- **session-start** — Announces available skills and detects Codex/Gemini CLI presence (note: CLI presence does not guarantee MCP/CLI usability)
- **task-loop-hook** — Generic task loop that blocks exit while any skill's `task-loop.json` has `complete: false`. Used by research (and available for future long-running skills).
- **pre-commit-quality-gate** — Runs quality checks before commits

### Multi-Engine Architecture

Each reviewer agent independently:
1. Performs Claude-based domain review
2. Calls the native `codex` MCP tool with `cwd` set to the repo root
3. Validates the Codex response — empty, non-JSON, or MCP error-text responses are treated as Codex-unavailable
4. Calls Gemini CLI via Bash (`gemini -p "..." -m gemini-2.5-pro -o json --approval-mode plan`)
5. Validates the Gemini response — extracts `.response` from JSON envelope, parses as JSON; empty, non-JSON, or error-text means Gemini-unavailable
6. Merges findings from all available engines with classification (AGREE/CHALLENGE/COMPLEMENT)
7. Returns unified JSON with engine tags and cross-validation status

Cross-validated findings (flagged by 2+ engines) receive a confidence boost — these are the highest-signal issues. Reviewers gracefully degrade to fewer engines when any engine is unavailable or returns unusable output. A Claude-only result is always valid.

## Prerequisites

- **Claude Code** with plugin support
- **Codex CLI** (optional, for Codex cross-validation): `npm i -g @openai/codex` — uses native `codex mcp-server`
- **Gemini CLI** (optional, for Gemini cross-validation): `brew install gemini-cli` or `npm i -g @google/gemini-cli` — invoked directly via Bash
- **btca** (optional, for source-level codebase research in planning): `bun add -g btca` then `claude mcp add --transport stdio btca-local -- bunx btca mcp`

## Installation

### Claude Code (via Plugin Marketplace)

```bash
/plugin marketplace add guyathomas/amux-marketplace
```

```bash
/plugin install amux@amux-marketplace
```

### Verify

```bash
/help
# Should list /amux:research, /amux:code-review-pipeline, etc.
```

## License

MIT — see [LICENSE](LICENSE)
