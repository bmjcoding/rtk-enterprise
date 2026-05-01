# Network Egress Policy

This document describes the recommended enterprise network policy for RTK Enterprise.

## Policy Goal

The `rtk` process should not initiate outbound network connections. RTK should execute user-requested child commands, filter their output, and return compact results to the caller.

Network-capable child tools should be governed by existing enterprise controls for those tools.

## Process Boundary

Apply policy to the process boundary:

- `rtk`: deny direct outbound network egress.
- Child tools: allow or deny according to the tool-specific enterprise policy.

Examples of child tools that may require network access:

- `git`
- `gh`
- `curl`
- `wget`
- `aws`
- `az`
- `gcloud`
- `npm`
- `pnpm`
- `pip`
- `cargo`
- `docker`

The enterprise should monitor and attribute child process egress independently from RTK process egress.

## Recommended Controls

Use one or more of the following controls:

- Host firewall rule denying direct outbound connections by the RTK executable path or signing identity
- EDR rule alerting on socket creation by `rtk`
- Proxy policy that requires child tools to authenticate independently
- Binary allowlisting tied to the approved RTK package hash
- Runtime monitoring for unexpected network or TLS library loads by `rtk`
- DLP and proxy monitoring for child commands that can move data

RTK Enterprise also includes a source-level build guard in `build.rs`. That guard fails compilation if RTK-owned runtime source adds direct socket, HTTP client, or local database APIs, or if banned network/database crates enter the lockfile. This is a preventative source control, not a replacement for endpoint enforcement.

## Allowed Behavior

The following behavior is expected:

- `rtk` spawns the child command requested by the user.
- `rtk` reads child process stdout and stderr.
- `rtk` writes compact output to stdout or stderr.
- `rtk` reads local configuration files needed for command filtering.
- `rtk init` writes hook configuration when explicitly invoked by the user or administrator.

## Disallowed Behavior

The following behavior should be blocked or investigated:

- Direct outbound socket creation by `rtk`
- DNS lookups initiated by `rtk`
- HTTP or HTTPS requests initiated by `rtk`
- Direct calls from RTK-owned code to analytics, telemetry, reporting, crash, update, AI, or webhook endpoints
- Creation of local usage-history databases
- Persistence of raw command output unless explicitly added and approved by enterprise policy

## Validation Procedure

Before rollout, test on a managed endpoint:

```bash
rtk --help
rtk config
rtk git status
rtk curl https://example.invalid
```

Expected result:

- `rtk --help` and `rtk config` do not require network access.
- `rtk git status` does not require network access unless Git hooks or configuration invoke networked behavior.
- `rtk curl ...` may attempt network access through the child `curl` process, not through `rtk`.
- Endpoint telemetry identifies the network-capable process correctly.

## Exception Handling

Any exception that allows direct RTK process egress should require:

- Written justification
- Named owner
- Destination allowlist
- Data classification review
- Expiration date
- Approval by security architecture and compliance owners

Do not grant broad outbound access to `rtk` for convenience.
