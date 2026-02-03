---
description: Create a lookup table for project and feature specifications
---

Create a new file in the current project - `./specs/README.md`.

This file will work as our lookup table and reference point for project and feature specifications.

- If the directory `specs/` already exists and contains specs, analyze the files and insert those into the lookup table.
- If there are no specifications right now, create an empty lookup table file.
- DO NOT insert any action or implementation plans - ephemeral files - into the lookup table!

For the `specs/README.md` file use the following template:

<template>
# {Project Name} Specs

Specification documents for the {project name} project.

> For additional documentation, see `./docs/`.

## Document Index

| Document                                   | Status | Purpose                                    |
| ------------------------------------------ | ------ | ------------------------------------------ |
| [example-feature.md](./example-feature.md) | Draft  | Brief description of what this spec covers |

## Status Legend

| Status      | Meaning                           |
| ----------- | --------------------------------- |
| Proposal    | Early idea, needs discussion      |
| Draft       | Being written, not finalized      |
| Ready       | Finalized, can be implemented     |
| Implemented | Built, spec documents what exists |

---

## Conventions

| Element   | Convention                                     |
| --------- | ---------------------------------------------- |
| Filename  | `kebab-case.md`                                |
| Status    | One of: Proposal → Draft → Ready → Implemented |
| Purpose   | Short, scannable (< 80 chars)                  |
| Directory | Flat structure, all specs in `specs/`          |

## Lifecycle

```
Proposal  →  Draft  →  Ready  →  Implemented
    ↑           ↑         |
    └───────────┴─────────┘
           (revisions)
```

## Workflow

1. **Create spec as Proposal/Draft** - Write down the problem, proposed solution
2. **Mark as Ready** - Spec is finalized, implementation can begin
3. **Implement the feature** - Use the spec as guide
4. **Mark as Implemented** - Spec now documents what exists
</template>
