---
name: code-review-pipeline
description: Creates an agent team of parallel code reviewers on your git diff, aggregates findings by severity, and fixes critical/high issues. Run after implementing a feature or before committing.
---

<objective>
Orchestrate parallel code review using an agent team of specialist reviewers. Read the git diff, determine which reviewers to spawn as teammates based on file types, run them concurrently, aggregate findings, filter low-confidence noise, and act on results.
</objective>

<quick_start>
1. Run `/code-review-pipeline` after making code changes
2. Reviewers dispatch automatically based on file types
3. Critical/high findings are fixed inline; medium/low reported as suggestions
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
3. If no code files changed, report "No code changes to review" and stop
4. Classify changed files into categories:

| File pattern | Categories |
|---|---|
| `.svelte, .tsx, .jsx, .vue, .html, .css` | implementation, test, tech-practices, ui |
| `.ts, .js, .py, .rs, .go` | implementation, test, architecture, tech-practices |
| New files, moved files, changed exports | architecture |

5. The `implementation` reviewer is ALWAYS dispatched
6. Deduplicate categories into a set of reviewers to dispatch
</phase>

<phase name="DISPATCH">
Create an agent team to run specialist reviewers in parallel. Each reviewer runs as an independent teammate with its own context window.

**Dispatch map:**

| Category | Teammate role | Condition |
|---|---|---|
| implementation | `implementation-reviewer` | Always |
| test | `test-reviewer` | Source files (not just tests) changed |
| architecture | `architecture-reviewer` | New/moved files, or changed exports detected |
| tech-practices | `tech-practices-reviewer` | Framework-specific files in diff |
| ui | `ui-reviewer` | UI component files in diff |

**Step 1 — Launch Codex background reviews:**

Before spawning teammates, launch Codex reviews as background processes for each reviewer type in the dispatch set:

```bash
# For each reviewer type (e.g., implementation, test, architecture):
./scripts/codex-domain-review.sh <domain> /tmp/codex-<domain>-$$.json &
```

The script runs `git diff main` internally — no diff file or file list needed. If `codex` is not installed, the script writes a skip-marker and exits cleanly. These run in the background alongside the Claude agent team with no added latency.

**Step 2 — Spawn Claude agent teammates:**

Spawn all applicable reviewers as teammates in a single request. Use Opus for each teammate.

For EACH teammate, provide:
1. The reviewer role name (from the dispatch map)
2. The full git diff
3. The list of files relevant to that reviewer
4. Instructions to return JSON in the standard output format

**Instructions for each teammate:**

```
You are a {reviewer-role} teammate. Review the following code changes. Return your findings as JSON.

## Changed files
{file_list}

## Diff
{diff_content}
```

**Step 3 — Wait for all:**

1. `wait` for all background codex processes to finish
2. Wait for Claude teammates to complete (may already be done)
</phase>

<phase name="AGGREGATE">
1. Collect JSON responses from all reviewer teammates (Claude agents)
2. Collect JSON output files from all codex reviews (`/tmp/codex-<domain>-$$.json`)
   - Skip any file whose summary starts with "skipped" (codex unavailable/timed out)
3. Merge all findings into a single array
4. Parse each response (if malformed, skip with warning)
5. **Filter:** Remove findings with `confidence < 80`
6. **Cross-validate:** If a Claude reviewer AND a Codex reviewer both flag the same file:line (within 3 lines), mark those findings as `"crossValidated": true` — this is a strong signal
7. **Deduplicate:** If multiple reviewers flag the same file:line with the same issue, keep the higher-confidence finding but preserve the cross-validated flag
8. **Group by severity:**
   - **Critical** — Must fix before proceeding
   - **High** — Should fix now
   - **Medium** — Suggestions worth considering
   - **Low** — Minor improvements

9. **Compile missing tests** list from all reviewers
10. **Cleanup:** Remove temp files (`/tmp/codex-*-$$.json`)
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

**Reviewers:** implementation, test, ui
**Codex reviewers:** codex-implementation, codex-test, codex-ui
**Files reviewed:** 5
**Findings:** 2 critical, 1 high, 3 medium, 1 low (1 cross-validated)

### Cross-Validated (flagged by both Claude and Codex)
- [critical] src/auth.ts:42 — SQL injection via string interpolation (implementation-reviewer + codex-implementation)

### Fixed (Critical/High)
- [critical] src/auth.ts:42 — SQL injection via string interpolation → switched to parameterized query
- [high] src/api.ts:15 — Uncaught promise rejection → added try/catch

### Suggestions (Medium/Low)
| Severity | Agent | File | Line | Issue | Recommendation |
|---|---|---|---|---|---|
| medium | implementation-reviewer | src/utils.ts | 23 | Potential null dereference | Add null check before access |
| medium | codex-implementation | src/utils.ts | 25 | Missing boundary check | Validate input range |
| low | codex-architecture | src/config.ts | 8 | Magic number | Extract to named constant |

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
| Codex CLI not available | Script writes skip-marker JSON, pipeline proceeds Claude-only |
| Codex returns malformed JSON | Script wraps raw output, AGGREGATE skips with warning |
| Codex hangs | `timeout 120` kills process, script writes skip-marker JSON |
</error_handling>
