# BentoPDF — Cainmani Internal Deployment

## Rules

- **ALWAYS check for upstream changes** at the start of every session before doing any other work:
  ```bash
  gh issue list --label "upstream-sync" --state open --repo Cainmani/bentopdf
  git fetch upstream
  git log --oneline HEAD..upstream/main
  ```
  If there is an open `upstream-sync` issue or new upstream commits, inform the user and offer to merge them.
- **ALWAYS use `--repo Cainmani/bentopdf`** when creating PRs with `gh pr create`. This is a fork — without this flag, PRs go to the upstream repo (alam00000/bentopdf) which cannot be undone.
- **NEVER commit secrets** — `.env` files are gitignored. This repo is public (AGPL-3.0 compliance).

## Project Context

This is a fork of [BentoPDF](https://github.com/alam00000/bentopdf) for internal use at Cainmani as a replacement for Adobe Acrobat Pro.

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

## Deployment Architecture

```
User Browser --> Keycloak (via oauth2-proxy) --> BentoPDF (nginx static files)
                                                   |
                                          PDF processing happens
                                          client-side in browser
```

- **oauth2-proxy** sits in front of BentoPDF and authenticates against our existing Keycloak
- BentoPDF itself has no auth — it's a static web app served by nginx
- Keycloak secrets (client ID, secret, realm URL) go in `.env` — NEVER committed
- The existing `docker-compose.yml` is BentoPDF's upstream default; we need a `docker-compose.prod.yml` that adds oauth2-proxy

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

Last synced: v2.4.1 (commit 1d68691) — 2026-03-09

## Deployment Status

- **Deployed** at `https://pdf.cainmani.cloud` behind Keycloak SSO
- **Production compose:** `docker-compose.prod.yml` (oauth2-proxy + BentoPDF via Traefik forwardAuth)
- **Env template:** `.env.prod.example`
- **CI/CD:** `.github/workflows/ci-cd.yml` (TruffleHog + auto-deploy on merge)
- **ADR:** `docs/adr/001-adopt-bentopdf-as-pdf-toolkit.md`

## Key References

- BentoPDF docs: https://www.bentopdf.com/
- BentoPDF licensing FAQ: https://www.bentopdf.com/licensing.html
- XDA comparison article: https://www.xda-developers.com/bentopdf-over-stirlingpdf-as-primary-pdf-toolkit/
- oauth2-proxy docs: https://oauth2-proxy.github.io/oauth2-proxy/
- Upstream repo: https://github.com/alam00000/bentopdf

## Keycloak Integration Notes

The oauth2-proxy needs a Keycloak OIDC client configured:
- **Client type:** OpenID Connect
- **Client ID:** `bentopdf` (or whatever you choose)
- **Valid redirect URI:** `https://<your-bentopdf-domain>/oauth2/callback`
- **Web origins:** `https://<your-bentopdf-domain>`

Key environment variables for oauth2-proxy (see `.env.prod.example` for full list):
```
OAUTH2_PROXY_PROVIDER=keycloak-oidc
OAUTH2_PROXY_UPSTREAMS=static://202        # Auth-only mode, Traefik serves content
OAUTH2_PROXY_SKIP_PROVIDER_BUTTON=true     # Skip "Sign in with..." interstitial
```

### Deployment Gotchas
- **forwardAuth must point at root `/`** — not `/oauth2/auth`. The root endpoint lets oauth2-proxy handle Keycloak redirects internally with correct HTTPS URLs. Using `/oauth2/auth` + Traefik errors middleware breaks behind Cloudflare (produces `http://` redirect URLs).
- **`OAUTH2_PROXY_FORCE_HTTPS: true` crashes oauth2-proxy** — do NOT use it. The redirect URL is already HTTPS via `OAUTH2_PROXY_REDIRECT_URL`.
- **`OAUTH2_PROXY_UPSTREAMS` is plural** — using singular `UPSTREAM` is a silent failure.
- **Keycloak audience mapper required** — without it, oauth2-proxy rejects tokens. Add via: Client scopes → `bentopdf-dedicated` → Add mapper → Audience.
