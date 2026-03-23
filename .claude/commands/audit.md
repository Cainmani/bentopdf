# Pre-Deployment Audit

Run the infrastructure audit against this repo before deploying to the Cainmani server.
This is MANDATORY before any first deploy and should be run after significant changes.

## Steps

1. Check if `audit-server-ready.sh` is available locally:
   ```bash
   ls ~/cainmani/infra/scripts/audit-server-ready.sh 2>/dev/null || echo "NOT FOUND"
   ```

2. If not found, clone infra-cainmani to a temp directory:
   ```bash
   gh repo clone Cainmani/infra-cainmani /tmp/infra-cainmani 2>/dev/null
   ```

3. Run the audit against the current repo:
   ```bash
   AUDIT_SCRIPT="${HOME}/cainmani/infra/scripts/audit-server-ready.sh"
   if [ ! -f "$AUDIT_SCRIPT" ]; then
     AUDIT_SCRIPT="/tmp/infra-cainmani/scripts/audit-server-ready.sh"
   fi
   bash "$AUDIT_SCRIPT" .
   ```

4. If the audit fails:
   - List each failing check
   - Explain what needs to be fixed
   - Fix the issues (do NOT bypass or ignore failures)
   - Re-run the audit to confirm all checks pass

5. If the audit passes: confirm all checks passed and the repo is ready for deployment.

**IMPORTANT**: Do NOT deploy if any audit check fails. Do NOT skip this step.
