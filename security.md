# NUTMerlin security model

## 1. Security objectives

- Do not weaken the router's default network perimeter.
- Minimize privileged code and credentials.
- Make safe monitoring easy and destructive control difficult.
- Prevent the web UI from becoming a general remote-code execution surface.
- Keep power events and actions auditable without leaking secrets.
- Fail without disrupting core router functions.

## 2. Trust boundaries

```text
WAN / internet                  untrusted
Guest Wi-Fi / untrusted VLANs   untrusted by default
Trusted LAN                     limited trust
Router web administrator        privileged
NUT clients                     read/monitor role unless explicitly elevated
Executor targets                separate trust domains
Entware storage                 persistent but removable
UPS USB device                  hardware input; data may be stale or incorrect
```

## 3. Principal threats

| Threat | Example |
|---|---|
| Network exposure | `upsd` listens on WAN or guest interface |
| Credential theft | SSH key/token rendered in UI or logs |
| Command injection | Hostname or command field reaches shell unquoted |
| CSRF/privileged UI abuse | Authenticated browser triggers unsafe action |
| Supply-chain compromise | Installer/update download is altered |
| Malicious/buggy executor | Arbitrary command or excessive retries |
| UPS data spoofing/fault | False low-battery state triggers shutdown |
| Configuration takeover | Existing manual NUT config overwritten |
| Storage removal | `/opt` disappears during operation |
| Router compromise amplification | Stored keys provide control of every host |
| Denial of service | Polling/logging consumes router resources |
| Unsafe power control | UPS/PDU or Redfish force-off invoked accidentally |

## 4. Required controls

### 4.1 Network binding

- Bind `upsd` to explicit trusted LAN addresses.
- Add firewall rules that deny WAN, guest, and untrusted VLAN access.
- Reapply rules after firewall restart.
- Detect broad listeners such as `0.0.0.0` and require an explicit expert override.
- Do not provide automatic internet exposure, port forwarding, or cloud tunneling.

### 4.2 NUT roles

Separate:

- read-only status access
- `upsmon` client role
- NUT primary/FSD role
- administrative `SET`/instant-command role

Administrative roles are disabled by default. Do not grant `ALL` commands casually.

### 4.3 Secret storage

- Store secrets in dedicated files under `/opt/etc/nutmerlin/secrets` or another verified persistent private directory.
- Mode: owner read/write only where supported.
- Keep secrets out of:
  - `custom_settings.txt`
  - JavaScript
  - HTML
  - URLs
  - logs
  - diagnostics bundles
  - normal command lines
  - source control
- Redact known secret field names and executor-specific headers.
- Do not include secrets in settings export.

### 4.4 Shell safety

- Use fixed commands and validated structured arguments.
- Never use `eval`.
- Never concatenate untrusted input into shell code.
- Avoid `sh -c` for executor invocation.
- Validate identifiers against strict patterns.
- Validate IP addresses and ports.
- Normalize and allowlist file paths.
- Use `--` where commands support it.
- Quote every variable expansion.
- Use temporary files with safe permissions and unpredictable names.

### 4.5 UI safety

- Use authenticated Merlin UI and service-event path.
- Encode all rendered values.
- Validate again server-side; JavaScript validation is not sufficient.
- Do not expose arbitrary command fields.
- Place expert/destructive controls behind a separate page or explicit feature gate.
- Require typed confirmation for future output-off or force-off operations.
- Do not return private key material through status endpoints.

### 4.6 SSH executor

Defaults:

- key authentication only
- host-key verification required
- dedicated key per NUTMerlin deployment or target group
- no agent forwarding
- no port forwarding
- no PTY
- restricted source address on the target
- forced command wrapper where possible
- dedicated low-privilege target account with only shutdown capability

Example target authorization concept:

```text
from="<router-LAN-IP>",no-agent-forwarding,no-port-forwarding,no-pty,command="/usr/local/sbin/nutmerlin-shutdown"
```

The router should store no general-purpose administrator key when a restricted target account is possible.

### 4.7 Webhook executor

