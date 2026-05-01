# CI/CD Flows

## PR Quality Gates (ci.yml)

Trigger: pull_request to develop or master

```
                          ┌──────────────────┐
                          │    PR opened      │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │       fmt         │
                          └────────┬─────────┘
                                   │
                          ┌────────▼─────────┐
                          │ clippy            │
                          │ -D unsafe_code    │
                          └┬───┬───┬───┬───┬─┘
                           │   │   │   │
           ┌───────────────┘   │   │   └───────────────┐
           │       ┌───────────┘   │   └──────────┐    │
           ▼       ▼               ▼              ▼    ▼
     ┌──────────┐ ┌──────────┐ ┌───────────┐ ┌─────────┐ ┌──────────┐
     │ test     │ │ security │ │ semgrep   │ │benchmark│ │enterprise│
     │ ubuntu   │ │ cargo    │ │ full scan │ │ >=80%   │ │egress    │
     │ windows  │ │ audit    │ │           │ │ savings │ │audit     │
     │ macos    │ │ deny     │ │           │ │         │ │          │
     └────┬─────┘ └────┬─────┘ └─────┬─────┘ └────┬────┘ └────┬─────┘
          │            │             │             │           │
          └────────────┴─────────┬───┴─────────────┴───────────┘
                                 │
                      ┌──────────▼─────────┐
                      │  All must pass     │
                      │  to merge          │
                      └────────────────────┘

     + DCO check (independent, develop PRs only)
     + Dependabot (weekly: Cargo deps + GitHub Actions)
```

## Merge to develop — pre-release (cd.yml)

Trigger: push to develop | workflow_dispatch (not master) | Concurrency: cancel-in-progress

```
     ┌──────────────────┐
     │ push to develop   │
     │ OR dispatch       │
     └────────┬─────────┘
              │
     ┌────────▼──────────────────┐
     │ pre-release                │
     │ compute next version      │
     │ from conventional commits │
     │ tag = v{next}-rc.{run}    │
     └────────┬──────────────────┘
              │
     ┌────────▼──────────────────┐
     │ release.yml               │
     │ prerelease = true         │
     └────────┬──────────────────┘
              │
     ┌────────▼──────────────────┐
     │ Build                     │
     │ 5 platforms + DEB + RPM   │
     └────────┬──────────────────┘
              │
     ┌────────▼──────────────────┐
     │ GitHub Release            │
     │ (pre-release badge)       │
     │                           │
     │ external notify: REMOVED  │
     │ Homebrew: SKIPPED         │
     └──────────────────────────┘
```

## Merge to master — stable release (cd.yml)

Trigger: push to master (only) | Concurrency: never cancelled

```
     ┌──────────────────┐
     │ push to master    │
     └────────┬─────────┘
              │
     ┌────────▼──────────────────┐
     │ release-please            │
     │ analyze conventional      │
     │ commits                   │
     └────────┬──────────────────┘
              │
         ┌────┴────────────────┐
         │                     │
    no release           release created
         │                     │
         ▼                     ▼
  ┌──────────────┐    ┌───────────────────────┐
  │ create/update│    │ release.yml            │
  │ release PR   │    │ prerelease = false     │
  └──────────────┘    └───────────┬───────────┘
                                  │
                     ┌────────────▼────────────┐
                     │ Build                   │
                     │ 5 platforms + DEB + RPM  │
                     └────────────┬────────────┘
                                  │
                     ┌────────────▼────────────┐
                     │ GitHub Release           │
                     │ (stable, "Latest" badge) │
                     └──┬─────────┬─────────┘
                        │         │
                        ▼         ▼
                    Homebrew   latest
                    tap update tag
```

## Manual release (release.yml)

Trigger: workflow_dispatch

```
     ┌────────────────────────┐
     │ workflow_dispatch       │
     │ inputs: tag, prerelease │
     └───────────┬────────────┘
                 │
     ┌───────────▼────────────┐
     │ Full build pipeline     │
     │ 5 platforms + DEB + RPM │
     └───────────┬────────────┘
                 │
          ┌──────┴──────┐
          │             │
   prerelease=false  prerelease=true
          │             │
          ▼             ▼
     Homebrew       pre-release
     latest tag     badge only
```
