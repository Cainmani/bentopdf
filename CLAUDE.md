# BentoPDF — Cainmani Internal Deployment

> **This file is read by Claude Code (AI assistant) to enforce development standards.
> All rules below are mandatory. Do not skip, bypass, or work around them.**

## Critical Rules

- **ALWAYS check for upstream changes** at the start of every session before doing any other work:
  ```bash
  gh issue list --label "upstream-sync" --state open --repo Cainmani/bentopdf
  git fetch upstream
  git log --oneline HEAD..upstream/main
  ```
  If there is an open `upstream-sync` issue or new upstream commits, inform the user and offer to merge them.
- **ALWAYS use `--repo Cainmani/bentopdf`** when creating PRs with `gh pr create`. This is a fork — without this flag, PRs go to the upstream repo (alam00000/bentopdf) which cannot be undone.
- **NEVER push directly to main** — always create a branch and PR. No exceptions.
- **NEVER commit `.env` files, secrets, passwords, or IP addresses** — even to private repos. This repo is public (AGPL-3.0 compliance).
- **NEVER deploy without running `audit-server-ready.sh` first**
- **NEVER skip failing tests or CI checks** — fix the root cause, do not bypass
- **NEVER delete or overwrite other people's branches or work** without explicit confirmation
- **NEVER run destructive commands** (`rm -rf`, `docker system prune`, `git reset --hard`, `DROP DATABASE`) without explicit user confirmation
- **NEVER modify shared infrastructure** (Docker networks, Traefik config, Keycloak settings) from this repo — infrastructure changes belong in [infra-cainmani](https://github.com/Cainmani/infra-cainmani)
- **If your change affects the server** (Docker config, ports, env vars, Traefik labels, networks, Keycloak clients) — check whether [infra-cainmani docs](https://github.com/Cainmani/infra-cainmani/tree/main/docs) need updating. If they do, create an issue on infra-cainmani describing what changed.

## Repository Overview

This is a fork of [BentoPDF](https://github.com/alam00000/bentopdf) for internal use at Cainmani as a replacement for Adobe Acrobat Pro. Static site (nginx), all PDF processing happens client-side in the browser. Deployed at `https://pdf.cainmani.cloud` behind Keycloak SSO via oauth2-proxy.

Repo maintainer: @CaideSpries

### Why BentoPDF was chosen over alternatives:
- **Client-side processing** — all PDF operations happen in the browser, files never leave the user's machine
- **100+ PDF tools** — covers all 6 required functions: redact, organise/delete pages, compress, combine, remove passwords, sign & edit
- **Lightweight deployment** — static files served via nginx/Docker, minimal server resources
- **AGPL-3.0 licensed** — free to use; this fork is kept public to comply with the license
- **No per-user limits** — unlike Stirling-PDF which locks Keycloak/OIDC behind a $99/mo paywall

### Why NOT Stirling-PDF:
- OAuth2/OIDC (Keycloak) requires paid Server plan ($99/mo) as of v2.1+
- Open-core model with features being moved behind paywalls over time
- Cannot edit existing text in PDFs (only add new text)
- Heavier server-side processing vs BentoPDF's client-side approach

### Licensing
- This repo is **public** to comply with AGPL-3.0 (source must be available to network users)
- If management objects to a public repo, the fallback is a **$49 one-time commercial license** from BentoPDF
- AGPL compliance rules: keep license intact, push any modifications, never commit secrets
- See: https://www.bentopdf.com/licensing.html

## Git Workflow

Follow [SOP-02 Branching Strategy](https://github.com/Cainmani/docs-sop/blob/main/docs/02-branching-strategy/README.md) and [SOP-03 Code Review](https://github.com/Cainmani/docs-sop/blob/main/docs/03-code-review/README.md):

- **Branch prefixes**: `feature/`, `bugfix/`, `docs/`, `hotfix/`, `chore/`
- **Conventional Commits**: `feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `refactor:`, `test:`, `style:`, `perf:`
- **Merge**: `--no-ff` (no fast-forward). Delete the source branch after merge.

```bash
git checkout -b feature/<name>
# ... make changes, commit with conventional commit messages ...
git push -u origin feature/<name>
gh pr create --repo Cainmani/bentopdf --title "feat: short description" --body "..." --label enhancement
```

- **Issues and PRs**: Always assign to the repo maintainer and add appropriate labels (`bug`, `documentation`, `enhancement`, etc.)

**Branch protection**: GitHub Free does not enforce branch protection on private repos — protection is convention-only (this file + SOPs). See issue [infra-cainmani#10](https://github.com/Cainmani/infra-cainmani/issues/10).

## Pull Requests

- **ALWAYS use `--repo Cainmani/bentopdf`** — this is a fork, omitting this flag sends PRs to upstream
- PR title must follow conventional commit format (e.g., `feat: add user export`)
- Keep PRs under **400 lines** where possible; include "How to Review" section if larger
- At least **1 approving review** before merge
- All CI checks must pass before merge
- Never force-push during active review
- Self-review checklist: builds, tests pass, no secrets, no debug code, docs updated

## Security

Follow [SOP-08 Security Practices](https://github.com/Cainmani/docs-sop/blob/main/docs/08-security-practices/README.md):

- **Never commit secrets**, IP addresses, hostnames, or credentials — even to private repos
- Use `<SERVER_IP>`, `${SERVER_IP}`, `<PUBLIC_IP>` placeholders in docs and code
- Actual values go in `.env` (gitignored) and GitHub repo secrets only
- If secrets are accidentally committed, rewrite history immediately with `git filter-repo`
- Use parameterized queries for all database access — no string interpolation
- Pin GitHub Actions to full commit SHAs, not mutable tags
- `.env` and `.claude/settings.local.json` must be in `.gitignore`

## Testing

Follow [SOP-05 Testing Standards](https://github.com/Cainmani/docs-sop/blob/main/docs/05-testing-standards/README.md):

- **Bug fix PRs must include a regression test** — write a failing test before fixing
- Mandatory tests for: security features, core business logic, data integrity
- Test naming: `[Feature]_[Scenario]_[ExpectedResult]`
- Run tests before pushing

## Common Commands

```bash
# Development (upstream app)
npm install               # Install dependencies
npm run dev               # Start development server

# Production deployment
docker compose -f docker-compose.prod.yml up -d    # Start production services
docker compose -f docker-compose.prod.yml logs -f   # Tail logs

# Upstream sync
git fetch upstream
git log --oneline HEAD..upstream/main
git merge upstream/main
```

## Key Files

- `docker-compose.prod.yml` — production compose (oauth2-proxy + BentoPDF via Traefik forwardAuth)
- `.env.prod.example` — production env template with Keycloak setup instructions
- `docker-compose.yml` — upstream default (BentoPDF only, no auth)
- `docs-cainmani/adr/001-adopt-bentopdf-as-pdf-toolkit.md` — ADR for adoption decision
- `docs-cainmani/adr/002-fork-guardrails-upstream-protection.md` — ADR for fork safety guardrails
- `.github/workflows/ci-cd.yml` — TruffleHog secrets scan + auto-deploy on merge
- `.claude/commands/` — shared Claude Code slash commands (`/audit`, `/review`, `/safe-pr`)
- `.claude/hooks/validate-gh-repo.sh` — PreToolUse hook blocking `gh` commands without `--repo`
- `.claude/settings.json` — Claude Code project settings (hooks configuration)

## Key References

- BentoPDF docs: https://www.bentopdf.com/
- BentoPDF licensing FAQ: https://www.bentopdf.com/licensing.html
- XDA comparison article: https://www.xda-developers.com/bentopdf-over-stirlingpdf-as-primary-pdf-toolkit/
- oauth2-proxy docs: https://oauth2-proxy.github.io/oauth2-proxy/
- Upstream repo: https://github.com/alam00000/bentopdf

---

## Server Deployment

### Deployment Architecture

```
User Browser --> Keycloak (via oauth2-proxy) --> BentoPDF (nginx static files)
                                                   |
                                          PDF processing happens
                                          client-side in browser
```

- **oauth2-proxy** sits in front of BentoPDF and authenticates against our existing Keycloak
- BentoPDF itself has no auth — it's a static web app served by nginx
- Keycloak secrets (client ID, secret, realm URL) go in `.env` — NEVER committed
- The existing `docker-compose.yml` is BentoPDF's upstream default; `docker-compose.prod.yml` adds oauth2-proxy

### Deployment Status

- **Deployed** at `https://pdf.cainmani.cloud` behind Keycloak SSO
- **Production compose:** `docker-compose.prod.yml` (oauth2-proxy + BentoPDF via Traefik forwardAuth)
- **Env template:** `.env.prod.example`
- **CI/CD:** `.github/workflows/ci-cd.yml` (TruffleHog + auto-deploy on merge)
- **ADR:** `docs-cainmani/adr/001-adopt-bentopdf-as-pdf-toolkit.md`

### Pre-Deployment Audit

**MANDATORY**: Run `audit-server-ready.sh` before every first deploy. If it fails, fix the issues. Do NOT deploy with failing audit checks. Do NOT bypass or ignore failures.

```bash
# From the infra repo on the server:
~/cainmani/infra/scripts/audit-server-ready.sh <path-to-app-repo>
```

If the audit script is not available locally, clone [infra-cainmani](https://github.com/Cainmani/infra-cainmani) and run it from there.

### Dockerfile Requirements

- Multi-stage build, non-root user (`USER appuser`)
- `HEALTHCHECK` using `127.0.0.1` (not `localhost` — Alpine resolves to IPv6)
- Validate `VITE_` build args at build time (fail if empty)
- Create writable dirs before `chown` (Docker named volumes mount as root)

### Docker Compose Requirements

- No host ports — Traefik handles all routing
- `restart: unless-stopped` on all services
- Named volumes with explicit `name:` (prevents project-prefix conflicts)
- Healthchecks on all services
- `${VAR:?error}` for required env vars — no `:-changeme` fallbacks in production
- Networks: join `web` (external, for Traefik) and `internal` (external, for DB/Keycloak)

### Keycloak Auth

The oauth2-proxy needs a Keycloak OIDC client configured:
- **Client type:** OpenID Connect
- **Client ID:** `bentopdf` (or whatever you choose)
- **Valid redirect URI:** `https://<your-bentopdf-domain>/oauth2/callback`
- **Web origins:** `https://<your-bentopdf-domain>`
- Internal URL: `http://keycloak:8080` (via `internal` network)
- External URL: `https://auth.cainmani.cloud` (for browser redirects)
- Roles: `realm_access.roles` — `admin`, `editor`, `viewer`
- Groups: `groups` claim — flat array, e.g., `["app-bentopdf"]`
- Skip `aud` verification in backend JWT validation (public clients omit client ID)

Key environment variables for oauth2-proxy (see `.env.prod.example` for full list):
```
OAUTH2_PROXY_PROVIDER=keycloak-oidc
OAUTH2_PROXY_UPSTREAMS=static://202        # Auth-only mode, Traefik serves content
OAUTH2_PROXY_SKIP_PROVIDER_BUTTON=true     # Skip "Sign in with..." interstitial
```

### CI/CD

- Self-hosted runner runs as `github-runner` — use **absolute paths**, never `~`
- Run `git config --global --add safe.directory $APP_DIR` before git operations
- Pin all GitHub Actions to commit SHAs
- Preview deploys use standalone compose files (not overlays — avoids `container_name` conflicts)
- `DOCKER_BUILDKIT=1` for all builds
- GitHub org secrets do not work on private repos (Free plan) — use repo-level secrets

See [SOP-06 CI/CD Pipeline](https://github.com/Cainmani/docs-sop/blob/main/docs/06-cicd-pipeline/README.md) and [CI/CD Guide](https://github.com/Cainmani/infra-cainmani/blob/main/docs/ci-cd-guide.md).

### Environment

- `.env.prod.example` required with all vars documented (passwords empty or placeholder)
- `.env` and `.claude/settings.local.json` in `.gitignore`
- `DOMAIN` and `SERVER_IP` required in `.env.prod.example`

### Infrastructure Context

This app runs on shared Cainmani infrastructure. Before making deployment, networking, or auth changes, review these living documents:

- [Server Context](https://github.com/Cainmani/infra-cainmani/blob/main/docs/server-context.md) — current deployed services, networks, versions
- [App Deployment Guide](https://github.com/Cainmani/infra-cainmani/blob/main/docs/app-deployment-guide.md) — deployment standards and pre-checks
- [App Deployment Context](https://github.com/Cainmani/infra-cainmani/blob/main/docs/app-deployment-context.md) — environment, networking, auth integration
- [CI/CD Guide](https://github.com/Cainmani/infra-cainmani/blob/main/docs/ci-cd-guide.md) — preview deploys, Actions patterns, scheduled maintenance

Do NOT make changes that conflict with this infrastructure without coordinating via an issue on [infra-cainmani](https://github.com/Cainmani/infra-cainmani).

## Upstream Sync

This is a fork of `alam00000/bentopdf`. **Check for upstream changes regularly** (at least before any deployment or PR).

```bash
git fetch upstream
git log --oneline HEAD..upstream/main
```

If there are new commits, merge them:
```bash
git merge upstream/main
# Resolve any conflicts (unlikely — we only add infra files, not app code)
git push origin main
# Then on the server: git pull && docker compose -f docker-compose.prod.yml up -d
```

Last synced: commit 3a985f7 — 2026-03-23

---

## Common Gotchas

### Fork Safety — `gh` CLI Defaults to Upstream
- **`gh` CLI in forks defaults to upstream** — without `--repo`, commands like `gh pr create` and `gh issue create` target `alam00000/bentopdf` instead of `Cainmani/bentopdf`. This has caused real incidents (accidental upstream PR #549, broken upstream-sync workflow).
- **MANDATORY after cloning:** Run `gh repo set-default Cainmani/bentopdf` in every new clone. This sets the `gh-resolved` marker in `.git/config` so all `gh` commands default to the fork.
- **Three layers of protection are in place** (see ADR-002):
  1. `gh repo set-default` — local development (must be run per-clone)
  2. `GH_REPO` env var + `--repo` flags — CI workflows
  3. Claude Code `PreToolUse` hook — blocks `gh pr/issue create` without `--repo Cainmani/bentopdf`
- **GitHub PRs cannot be deleted** — only GitHub Support can remove them, and only for sensitive content. Prevention is the only viable strategy.

### BentoPDF / Deployment-Specific
- **forwardAuth must point at root `/`** — not `/oauth2/auth`. The root endpoint lets oauth2-proxy handle Keycloak redirects internally with correct HTTPS URLs. Using `/oauth2/auth` + Traefik errors middleware breaks behind Cloudflare (produces `http://` redirect URLs).
- **`OAUTH2_PROXY_FORCE_HTTPS: true` crashes oauth2-proxy** — do NOT use it. The redirect URL is already HTTPS via `OAUTH2_PROXY_REDIRECT_URL`.
- **`OAUTH2_PROXY_UPSTREAMS` is plural** — using singular `UPSTREAM` is a silent failure.
- **Keycloak audience mapper required** — without it, oauth2-proxy rejects tokens. Add via: Client scopes → `bentopdf-dedicated` → Add mapper → Audience.

### Shared Infrastructure Gotchas
- `.env` passwords containing `&` must be wrapped in single quotes — bash `source` interprets `&` as background operator
- `docker exec` without `-i` silently drops heredoc stdin — always use `docker exec -i` when piping commands
- GitHub Actions runner runs as `github-runner` — never use `~` in workflows (expands to wrong home). Use absolute paths.
- GitHub org secrets do NOT work with private repos on the Free plan — use repo-level secrets
- `docker compose images --format json` output varies by version (NDJSON vs JSON array) — handle both formats
- Alpine `wget` resolves `localhost` to IPv6 `::1` — use `127.0.0.1` in healthchecks
- Docker named volumes mount as root — Dockerfile must `mkdir` before `chown` for writable dirs
- Keycloak public clients don't include client ID in JWT `aud` claim — skip audience verification in backend
- `Nginx` default `client_max_body_size` is 1MB — set explicitly for upload endpoints
- `(( VAR++ ))` when VAR=0 returns exit code 1 under `set -e` — use `VAR=$((VAR + 1))` instead

---

## Shared Commands

This repo includes shared Claude Code commands in `.claude/commands/`. These are available as slash commands in any Claude Code session:

- **`/audit`** — Run the pre-deployment audit against this repo. MANDATORY before deploying.
- **`/review`** — Review a PR against Cainmani standards (SOPs, security, code quality).
- **`/safe-pr`** — Create a branch and PR safely (enforces naming, conventional commits, labels).

Commands are maintained in [infra-cainmani/templates/.claude/commands/](https://github.com/Cainmani/infra-cainmani/tree/main/templates/.claude/commands/). To update, copy the latest versions from there.
