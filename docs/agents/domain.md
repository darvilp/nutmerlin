# Domain Docs

This is a single-context repository. The engineering skills should consume its domain documentation as follows.

## Before exploring, read these

- **`CONTEXT.md`** at the repository root when it exists.
- **`decisions/`** for ADRs relevant to the area being examined.
- **`AGENTS.md`** for repository-wide safety and contributor instructions.

If `CONTEXT.md` does not yet exist, proceed silently. Do not create placeholder terminology. The domain-modeling workflow should create or update it when project vocabulary is actually resolved.

## Canonical layout

```text
/
├── AGENTS.md
├── CONTEXT.md
├── decisions/
│   ├── 0001-name-and-scope.md
│   └── ...
└── docs/
    └── agents/
```

The canonical ADR directory is `decisions/`. Do not create a second ADR hierarchy under `docs/adr/`, and do not relocate existing ADRs unless a repository-wide decision explicitly changes this layout.

## Use the glossary’s vocabulary

When output names a domain concept—in an issue title, design proposal, hypothesis, or test name—use the term defined in `CONTEXT.md`. Do not drift to synonyms the glossary explicitly avoids.

If a needed concept is absent, either reconsider whether the term belongs to the project or record the gap for the domain-modeling workflow.

## Flag ADR conflicts

If proposed work contradicts an existing ADR, surface the conflict explicitly instead of silently overriding it.

For example:

> _Contradicts `decisions/0007-storage-durability.md`; reopening this decision would require explicit review._
