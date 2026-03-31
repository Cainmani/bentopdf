# Adobe Acrobat Pro Replacement — Research Summary

## Original Request

A colleague requested an alternative to Adobe Acrobat Pro that can:
1. Redact information
2. Organise and delete pages
3. Compress PDFs
4. Combine/merge PDFs
5. Remove passwords
6. Sign and edit PDFs

Requirements: free, open source, self-hosted on our existing server infrastructure.

## Tools Evaluated

### Stirling-PDF (Rejected)
- 75K+ GitHub stars, 60+ tools, very popular
- **Rejected because:** Keycloak/OIDC integration requires paid Server plan ($99/mo or $999/yr) as of v2.1+
- Free tier limited to 5 users with built-in auth only
- Open-core model — previously-free features moved behind paywall
- Cannot edit existing text in PDFs (only add new text)
- Server-side processing (heavier resource usage)
- MIT-licensed core, but proprietary extensions for auth features

### BentoPDF (Selected)
- 11K+ GitHub stars, 100+ tools
- All processing is client-side (browser) — files never leave the user's machine
- AGPL-3.0 — fully open source, no artificial limits
- Lightweight: just static files served by nginx
- Covers all 6 requirements
- $49 one-time commercial license available if AGPL compliance is unwanted
- Reference: https://www.xda-developers.com/bentopdf-over-stirlingpdf-as-primary-pdf-toolkit/

### Other Tools Considered
| Tool | Notes |
|------|-------|
| LibreOffice Draw | Good for editing existing PDF text, limited merge/compress |
| OnlyOffice | Full-featured but heavier deployment (AGPL-3.0) |
| PDF Arranger | Desktop only, page management only (GPL-3.0) |
| QPDF | CLI only, no redaction or signing (Apache 2.0) |
| Okular | Annotations only, no true redaction (GPLv2+) |
| Xournal++ | Handwriting/markup focus (GPL-2.0) |
| Paperless-ngx | Document archival/OCR, not a PDF editor (GPL-3.0) |

## Licensing Decision

**Approach:** Public fork on org GitHub to comply with AGPL-3.0 at $0 cost.

AGPL-3.0 requires source availability for network-accessible services. A public fork satisfies this. Keycloak config (secrets) lives in `.env` which is gitignored — no security risk.

**Fallback:** If management objects to public repo, pay $49 one-time for commercial license. This removes all AGPL obligations.

## Architecture

BentoPDF is a static web app — it needs no backend processing. We put oauth2-proxy in front of it to authenticate users against our existing Keycloak instance.

```
Internet/Intranet
       |
  oauth2-proxy (port 8443)
  - authenticates via Keycloak OIDC
  - only passes through authenticated requests
       |
  BentoPDF (port 8080, internal only)
  - nginx serving static files
  - all PDF processing in user's browser
```

## Email Sent

Reply sent to the original requester confirming BentoPDF as the chosen tool, explaining key benefits (client-side processing, no installation needed, 100+ tools, free and open source). Committed to setting it up behind existing auth and notifying when live.
