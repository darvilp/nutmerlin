# ADR 0097: Make the WebUI an optional version-matched component

- Status: Accepted
- Date: 2026-08-02

## Context

ADRs 0060 and 0082 define the Merlin WebUI as a curated adapter over the complete local management controller, but the reconciled P0 language implicitly bundled that adapter into every core installation. The Merlin/amtm ecosystem contains both bundled WebUIs and separately installed companion UIs. NUTMerlin's complete CLI, conservative ownership model, and fail-closed UI boundary make a separable component practical and avoid requiring firmware WebUI integration on a router that needs only the NUT service and CLI.

## Decision

NUTMerlin consists of a required core component and an optional WebUI component.

- The core component contains all NUT services, lifecycle and ownership management, persistent configuration and state, policy/executor authority, recovery behavior, and the complete local CLI. A core-only installation is a fully supported NUTMerlin installation.
- The WebUI component contains only the Merlin Addons API page, fixed service-event adapter, sanitized presentation assets, and transient nonce integration. It cannot be installed or operated without a healthy matching core component and introduces no standalone listener, management API, persistent authority, or alternate validation path.
- One canonical signed release manifest authenticates separate core and WebUI artifacts. The WebUI version and management schema must exactly match the active core version; cross-version operation is refused.
- First install installs the core only unless the administrator explicitly selects the WebUI. The core CLI may add or remove the WebUI later through the same authenticated, ownership-checked, journaled lifecycle used for other project artifacts.
- Removing the WebUI invalidates its outstanding nonces and removes only verified UI registration, web assets, and UI-specific transient state. It preserves NUT services, configuration, credentials, policies, journals, history, release trust, and CLI operation. Full core uninstall removes an installed WebUI as part of the existing clean-uninstall transaction.
- Updates preserve the selected component set. When the WebUI is installed, candidate activation stages and validates the exact matching WebUI with the core. If that artifact is absent or fails validation, the candidate cannot serve the old UI; the administrator must explicitly postpone the core update or approve WebUI removal. Unattended operation may remove it only with an operation-specific authorization.
- Rollback never combines a core and WebUI from different releases. An installed WebUI is restored only from the matching authenticated rollback slot; otherwise it remains absent and the CLI reports recovery guidance.
- Core platform support and release evidence do not depend on WebUI availability. Publication and support claims for the optional WebUI require their own host, simulated-Merlin, and exact-platform integration evidence.

ADR 0060 continues to control CLI completeness and milestone-scoped UI content. ADR 0082 continues to control browser authorization and exposure. ADR 0096 is narrowed so that the WebUI is an optional P0 component rather than part of the required safe core installation.

## Consequences

- Routers can run a smaller core-only installation without consuming an Addons API page or relying on firmware browser integration.
- UI installation, removal, update, rollback, ownership, and failure isolation become explicit lifecycle test cases.
- The release process produces and authenticates two version-locked artifacts without creating separate repositories, release channels, state models, or support identities.
- A WebUI fault or unavailable firmware integration cannot reduce an otherwise qualified core support claim.

## Rejected alternatives

Bundling the WebUI into every core installation is simpler and is used by established addons such as FlexQoS and YazFi, but unnecessarily couples core support and updates to an optional firmware surface. A separately versioned WebUI project or independent update channel would maximize decoupling but would create schema skew, duplicate trust and ownership, and split the product support boundary.
