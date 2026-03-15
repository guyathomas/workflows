---
description: "Check implementation completeness and adherence against the selected plan."
argument-hint: "[optional plan slug or file paths]"
context: fork
agent: plan-adherence-reviewer
disable-model-invocation: true
---

Review the following code changes against the selected plan. Return your findings as JSON.

## Repository root
!`git rev-parse --show-toplevel`

## Changed files
!`git diff --name-only HEAD`

## Diff
!`git diff HEAD`

## Additional context
$ARGUMENTS
