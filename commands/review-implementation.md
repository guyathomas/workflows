---
description: "Run the implementation-reviewer subagent to find bugs, logic errors, security issues, and error handling gaps."
argument-hint: "[optional focus area or file paths]"
---

Dispatch the `implementation-reviewer` agent as a subagent (using the Task tool with `subagent_type` set to `implementation-reviewer`).

First run `git diff HEAD` and `git diff --name-only HEAD` to get the diff and changed file list. Pass both to the subagent.

Additional context from the user: $ARGUMENTS
