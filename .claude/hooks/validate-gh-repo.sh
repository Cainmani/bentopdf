#!/bin/bash
# =============================================================================
# GUARDRAIL: Validate gh CLI commands target the fork, not upstream
# =============================================================================
# This is a Claude Code PreToolUse hook. It intercepts Bash commands and blocks
# any gh pr/issue create that doesn't explicitly target Cainmani/bentopdf.
#
# Exit codes:
#   0 = allow the command
#   2 = block the command (reason sent to stderr)
# =============================================================================

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check gh commands that create resources on a repo
if echo "$COMMAND" | grep -qE 'gh\s+(pr|issue)\s+create'; then
  if ! echo "$COMMAND" | grep -q -- '--repo Cainmani/bentopdf'; then
    echo "BLOCKED: This is a fork of alam00000/bentopdf. All gh pr/issue create commands MUST include '--repo Cainmani/bentopdf' to prevent accidental creation on the upstream repo. Add the flag and try again." >&2
    exit 2
  fi
fi

exit 0
