---
name: review
description: Creates an agent team of parallel multi-engine code reviewers on your git diff, aggregates findings by severity, and fixes critical/high issues. Each reviewer cross-validates with Codex (MCP) and Gemini (CLI). Run after implementing a feature or before committing.
---

<objective>
Orchestrate parallel code review using an agent team of specialist reviewers. Each reviewer performs its own Claude analysis and calls Codex (MCP) and Gemini (CLI) for cross-validation. Read the git diff, determine which reviewers to spawn as teammates based on file types, run them concurrently, aggregate findings, filter low-confidence noise, and act on results.
</objective>

<quick_start>
1. Run `/code-review-pipeline` after making code changes
2. Reviewers dispatch automatically based on file types
3. Each reviewer cross-validates findings with Codex (MCP) and Gemini (CLI)
4. Critical/high findings are fixed inline; medium/low reported as suggestions
</quick_start>

<when_to_use>
Use when:
- You've implemented a feature and want to catch issues before committing
- Before finalizing a branch or PR
- After a significant refactor
- User asks for a code review

Don't use when:
- Only config/docs changed (no code to review)
- Single-line trivial fix
</when_to_use>

<workflow>

<phase name="DIFF">
1. Run `git diff HEAD` to get the full diff (staged + unstaged)
2. Run `git diff --name-only HEAD` to get the list of changed files
3. Determine the repository root: run `git rev-parse --show-toplevel` to get the absolute path. This is required context for all teammates.
4. If no code files changed, report "No code changes to review" and stop
5. Classify changed files into categories:

| File pattern | Categories |
|---|---|
| `.svelte, .tsx, .jsx, .vue, .html, .css` | implementation, test, tech-practices, ui |
| `.ts, .js, .py, .rs, .go` | implementation, test, architecture, tech-practices, docs |
| New files, moved files, changed exports | architecture |
| Changed public API, config, env vars, CLI flags | docs |

5. The `implementation` reviewer is ALWAYS dispatched
6. **Check for a plan:** Look for plan context to pass to the plan-adherence reviewer. Repos accumulate multiple plans over time, so disambiguation matters — using the wrong plan produces bogus findings. Check these sources in priority order:
   - **Explicit argument** (highest priority): If the user passed plan context as an argument (e.g., `/code-review-pipeline "plan: ..."` or a plan slug/path), use that directly. Read the file if a path was given.
   - **Branch-matched plan**: List all `plans/*/state.json` with `"phase": "SELECTED"`. If the current git branch name contains a plan slug (e.g., branch `feat/user-auth` matches `plans/user-auth/`), use that plan. This is the most common case — branches are usually named after the feature they implement.
   - **Diff-matched plan**: If no branch match, compare changed file paths against each selected plan's scope (read `approaches.json` to understand what each plan covers). Pick the plan whose scope best overlaps with the changed files.
   - **`plan.md` or `PLAN.md`** in the repo root — use as fallback only if no `plans/` directory exists.
   - If multiple plans match equally or no plan is found, do NOT guess. Skip the plan-adherence reviewer and note "Multiple plans found, pass a plan slug to disambiguate" or "No matching plan found".
   If plan context is found, add `plan-adherence` to the category set and store the plan content to pass to the reviewer.
7. Deduplicate categories into a set of reviewers to dispatch
</phase>

<phase name="DISPATCH">
Create an agent team to run specialist reviewers in parallel. Each reviewer runs as an independent teammate with its own context window. Each reviewer independently calls Codex (MCP) and Gemini (CLI) for cross-validation.

**Dispatch map:**

| Category | Teammate role | Condition |
|---|---|---|
| implementation | `core:review-implementation` | Always |
| test | `core:review-tests` | Source files (not just tests) changed |
| architecture | `core:review-architecture` | New/moved files, or changed exports detected |
| tech-practices | `core:review-tech-practices` | Framework-specific files in diff |
| ui | `core:review-ui` | UI component files in diff |
| docs | `core:review-docs` | Source files changed (not just tests/docs) |
| plan-adherence | `core:review-plan-adherence` | Plan context found (from `plans/`, `plan.md`, or arguments) |

**Announce:** `"Dispatching reviewers: {list}. Each reviewer will cross-validate with Codex (MCP) and Gemini (CLI)."`

Spawn all applicable reviewers as teammates in a single request. Use Opus for each teammate.

For EACH teammate, provide:
1. The reviewer role name (from the dispatch map)
2. The full git diff
3. The list of files relevant to that reviewer
4. The **repository root path** (from `git rev-parse --show-toplevel`)
5. Instructions to return JSON in the standard output format

**Instructions for each teammate:**

```
You are a {reviewer-role} teammate. Review the following code changes. Return your findings as JSON.

## Repository root
{repo_root}

## Changed files
{file_list}

## Diff
{diff_content}

When calling the codex tool, pass `cwd: "{repo_root}"` and use repo-relative @ file references.
```

