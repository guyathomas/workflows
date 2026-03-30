---
description: "Check whether documentation is up-to-date with code changes."
argument-hint: ""
context: fork
disable-model-invocation: false
---

Review the following code changes and check whether any existing documentation is now stale. Return your findings as JSON following the `core:review-docs` agent definition.

## Repository root
!`git rev-parse --show-toplevel`

## Changed files
!`git diff --name-only HEAD`

## Diff
!`git diff HEAD`
