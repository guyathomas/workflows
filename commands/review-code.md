---
description: "Review completed work against your plan and coding standards."
argument-hint: "[description of what was implemented, or path to plan]"
context: fork
agent: code-reviewer
disable-model-invocation: true
---

Review the following code changes against the plan and coding standards.

## Changed files
!`git diff --name-only HEAD`

## Diff
!`git diff HEAD`

## Additional context
$ARGUMENTS