**For the plan-adherence reviewer only**, also include:
```
## Plan context
{plan_content}
```
Where `{plan_content}` is the plan text discovered in the DIFF phase (the selected approach JSON, markdown plan, or user-provided plan text).

Each teammate will:
1. Perform their Claude-based domain review
2. Call `codex` MCP tool for Codex cross-validation (with `cwd` set to the repo root)
3. Validate the Codex response before merging — empty, non-JSON, or error-text responses mean Codex-unavailable
4. Call Gemini CLI for Gemini cross-validation via Bash (`gemini -p "..." -m gemini-2.5-pro -o json --approval-mode plan`)
5. Validate Gemini response — extract `.response` from JSON envelope, parse as JSON; empty, non-JSON, or error-text means Gemini-unavailable
6. Merge findings from all available engines with classification (AGREE/CHALLENGE/COMPLEMENT)
7. Return unified JSON with engine tags
</phase>

<phase name="AGGREGATE">
1. Collect JSON responses from all reviewer teammates
2. Parse each response (if malformed, skip with warning)
3. **Filter:** Remove findings with `confidence < 80`
4. **Group by severity** from teammate outputs:
   - **Critical** — Must fix before proceeding
   - **High** — Should fix now
   - **Medium** — Suggestions worth considering
   - **Low** — Minor improvements
5. **Highlight cross-validated findings** — findings with `crossValidated: true` are high-signal (confirmed by 2+ engines)
6. **Compile missing tests** list from all teammates
7. **Compile stale docs** from docs reviewer findings — list doc files with staleness issues
8. **Surface plan adherence** — if the plan-adherence reviewer returned `planAdherence`, include completeness score, deviation summary, and scope creep items in the report
</phase>

<phase name="ACT">
Based on aggregated findings:

### Critical and High findings
For each critical/high finding:
1. Read the file at the specified line
2. Apply the recommendation to fix the issue
3. Report what was fixed

### Medium and Low findings
Report as suggestions in a summary table:

```
## Review Summary

**Reviewers dispatched:** implementation, test, ui (Opus, multi-engine)
**Files reviewed:** 5
**Findings:** 2 critical, 1 high, 3 medium, 1 low
**Cross-validated:** 2 findings confirmed by 2+ engines

### Cross-Validated (flagged by multiple engines)
- [critical] src/auth.ts:42 — SQL injection via string interpolation (AGREE)
- [high] src/api.ts:15 — Uncaught promise rejection (AGREE)

### Fixed (Critical/High)
- [critical] src/auth.ts:42 — SQL injection via string interpolation -> switched to parameterized query
- [high] src/api.ts:15 — Uncaught promise rejection -> added try/catch

### Suggestions (Medium/Low)
| Severity | Agent | File | Line | Issue | Recommendation | Engines |
|---|---|---|---|---|---|---|
| medium | implementation | src/utils.ts | 23 | Potential null dereference | Add null check | claude |
| medium | implementation | src/utils.ts | 25 | Missing boundary check | Validate input range | codex |
| low | architecture | src/config.ts | 8 | Magic number | Extract to named constant | claude, codex, gemini |

### Plan Adherence
**Plan:** plans/feature-slug (Approach 1: "Name")
**Completeness:** 4/5 items implemented
- [x] JWT authentication middleware
- [x] Route protection
- [ ] Token refresh endpoint (**missing**)
**Deviations:** 1 justified (middleware instead of decorator)
**Scope creep:** None

### Stale Documentation
- [high] README.md:42 — `AUTH_SECRET` env var renamed to `JWT_SECRET`
- [medium] docs/api.md:15 — Missing `/auth/refresh` endpoint from API reference

### Missing Tests
- Test error path when fetchUser throws in src/auth.ts:42
- Test empty array input in src/utils.ts:23
```

If no findings above confidence threshold: report "Review complete — no issues found."
</phase>

</workflow>

<error_handling>
| Error | Action |
|---|---|
| Teammate returns malformed JSON | Log warning, continue with other teammates |
| Teammate times out | Log warning, continue with other teammates |
| No git diff available | Report "No changes to review" and stop |
| All teammates fail | Report error, suggest running individual reviewer manually |
| `codex` unavailable in teammate | Teammate returns findings without Codex (`"engines"` omits `"codex"`), pipeline continues |
| `codex` returns empty or error text | Same as unavailable — teammate returns findings without Codex, pipeline continues |
| `gemini` CLI unavailable in teammate | Teammate returns findings without Gemini (`"engines"` omits `"gemini"`), pipeline continues |
| `gemini` returns empty, non-JSON `.response`, or error text | Same as unavailable — teammate returns findings without Gemini, pipeline continues |
</error_handling>
