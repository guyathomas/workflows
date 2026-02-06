---
description: "Run the tech-practices-reviewer subagent to check framework-specific best practices and deprecated APIs."
argument-hint: "[optional focus area or file paths]"
---

Dispatch the `tech-practices-reviewer` agent as a subagent (using the Task tool with `subagent_type` set to `tech-practices-reviewer`).

First run `git diff HEAD` and `git diff --name-only HEAD` to get the diff and changed file list. Pass both to the subagent.

Additional context from the user: $ARGUMENTS
