# Amux

Research, planning, and code review skills for Claude Code with dual-engine cross-validation (Claude + Codex).

## What's Included

### Skills (3)

- **research** — Deep research with 20+ sources and confidence tracking, powered by agent teams with Codex cross-validation
- **planning** — Pre-implementation planning that researches approaches using Context7, Serper, GitHub MCPs, and optionally btca for source-level codebase research, with dual-engine evaluation via Codex MCP
- **code-review-pipeline** — Multi-reviewer code review using agent teams (architecture, implementation, tech practices, tests, UI), each cross-validated with Codex

### Agents (6)

**Pipeline reviewers (5):** architecture, implementation, tech practices, tests, UI — dispatched by the code-review-pipeline skill based on file types. Each performs Claude analysis and calls the native `codex` MCP tool for cross-validation.

**Standalone reviewer (1):** code — reviews completed work against the original plan and coding standards. Invoked via `/review-code`.

### Commands (8)

- `/research` — Start a deep research session
- `/code-review-pipeline` — Run the full review pipeline
- `/review-architecture`, `/review-code`, `/review-implementation`, `/review-tech-practices`, `/review-tests`, `/review-ui` — Individual review commands

### Hooks

- **session-start** — Announces available skills and detects Codex CLI presence (note: CLI presence does not guarantee MCP usability)
- **task-loop-hook** — Generic task loop that blocks exit while any skill's `task-loop.json` has `complete: false`. Used by research (and available for future long-running skills).
- **pre-commit-quality-gate** — Runs quality checks before commits

### Dual-Engine Architecture

Each reviewer agent independently:
1. Performs Claude-based domain review
2. Calls the native `codex` MCP tool with `cwd` set to the repo root
3. Validates the Codex response — empty, non-JSON, or MCP error-text responses are treated as Codex-unavailable
4. Merges findings with classification (AGREE/CHALLENGE/COMPLEMENT) only if Codex returned valid JSON
5. Returns unified JSON with engine tags and cross-validation status

Cross-validated findings (flagged by both engines) receive a confidence boost — these are the highest-signal issues. Reviewers gracefully degrade to Claude-only when Codex is unavailable or returns unusable output.

## Prerequisites

- **Claude Code** with plugin support
- **Codex CLI** (optional, for dual-engine mode): `npm i -g @openai/codex`
- **Codex MCP server** is declared as an MCP dependency (uses `codex mcp-server` — requires Codex CLI installed)
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
