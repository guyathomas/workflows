# Amux

Research, planning, and code review skills for Claude Code with dual-engine cross-validation (Claude + Codex).

## What's Included

### Skills (3)

- **research** — Deep research with 20+ sources and confidence tracking, powered by agent teams with Codex cross-validation
- **planning** — Pre-implementation planning that researches approaches using Context7, Serper, GitHub MCPs, and optionally btca for source-level codebase research, with dual-engine evaluation via `ask-codex`
- **code-review-pipeline** — Multi-reviewer code review using agent teams (architecture, implementation, tech practices, tests, UI), each cross-validated with Codex

### Agents (6)

**Pipeline reviewers (5):** architecture, implementation, tech practices, tests, UI — dispatched by the code-review-pipeline skill based on file types. Each performs Claude analysis and calls `ask-codex` for Codex cross-validation.

**Standalone reviewer (1):** code — reviews completed work against the original plan and coding standards. Invoked via `/review-code`.

### Commands (8)

- `/research` — Start a deep research session
- `/code-review-pipeline` — Run the full review pipeline
- `/review-architecture`, `/review-code`, `/review-implementation`, `/review-tech-practices`, `/review-tests`, `/review-ui` — Individual review commands

### Hooks

- **session-start** — Announces available skills and detects Codex and btca availability on startup
- **research-stop-hook** — Enforces source gate and reports resource usage on research completion
- **pre-commit-quality-gate** — Runs quality checks before commits

### Dual-Engine Architecture

Each reviewer agent independently:
1. Performs Claude-based domain review
2. Calls `ask-codex` MCP tool for Codex's perspective
3. Merges findings with classification (AGREE/CHALLENGE/COMPLEMENT)
4. Returns unified JSON with engine tags and cross-validation status

Cross-validated findings (flagged by both engines) receive a confidence boost — these are the highest-signal issues.

## Prerequisites

- **Claude Code** with plugin support
- **Codex CLI** (optional, for dual-engine mode): `npm i -g @openai/codex`
- **codex-mcp-server** is declared as an MCP dependency and installed automatically
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
