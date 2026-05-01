## Security Checklist

- [ ] `scripts/enterprise-audit.sh` passes locally or in CI.
- [ ] No removed data-collection, local command-history, reporting command, or raw-output persistence was added.
- [ ] No HTTP client, socket, external reporting vendor, or SQLite usage-database dependency was added.
- [ ] No workflow sends source, PR content, release content, or user data to external reporting services.
- [ ] If release logic changed, SBOM, checksums, signatures, and provenance attestations still run.
- [ ] Independent reviewer assigned for high-risk files.
