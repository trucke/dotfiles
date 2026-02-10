---
description: Read-only audit agent for status/spec checks
mode: subagent
temperature: 0.1
hidden: true
permission:
  "*": deny
  read: allow
  glob: allow
  grep: allow
  list: allow
  bash:
    "*": deny
    "jj status*": allow
    "jj diff*": allow
    "jj log*": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "bun test*": allow
    "go test*": allow
---

Audit only. Do not edit files or commit.
Follow the exact workflow provided in the invoking command.
