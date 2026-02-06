---
description: "Run the ui-reviewer subagent to check WCAG accessibility, keyboard navigation, and UX patterns."
argument-hint: "[optional focus area or file paths]"
---

Dispatch the `ui-reviewer` agent as a subagent (using the Task tool with `subagent_type` set to `ui-reviewer`).

First run `git diff HEAD` and `git diff --name-only HEAD` to get the diff and changed file list. Pass both to the subagent.

Additional context from the user: $ARGUMENTS
