---
description: "Run the architecture-reviewer subagent to check structural integrity, pattern consistency, and coupling."
argument-hint: "[optional focus area or file paths]"
---

Dispatch the `architecture-reviewer` agent as a subagent (using the Task tool with `subagent_type` set to `architecture-reviewer`).

First run `git diff HEAD` and `git diff --name-only HEAD` to get the diff and changed file list. Pass both to the subagent.

Additional context from the user: $ARGUMENTS
