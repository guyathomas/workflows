---
description: "Find coverage gaps, test antipatterns, and missing test cases in code changes."
argument-hint: "[optional focus area or file paths]"
context: fork
agent: test-reviewer
disable-model-invocation: true
---

Review the following code changes. Return your findings as JSON.

## Changed files
!`git diff --name-only HEAD`

## Diff
!`git diff HEAD`

## Additional context
$ARGUMENTS