- HTTPS certificate verification on by default.
- Explicit opt-in for private/self-signed CAs through installed trust material, not `-k`.
- Bounded connect and total timeouts.
- Redirects disabled or constrained.
- Optional HMAC signing.
- Header/token redaction.
- Destination allowlist or explicit administrator configuration.
- Prevent access to router-local administrative endpoints by default to reduce SSRF risk.

### 4.8 MQTT executor

- TLS when traffic leaves a trusted local segment.
- Explicit retained-message configuration.
- Separate publish and subscribe privileges.
- Topic prefix scoped to the deployment.
- Do not treat unauthenticated MQTT commands as authorization for destructive action.

### 4.9 WinRM executor

Backlog requirements:

- prefer HTTPS
- no Basic authentication over plaintext
- dedicated constrained endpoint/JEA where feasible
- certificate/host verification
- least-privilege shutdown permission
- no reusable domain administrator credentials

### 4.10 Redfish executor

Backlog requirements:

- dedicated BMC account
- TLS verification
- capability query before action
- prefer `GracefulShutdown`
- verify power-state transition
- `ForceOff` disabled by default
- escalation requires explicit policy, timeout, and dual opt-in
- rate limit and audit every action
- never expose BMC credentials to general NUT clients

### 4.11 UPS/PDU output control

- Disabled in early releases.
- Discover and show capabilities without enabling them.
- Require device-specific allowlist.
- Require global feature gate plus action-specific gate.
- Provide a simulation/dry-run.
- Warn that all connected equipment may lose power.
- Never run automatically as part of ordinary client-local onboarding.



### 4.12 Legacy router isolation

The optional RT-AC3100 runs an end-of-life Merlin branch and is test equipment only.

- WAN port unused.
- No remote administration.
- No port forwarding to the device.
- Internet egress blocked after deliberate setup/update windows.
- LAN administration restricted to trusted hosts.
- Unneeded ASUS services disabled.
- No production-only secrets stored on the legacy router.
- A compromise of the legacy target must not provide reusable credentials for the production RT-AX86U Pro.

### 4.13 Storage integrity

- Treat Entware media as fallible and replaceable.
- Do not store the only copy of configuration or keys on the router drive.
- Avoid high-frequency persistent writes.
- Detect read-only mounts and I/O failures.
- Do not execute scripts or configuration from a filesystem that failed integrity checks.
- Keep production and legacy-router deployment keys separate.

## 5. Policy safety

### Reversible policy

May cancel when utility returns. Appropriate for delayed workstation shutdown.

### Committed policy

Does not cancel after the commit boundary. Appropriate for FSD or a critical low-battery sequence.

The UI and logs must make the distinction explicit.

Additional controls:

- event debounce
- one action per event episode
- bounded retry
- maximum action rate
- monotonic timer
- no action on unknown/stale contradictory state
- explicit behavior after service/router restart
- target exclusions for router, ONT, ISP gateway, and critical network equipment

## 6. Update and installer security

- Prefer HTTPS release retrieval.
- Publish SHA-256 hashes or signatures.
- Verify before activation.
- Stage update in a temporary directory.
- Validate file list and permissions.
- Keep last known-good version.
- Avoid executing remote content directly through a pipe.
- Installer must display and record version/source.
- Do not automatically join AMTM or another catalog without a stable maintenance and update model.

## 7. Logging and privacy

Log enough to diagnose actions:

- event and state
- policy ID
- target ID
- executor
- result
- timestamps
- retries
- redacted errors

Do not log:

- passwords
- tokens
- private keys
- full authorization headers
- sensitive command output
- unnecessary device serial numbers in public diagnostic bundles

Logs must be bounded and preferably written to `/opt`, not frequently to JFFS.

## 8. Security test cases

- WAN cannot reach port 3493.
- Guest VLAN cannot reach port 3493.
- Listener change removes obsolete firewall access.
- Malicious hostname/username/path cannot inject shell.
- UI output encodes HTML/JavaScript characters.
- Settings export contains no secrets.
- Logs redact secrets after both success and failure.
- SSH rejects changed host key.
- Webhook rejects invalid TLS certificate by default.
- Retry storms are bounded.
- Stale UPS data does not trigger default shutdown.
- FSD cannot be started from the ordinary status page.
- Redfish `ForceOff` remains unavailable without dual opt-in.
- Uninstall removes firewall and hook modifications.
