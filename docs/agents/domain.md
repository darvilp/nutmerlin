# Domain docs

This is a single-context v0.1 repository. Engineering skills consume its domain documentation as follows.

## Before exploring, read these

- **`CONTEXT.md`** at the repository root when it exists.
- **`requirements.md`** for normative product behavior.
- **`decisions/README.md`** for the only ADRs active in v0.1.
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

The canonical ADR directory is `decisions/`. Historical and deferred ADRs remain there but are non-authoritative unless the index lists them active. Do not create a second ADR hierarchy under `docs/adr/`.

## Use the glossary’s vocabulary

When output names a domain concept—in an issue title, design proposal, hypothesis, or test name—use the term defined in `CONTEXT.md`. Do not drift to synonyms the glossary explicitly avoids.

If a needed concept is absent, either reconsider whether the term belongs to the project or record the gap for the domain-modeling workflow.

## Flag ADR conflicts

If proposed work contradicts an active ADR, surface the conflict explicitly instead of silently overriding it. Historical and deferred ADRs may inform research but do not constrain v0.1.

For example:

> _Contradicts `decisions/0007-storage-durability.md`; reopening this decision would require explicit review._
