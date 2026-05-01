# Repository Controls

This source tree contains build-time and CI guardrails, but GitHub-hosted controls still matter because they govern who can change the protected source and release workflows.

Required live settings for `bmjcoding/rtk-enterprise`:

- Default branch is `main`
- `main` has branch protection enabled
- CODEOWNERS review is required before protected-branch changes merge
- Signed commits are required on `main`
- CI status checks from `.github/workflows/ci.yml` are required before merge
- Stale approvals are dismissed after new pushes
- Conversations must be resolved before merge
- Force pushes and branch deletion are disabled on `main`
- Secret scanning and secret scanning push protection are enabled
- Dependabot security updates are disabled unless dependency intake is moved to an approved internal mirror
- Branches are deleted after merge to reduce stale-change surface

Verify these controls with:

```bash
scripts/verify-repo-controls.sh bmjcoding/rtk-enterprise main
```

This check is intentionally separate from `scripts/enterprise-audit.sh` because it requires authenticated GitHub API access and validates hosted repository policy, not local source integrity.
