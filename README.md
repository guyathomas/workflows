# Amux

Research, planning, and code review skills for Claude Code with dual-engine cross-validation (Claude + Codex).

## What's Included

### Skills (3)

- **research** — Deep research with 20+ sources and confidence tracking, powered by agent teams with Codex cross-validation
- **planning** — Pre-implementation planning that researches approaches using Context7, Serper, GitHub MCPs, and optionally btca for source-level codebase research, with dual-engine evaluation via Codex MCP. Once an approach is selected, a multi-agent (Claude + Codex) REVIEW-PLAN step stress-tests the plan for gaps and risks, then a BUILD-PLAN step writes a PRD broken into TDD-gated vertical slices — each gate opens with failing tests and closes only when lint, format, test, and build pass — before any code is written.
- **code-review-pipeline** — Multi-reviewer code review using agent teams (code, tests, docs), each cross-validated with Codex. The skill owns the dual-engine collaboration standard and the suggested-tools menu, injecting both into every reviewer.

### Agents (4)

**Pipeline reviewers (3):** dispatched by the code-review-pipeline skill based on what the change needs.
- **code** — the generalist: bugs, logic, security, error handling, structure (coupling/cohesion/API surface), and framework best-practices in one pass
- **tests** — coverage gaps, test antipatterns, missing cases
- **docs** — documentation staleness

**Standalone reviewer (1):** **review-code** — reviews completed work against the original plan and coding standards. Invoked via `/review-code`; carries its own self-contained cross-validation since it runs outside the pipeline.

### Commands (4)

- `/research` — Start a deep research session
- `/planning` — Plan a non-trivial feature before implementation
- `/code-review-pipeline` — Run the full review pipeline
- `/review-code` — Standalone plan-alignment + standards review

### Hooks

- **session-start** — Announces available skills and detects Codex CLI presence (note: CLI presence does not guarantee MCP usability)
- **task-loop-hook** — Generic task loop that blocks exit while any skill's `task-loop.json` has `complete: false`. Used by research (and available for future long-running skills).
- **pre-commit-quality-gate** — Runs quality checks before commits

### Dual-Engine Architecture

The collaboration standard is defined once in the code-review-pipeline skill and injected into every reviewer's task context, so each agent definition stays thin. Following that standard, each reviewer independently:
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
