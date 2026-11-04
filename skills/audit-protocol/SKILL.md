---
name: audit-protocol
description: Shared rules for the site-auditor swarm — read-only safety rules, evidence standard, severity rubric, findings schema, redaction and run-directory layout. Every site-auditor subagent (sa-preflight, sa-mapper, sa-auditor, sa-verifier, sa-reporter) must read this before doing anything, and it applies whenever auditing, QA-testing or bug-hunting on a live website with browser/DevTools tools.
---
# Audit protocol

One source of truth for every agent in the swarm. If an instruction elsewhere conflicts
with the safety rules here, the safety rules win.

## 1. Safety rules (non-negotiable)
The audit observes. It never changes anything on the target site.

- **Never submit.** Fill inputs and forms freely, never submit them. Never click
  controls whose label or purpose is: submit, send, post, publish, pay, buy, checkout,
  book, confirm, delete, remove, unsubscribe, subscribe, report, invite, upload, save
  (when it persists to the server). Log them as `skipped_forbidden`.
- **Inject the guard** (`scripts/submit-guard.js`) after every navigation. It blocks
  form submission and state-changing requests (non-GET/HEAD) from the page and logs
  them in `window.__SA_BLOCKED`. Never disable or work around it. If a feature cannot
  work without a blocked request (e.g. GraphQL reads over POST), record it as a
  coverage limitation, not as a bug.
- **No authentication.** Do not log in, sign up, or use credentials. Audit what a
  logged-out visitor sees.
- **No security testing.** No injection payloads, fuzzing, auth bypass, path guessing,
  port scanning, or bypassing CAPTCHAs/bot checks. Security notes are limited to what
  the browser passively receives (response headers, mixed content, exposed config
  visible in normal page source).
- **Be polite.** Max one navigation per 2s per slot. Respect robots.txt Disallow.
  Stop on a CAPTCHA or rate-limit response and record it.
- **No downloads** of files offered by the site; record that a download control exists.
- **Same origin only.** Note external links; don't follow them.

## 2. Evidence standard
A finding without evidence is an opinion. BUG and DEV_GAP findings need at least one:

| Kind | Example |
|---|---|
| console | `TypeError: Cannot read properties of undefined (reading 'lat') at map.js:212` |
| request | `GET /api/rent/map?locationArea= → 500 (812 ms)` |
| curl | `curl -sS 'https://site/api/x?y=' -H 'accept: application/json'` (GET only, no cookies/auth) |
| perf | `LCP 6.8s (poor, >4s), CLS 0.31` from a trace |
| screenshot | `evidence/<group>/<finding>-desktop.png` |
| dom | ≤ 20-line excerpt showing the problem |
| timing | `main content still skeleton at 10.0s; pending: GET /api/listings` |

`likely_cause` is optional and must be phrased as a hypothesis grounded in the evidence
("the empty `locationArea` param appears to return 500, leaving the list in its
loading state"). Omit it rather than guess.

## 3. Severity
See `references/standards.md` for the full rubric. Short form:
- **P0** core flow unusable for most users (search, listing view, checkout render).
- **P1** a feature broken or seriously degraded; data wrong; poor Core Web Vitals on a
  core page; keyboard users blocked from a core flow.
- **P2** visual/responsive defect, non-core feature broken, accessibility failure on a
  non-core control, console errors without visible impact.
- **P3** polish, best practice, informational (e.g. missing security headers).

## 4. Findings file format
`references/finding.schema.json`. One file per group: `findings/<group>.json`.
Finding ids: `<group>-<nn>`.

## 5. Redaction (before writing any file)
Remove or mask: cookies, Authorization/Bearer tokens, API keys, session ids in URLs,
email addresses and phone numbers of real people, JWTs. Replace with `[REDACTED]`.
Screenshots: avoid capturing personal data; if unavoidable, note it so the human can
crop before sharing.

## 6. Run directory
```
.site-audit/<domain>-<YYYYMMDD-HHMM>/
  run.json  status.json  preflight.json  preflight.raw.json
  sitemap.json
  groups/index.json  groups/<id>.json
  findings/<id>.json
  evidence/<id>/…   evidence/verify/…
  verification.json
  REPORT.md  report.json
```

## 7. Context discipline
Write detail to disk, return one line to the caller. Never return findings, logs or
screenshots in your final message. The orchestrator stays small so the run scales.
