# Codex MCP-Native Integration

**Date:** 2026-03-07
**Status:** Approved

## Problem

Current Codex integration uses `run-engine.sh` (shell script) to background-launch `codex exec`, write prompt files to temp dirs, `wait` for completion, parse JSON output, then pass everything to a separate `core:synthesizer` agent. This is fragile, hard to debug, and adds unnecessary layers.

## Solution

Replace shell-based Codex invocation with `ask-codex` MCP tool from `@cexll/codex-mcp-server`. Each reviewer agent becomes a dual-engine reviewer — it does its own Claude analysis, calls `ask-codex` for a Codex second opinion, and returns merged findings. No synthesizer agent needed.

## Architecture

```
skill (orchestrator)
  └─ spawns Claude teammates (parallel)
       └─ each teammate:
            1. Claude review (as before)
            2. ask-codex MCP call (same diff, same domain)
            3. Match findings across engines
            4. Return merged JSON with engine tags
  └─ aggregates all teammate results
  └─ presents findings
```

## Changes

### Files Deleted
- `scripts/run-engine.sh` — replaced by `ask-codex` MCP tool
- `lib/escape-json.sh` — only used by session-start hook (inlined or removed)
- `agents/synthesizer.md` — synthesis distributed to each reviewer

### Files Modified

#### All 6 reviewer agents (`agents/review-*.md`)
- Add dual-engine instructions: do Claude review, call `ask-codex`, merge findings
- Add `classification`, `crossValidated`, `engines` fields to output format
- Model selection: `o3` for implementation/security, `gpt-5-codex` for others

#### `skills/code-review-pipeline/SKILL.md`
- Remove DISPATCH Step 0 (Codex pre-flight)
- Remove DISPATCH Step 1 (Codex background jobs via run-engine.sh)
- Remove DISPATCH Step 3 wait + Codex status reporting
- Remove AGGREGATE Steps 2, 5 (Codex collection, synthesizer invocation)
- Teammates return pre-merged findings; skill just aggregates
- Update summary format to show cross-validated findings

#### `skills/planning/SKILL.md`
- EVALUATE phase: call `ask-codex` directly instead of run-engine.sh
- Inline merge of Claude + Codex evaluations (no synthesizer agent)
- Use `@` file references for project context

#### `skills/research/SKILL.md`
- Research teammates call `ask-codex` for cross-validation per question
- Remove run-engine.sh Codex background job pattern
- Tag codex-only findings as hypotheses

#### `hooks/session-start.sh`
- Detect `ask-codex` MCP tool availability (check for codex-mcp-server)
- Fall back to `codex` binary detection
- Remove dependency on `escape-json.sh`

#### `.claude-plugin/plugin.json`
- Add `mcpServers` field declaring codex-mcp-server dependency

#### `README.md`
- Update to reflect MCP-native Codex integration

## Key Decisions

1. **Distributed synthesis** — each teammate merges its own findings (has domain context for semantic matching)
2. **Model selection per domain** — `o3` for deep reasoning, `gpt-5-codex` for speed
3. **Graceful degradation** — if `ask-codex` fails, teammate returns Claude-only findings
4. **`@` file references** — pass file paths to Codex instead of inlining content

## Output Format (per reviewer)

```json
{
  "agent": "implementation-reviewer",
  "engines": ["claude", "codex"],
  "filesReviewed": ["src/auth.ts"],
  "findings": [
    {
      "severity": "critical",
      "confidence": 95,
      "file": "src/auth.ts",
      "line": 42,
      "issue": "SQL injection via string interpolation",
      "recommendation": "Use parameterized query",
      "category": "security",
      "classification": "AGREE",
      "crossValidated": true,
      "engines": ["claude", "codex"]
    }
  ],
  "missingTests": [],
  "summary": "1 critical (cross-validated by both engines)"
}
```
