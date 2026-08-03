# WinRM router client-stack qualification

> Historical research only. This document is non-authoritative for v0.1; WinRM execution is deferred.

Date: 2026-08-02

## Question and safety boundary

Can the current supported Entware feed provide a reproducible, maintainable
router-side WinRM client cohort that uses verified HTTPS and invokes only a
dedicated non-administrator JEA-equivalent endpoint?

This investigation inspected the current package catalog and specifications.
It did not install a package, use `pip`, build or vendor a private component,
implement WS-Man or an authentication protocol, contact a Windows host, use a
credential, change `TrustedHosts`, configure a listener or endpoint, or request
a host shutdown.

## Result: reproducible no-go for the current supported feed

No qualified WinRM cohort exists in the current supported Entware feed.
Consequently the WinRM capability remains **unavailable** under
[ADR 0076](../decisions/0076-gate-winrm-on-a-qualified-client-stack.md) and does
not block the safe core release under
[ADR 0096](../decisions/0096-freeze-milestones-around-the-safe-nut-core.md).

The exact catalog evaluated was:

| Field | Observed value |
| --- | --- |
| Feed | Entware AArch64 3.10 |
| Configured feed URL | `http://bin.entware.net/aarch64-k3.10` |
| Catalog provenance URL | `https://bin.entware.net/aarch64-k3.10/Packages` |
| Package architecture | `aarch64-3.10` |
| Retrieved | 2026-08-02 |
| Last-Modified | `2026-06-27T18:00:59Z` |
| Bytes | `1659256` |
| SHA-256 | `b1f04218d93d967d79fdf8d58badd759c3fd44dda4edeb2d68670f9fbbff1283` |

The feed has no package, virtual provider, or package description for WinRM,
WS-Man, OpenWSMan, `pywinrm`, `requests-ntlm`, or PowerShell. There is therefore
no WinRM root package from which an exact transitive dependency closure can be
constructed, no packaged WS-Man request/response implementation to qualify,
and no packaged WinRM authentication behavior to exercise.

The catalog does contain generic pieces, but they are not a client cohort:

| Package | Exact version | Catalog dependency record | Why it is insufficient |
| --- | --- | --- | --- |
| `curl` | `8.15.0-2` | `libc, libssp, librt, libpthread, libcurl` | URL-transfer client; no packaged WS-Man operation contract |
| `libcurl` | `8.15.0-2` | `libc, libssp, librt, libpthread, libopenssl, zlib, libnghttp2, ca-bundle` | HTTPS transport does not supply a WS-Man client or establish a supported WinRM authentication profile |
| `python3` | `3.13.9-2` | `libc, libssp, librt, libpthread, python3-light, python3-asyncio, python3-codecs, python3-ctypes, python3-dbm, python3-decimal, python3-email, python3-logging, python3-lzma, python3-multiprocessing, python3-ncurses, python3-openssl, python3-pydoc, python3-readline, python3-sqlite3, python3-unittest, python3-urllib, python3-uuid, python3-xml` | Runtime alone; the feed lacks `pywinrm` and `requests-ntlm` |
| `python3-requests` | `2.32.5-1` | `libc, libssp, librt, libpthread, python3-light, python3-chardet, python3-idna, python3-urllib3, python3-certifi` | Generic HTTP client; no WS-Man or accepted WinRM authentication package |
| `python3-cryptography` | `46.0.5-1` | `libc, libssp, librt, libpthread, libopenssl, libopenssl-legacy, python3-cffi, python3-email, python3-urllib, python3-uuid` | Cryptographic primitives do not provide WS-Man or a WinRM client |
| `python3-lxml` | `6.0.2-1` | `libc, libssp, librt, libpthread, libxml2, libxslt, libexslt, python3-light` | XML processing alone would require NUTMerlin to implement WS-Man |
| `krb5-libs` | `1.22.1-1` | `libc, libssp, librt, libpthread, libncurses, libss, libcomerr` | Libraries alone do not provide or qualify a WinRM client, and a domain/Kerberos profile is separately gated |
| `libneon` | `0.32.4-1` | `libc, libssp, librt, libpthread, libopenssl, libexpat, zlib` | Generic HTTP/WebDAV library; no packaged WS-Man client contract |
| `libserf` | `1.3.10-2` | `libc, libssp, librt, libpthread, libopenssl, libaprutil, unixodbc` | Generic HTTP library; no packaged WS-Man client contract |

Combining these pieces would require NUTMerlin to own WS-Man message creation,
parsing, authentication integration, fault handling, and interoperability. That
is the homegrown protocol stack expressly prohibited by ADR 0076. Installing
the missing Python packages from PyPI would instead create the prohibited
mutable runtime dependency. Samba libraries or an `ntlm_auth` helper likewise
do not supply a reviewed WS-Man client and would not turn generic transport
parts into one.

Because the mandatory router-client gate fails, the Windows-target phase was
not entered. A disposable Windows VM cannot demonstrate end-to-end verified
HTTPS or constrained-endpoint invocation when there is no permitted client to
run on the router side. This is a no-go at an earlier qualification gate, not
negative evidence about whether a particular Windows edition can host a safe
JEA endpoint. No production desktop was substituted for a disposable target.

## Reproduction

