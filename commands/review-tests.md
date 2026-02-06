---
description: "Run the test-reviewer subagent to find coverage gaps, test antipatterns, and missing test cases."
argument-hint: "[optional focus area or file paths]"
---

Dispatch the `test-reviewer` agent as a subagent (using the Task tool with `subagent_type` set to `test-reviewer`).

First run `git diff HEAD` and `git diff --name-only HEAD` to get the diff and changed file list. Pass both to the subagent.

Additional context from the user: $ARGUMENTS
