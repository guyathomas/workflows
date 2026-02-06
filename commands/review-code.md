---
description: "Run the code-reviewer subagent to review completed work against your plan and coding standards."
argument-hint: "[description of what was implemented, or path to plan]"
---

Dispatch the `code-reviewer` agent as a subagent (using the Task tool with `subagent_type` set to `code-reviewer`).

Pass it the current git diff (`git diff HEAD`) and the list of changed files, along with this context from the user: $ARGUMENTS

The code-reviewer checks plan alignment, code quality, architecture, documentation, and identifies issues by severity (Critical / Important / Suggestions).
