# Workflows

Research, planning, and code review skills for Claude Code.

## What's Included

### Skills (3)

- **research** — Deep research with 20+ sources and confidence tracking, powered by agent teams
- **planning** — Pre-implementation planning that researches approaches using Context7, Serper, and GitHub MCPs
- **code-review-pipeline** — Multi-reviewer code review using agent teams (architecture, code, implementation, tech practices, tests, UI)

### Agents (6)

Specialized reviewers for the code-review-pipeline: architecture, code, implementation, tech practices, tests, and UI.

### Commands (8)

- `/research` — Start a deep research session
- `/code-review-pipeline` — Run the full review pipeline
- `/review-architecture`, `/review-code`, `/review-implementation`, `/review-tech-practices`, `/review-tests`, `/review-ui` — Individual review commands

### Hooks

- **session-start** — Announces available skills on startup
- **research-stop-hook** — Validates research output format
- **pre-commit-quality-gate** — Runs quality checks before commits
- **review-nudge-hook** — Reminds to run code review after implementation

### AGENTS.md Template

A comprehensive `AGENTS.md` / `CLAUDE.md` template covering project setup, decision protocol, development flow, code rules, testing, git conventions, and quality gates.

## Installation

### Claude Code (via Plugin Marketplace)

```bash
/plugin marketplace add guyathomas/workflows-marketplace
```

```bash
/plugin install workflows@workflows-marketplace
```

### Verify

```bash
/help
# Should list /workflows:research, /workflows:code-review-pipeline, etc.
```

## License

MIT — see [LICENSE](LICENSE)
