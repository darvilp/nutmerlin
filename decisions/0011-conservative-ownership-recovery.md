# ADR 0011: Permit explicit conservative ownership recovery

- Status: Superseded by ADR 0098
- Date: 2026-08-01

## Context

The ownership manifest is the normal authority for mutation and removal, but it may be lost or corrupted while NUTMerlin-created configuration and managed hook blocks remain. Treating every such case as permanently foreign is safe but makes interrupted-installation and metadata-loss recovery unnecessarily fragile. Guessing ownership from paths or process names could destroy administrator-owned state.

## Decision

NUTMerlin permits explicit, conservative ownership recovery.

- First installation generates a random, non-secret installation ID.
- The ownership manifest records the installation ID and managed artifact inventory.
- Managed standalone files and hook blocks carry exact NUTMerlin ownership markers associated with that installation ID where their formats safely permit it.
- A valid ownership manifest remains the normal ownership authority; reconstruction is never automatic.
- An explicit CLI recovery operation inspects only canonical artifact locations and shows the proposed recovered ownership set before confirmation.
- Recovery succeeds only when every discovered relevant artifact has consistent NUTMerlin ownership evidence and the same installation ID.
- Unmarked, conflicting, symlinked, unexpectedly located, copied, or materially drifted artifacts leave ownership ambiguous and are not mutated.
- Filenames, conventional directories, installed packages, and running process names are supporting diagnostics but never sufficient ownership proof.
- Recovery reconstructs ownership metadata only. It does not replace altered configuration, adopt foreign files, or claim package provenance.

## Consequences

- Managed formats need stable ownership-marker conventions and negative-path tests.
- Recovery can restore safe repair and uninstall behavior after limited metadata loss.
- Some partially damaged installations still require manual recovery because preserving uncertain administrator state takes precedence over convenience.
- The installation ID must be redacted only if diagnostics combine it with sensitive local details; it is not itself a credential.

## Rejected alternative

Manifest-only ownership would classify every missing or corrupt manifest as manual-recovery-only ambiguity. It is simpler, but provides no safe automated path even when all remaining artifacts carry mutually consistent project evidence.
