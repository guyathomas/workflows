---
description: "Check implementation completeness and adherence against the selected plan."
argument-hint: "[plan slug, plan file path, or plan text]"
context: fork
disable-model-invocation: false
---

Review the following code changes against the selected plan. Return your findings as JSON following the `core:review-plan-adherence` agent definition.

## Repository root
!`git rev-parse --show-toplevel`

## Changed files
!`git diff --name-only HEAD`

## Diff
!`git diff HEAD`

## Plan context

Resolve the plan from the argument below. The argument may be:
- A **plan slug** (e.g., `user-auth`) → read `plans/{slug}/approaches.json` and `plans/{slug}/state.json` to get the selected approach
- A **file path** (e.g., `plans/user-auth/approaches.json` or `plan.md`) → read the file contents
- **Inline plan text** → use as-is
- **Empty** → try to auto-discover: list `plans/*/state.json` files, find ones with `"phase": "SELECTED"`, match against the current branch name or changed files. If ambiguous or none found, report that no plan could be resolved.

User argument: $ARGUMENTS