Run this from a host with `curl`, `sha256sum`, and POSIX `awk`. The checksum is a
control-flow gate, so changed feed metadata becomes new qualification evidence
instead of silently changing the result.

```sh
set -eu
index_file=$(mktemp)
trap 'rm -f "$index_file"' EXIT HUP INT TERM

curl -fsS --connect-timeout 15 --max-time 120 -o "$index_file" \
  https://bin.entware.net/aarch64-k3.10/Packages
printf '%s  %s\n' \
  b1f04218d93d967d79fdf8d58badd759c3fd44dda4edeb2d68670f9fbbff1283 \
  "$index_file" | sha256sum -c -
[ "$(wc -c <"$index_file")" -eq 1659256 ]

awk '
  BEGIN { RS=""; FS="\n"; found=0 }
  {
    package=""
    for (i=1; i<=NF; i++) {
      if ($i ~ /^Package: /) package=substr($i, 10)
    }
    record=tolower($0)
    if (record ~ /(winrm|ws-?man|openwsman|pywinrm|requests[_-]ntlm|powershell)/) {
      print package
      found=1
    }
  }
  END {
    if (found) exit 1
    print "no WinRM/WS-Man client package or provider found"
  }
' "$index_file"
```

On 2026-08-02 the checksum returned `OK`, the byte-count assertion succeeded,
and the query printed `no WinRM/WS-Man client package or provider found`. The
server also reported `Last-Modified: Sat, 27 Jun 2026 18:00:59 GMT` and
`Content-Length: 1659256`.

The query intentionally searches package names, virtual providers, and
descriptions. A future catalog with any candidate must be treated as changed
evidence and evaluated from its exact root package through its complete
transitive closure; a name match alone cannot qualify it.

## Acceptance audit

- The sole current supported release architecture is AArch64; ARMv7 is optional
  legacy evidence and not a supported release tier. The exact current AArch64
  feed, catalog bytes, digest, timestamp, package versions, and dependency
  records used for this result are recorded above.
- No complete package root means there is no exact WinRM dependency closure,
  TLS behavior, authentication behavior, parser, or structured result contract
  to qualify. Generic TLS, XML, Python, Kerberos, and HTTP components are not
  treated as protocol evidence.
- Runtime `pip`, private builds, a homegrown WS-Man/NTLM/Kerberos/CredSSP
  implementation, HTTP/5985, Basic, CredSSP, trust-all TLS, broad
  `TrustedHosts`, automatic downgrade, and unrestricted administrator endpoints
  remain rejected by
  [ADR 0041](../decisions/0041-require-constrained-winrm-endpoints.md) and
  [ADR 0076](../decisions/0076-gate-winrm-on-a-qualified-client-stack.md).
- The disposable Windows phase is structurally downstream of a qualified
  router client. It was not entered after the feed gate disproved the current
  cohort, and the no-go makes no target-side qualification claim.
- No unresolved protocol or trust choice was selected. The result applies the
  existing ADR hierarchy and leaves WinRM absent; it does not define a new
  fallback, credential flow, endpoint interface, or dependency source.
- No credential, Windows configuration, production host, router, or shutdown
  operation was used.

## Procedure if a future feed adds a candidate

A changed feed does not automatically make WinRM available. Qualification must
restart in order and stop on the first failed gate:

The Windows-side steps must follow Microsoft's
[JEA role-capability](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/role-capabilities)
and
[JEA security](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/security-considerations)
guidance without using the workgroup `TrustedHosts` workaround described in
[PowerShell remoting troubleshooting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting)
as a substitute for HTTPS server identity.

1. Pin the exact supported architecture, feed index, candidate package,
   archive hashes, complete transitive closure, licenses, update source, and
   executable architecture/linkage. Reject private or mutable runtime sources.
2. Demonstrate the packaged client's closed WS-Man parser, message limits,
   HTTPS TLS 1.2+ peer and hostname verification, selected authentication
   mechanism, no downgrade, structured faults, request-loss outcome, and
   nonrepeatable dispatch behavior with harmless fixtures.
3. On a disposable Windows VM, record the exact edition/build and configure an
   explicit HTTPS listener with a disposable certificate trust chain. Do not
   use HTTP, Basic, CredSSP, trust-all TLS, or `TrustedHosts` as identity.
4. Create a unique non-administrator identity admitted only to one dedicated
   JEA-equivalent endpoint. Preserve role-capability and endpoint-ACL evidence
   showing only versioned harmless test, bounded status, and the typed graceful
   wrapper; reject wildcards, providers, script blocks, arbitrary commands,
   default endpoints, administrator membership, and broader operations.
5. Exercise harmless test/status operations, certificate rotation, forbidden
   command coverage, authentication and parser faults, and lost responses. Use
   mocks for ordinary CI. Never interpret disconnect as Off.
6. Qualify an independent read-only Off observation bound to the same logical
   target. Any real graceful shutdown remains a separate manually gated test
   requiring `NUTMERLIN_ALLOW_HOST_SHUTDOWN=1`; one possible dispatch is never
   retried and never escalates.

Any new protocol, trust, credential, packaging, or endpoint-interface choice
not already settled by ADR 0041 and ADR 0076 must return to the design thread
and accepted ADR hierarchy before implementation.
