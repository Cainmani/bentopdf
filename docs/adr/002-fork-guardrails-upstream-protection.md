# ADR-002: Fork Guardrails — Prevent Accidental Upstream Interaction

| Field | Value |
|---|---|
| Status | Accepted |
| Date | 2026-03-31 |
| Decision Makers | @CaideSpries |

## Context

This repository is a fork of [alam00000/bentopdf](https://github.com/alam00000/bentopdf). The `gh` CLI resolves the default target repository using the `gh-resolved` marker in `.git/config`. In forks, this can silently default to the **upstream** repo rather than the fork.

This caused two incidents:

1. **PR #549 on upstream** (2026-03-18): A `gh pr create` without `--repo` accidentally opened a pull request on `alam00000/bentopdf` containing internal infrastructure documentation. The PR could not be deleted via UI or API — a GitHub Support ticket (#4137864) was required to request removal.

2. **Upstream sync workflow failure** (2026-03-30): The `upstream-sync.yml` workflow's `gh issue create` command was targeting the upstream repo (where our `upstream-sync` label didn't exist), causing repeated failures. The workflow had been silently broken since its creation — the missing label on upstream was the only thing preventing issues from being created there.

Both incidents stem from the same root cause: the `gh` CLI defaults to the upstream repo in fork contexts, and there were no technical guardrails to prevent it.

## Decision

Implement a **defense-in-depth strategy** with three layers of protection to ensure all `gh` CLI commands target `Cainmani/bentopdf` and never `alam00000/bentopdf`.

### Layer 1: `gh repo set-default` (Local Development)

Run `gh repo set-default Cainmani/bentopdf` in every local clone. This sets `gh-resolved = base` on the `origin` remote in `.git/config`, making all `gh` commands default to the fork.

- **Scope:** Local development, all `gh` commands
- **Limitation:** Per-clone setting. Each new clone must run this command.
- **Enforcement:** Documented in CLAUDE.md setup instructions and this ADR.

### Layer 2: `GH_REPO` Environment Variable (CI)

Set `GH_REPO: ${{ github.repository }}` at the job level in GitHub Actions workflows that use `gh` commands. This forces the `gh` CLI to target the correct repo regardless of git remote configuration. All `gh` commands also use explicit `--repo "${{ github.repository }}"` flags as additional safety.

A verification step at the start of affected workflows fails fast if `GH_REPO` somehow resolves to the upstream repo.

- **Scope:** GitHub Actions CI
- **Limitation:** Must be added to every workflow that uses `gh` commands.
- **Enforcement:** Workflow fails immediately if targeting upstream.

### Layer 3: Claude Code PreToolUse Hook (AI Assistant)

A hook in `.claude/settings.json` intercepts all Bash tool calls and blocks any `gh pr create` or `gh issue create` command that doesn't include `--repo Cainmani/bentopdf`. The hook exits with code 2 (block) and provides an error message explaining why.

- **Scope:** All Claude Code sessions working in this repo
- **Limitation:** Only protects Claude Code, not human CLI usage.
- **Enforcement:** Deterministic — the command is blocked before execution.

## Alternatives Considered

### `GH_REPO` in Shell Profile

Setting `GH_REPO=Cainmani/bentopdf` in `.bashrc`/`.zshrc` would protect all local `gh` commands. However, this applies to **all repos** in the shell, breaking `gh` usage in other projects. Rejected for local use; adopted for CI only (where it's scoped per-job).

### Git Hooks (pre-push)

`gh pr create` does not go through `git push` — it calls the GitHub API directly. Git hooks are the wrong abstraction layer for this problem. Rejected.

### Shell Alias / Wrapper

Wrapping `gh` to auto-inject `--repo` is fragile, may not be loaded in all shell contexts (including Claude Code), and has the same global-scope problem as `GH_REPO`. Rejected.

### GitHub Upstream Setting

GitHub has no setting to prevent fork contributors from creating PRs or issues on the upstream repo. This is outside our control. Not applicable.

## Consequences

### Positive

- Three independent layers of protection — any single layer prevents the mistake
- `gh repo set-default` is the officially supported mechanism from the `gh` CLI
- Claude Code hook provides deterministic enforcement for AI-assisted development
- CI verification step fails fast with a clear error message
- All guardrails are documented and discoverable

### Negative

- `gh repo set-default` must be run in every new clone (not committable to the repo)
- Claude Code hook only protects Claude Code sessions, not manual `gh` usage
- Developers must be aware of the fork context (documented in CLAUDE.md)

### Risks & Mitigation

| Risk | Likelihood | Mitigation |
|---|---|---|
| New clone forgets `gh repo set-default` | Medium | Documented in CLAUDE.md Common Gotchas. First `gh pr create` attempt will be caught by CLAUDE.md rules or Claude Code hook. |
| New workflow added without `GH_REPO` | Low | CLAUDE.md documents the requirement. PR review should catch it (added to `/review` checklist context). |
| Claude Code hook bypassed | Very Low | Hook is committed to repo (`.claude/settings.json`). Even if bypassed, Layer 1 (`gh repo set-default`) still protects. |

## References

- `gh repo set-default` documentation: https://cli.github.com/manual/gh_repo_set-default
- GitHub CLI issue on fork default behavior: https://github.com/cli/cli/issues/9399
- GitHub Support — PR deletion policy: https://github.com/orgs/community/discussions/28200
- Incident: PR #549 on upstream (GitHub Support ticket #4137864)
- Incident: Upstream sync workflow failure (Actions run #23737475436)
