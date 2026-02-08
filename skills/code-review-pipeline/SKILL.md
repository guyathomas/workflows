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

Spawn all applicable reviewers as teammates in a single request. Use Sonnet for each teammate.

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

Wait for all teammates to complete their reviews before proceeding to AGGREGATE.
</phase>

<phase name="AGGREGATE">
1. Collect JSON responses from all reviewer teammates
2. Parse each response (if malformed, skip with warning)
3. **Filter:** Remove findings with `confidence < 80`
4. **Deduplicate:** If multiple reviewers flag the same file:line, keep the higher-confidence finding
5. **Group by severity:**
   - **Critical** — Must fix before proceeding
   - **High** — Should fix now
   - **Medium** — Suggestions worth considering
   - **Low** — Minor improvements

6. **Compile missing tests** list from all reviewers
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
**Files reviewed:** 5
**Findings:** 2 critical, 1 high, 3 medium, 1 low

### Fixed (Critical/High)
- [critical] src/auth.ts:42 — SQL injection via string interpolation → switched to parameterized query
- [high] src/api.ts:15 — Uncaught promise rejection → added try/catch

### Suggestions (Medium/Low)
| Severity | File | Line | Issue | Recommendation |
|---|---|---|---|---|
| medium | src/utils.ts | 23 | Potential null dereference | Add null check before access |
| low | src/config.ts | 8 | Magic number | Extract to named constant |

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
</error_handling>
