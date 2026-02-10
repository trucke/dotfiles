---
description: VCS commit agent for generating and applying commits
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
    # jj commands
    "jj root*": allow
    "jj status*": allow
    "jj diff*": allow
    "jj log*": allow
    "jj commit*": allow
    "jj describe*": allow
    # git commands
    "git rev-parse*": allow
    "git status*": allow
    "git diff*": allow
    "git log*": allow
    "git add*": allow
    "git commit*": allow
---

VCS commit agent. Can read repository state and create commits using jj or git.
Follow the exact workflow provided in the invoking command.
