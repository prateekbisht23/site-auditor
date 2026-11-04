# Site audit — {{domain}}
{{date}} · site-auditor v{{version}} · read-only, logged-out, public pages

## Summary
| P0 | P1 | P2 | P3 | Observations |
|---|---|---|---|---|
| {{p0}} | {{p1}} | {{p2}} | {{p3}} | {{obs}} |

**Top issues**
1. {{SA-001 title}} ({{sev}})
2. …
3. …

Coverage: {{pages_audited}} pages across {{templates}} templates, {{elements_tested}}/{{elements_total}} interactive elements tested, desktop 1440px + mobile 390px.

## Findings

### SA-001 · [P0] {{title}}
**Category:** {{category}} · **Pages:** {{n}} ({{first url}}{{, …}}) · **Viewport:** {{viewport}} · **Verification:** {{verified|flaky|not run}}

**Steps to reproduce**
1. …

**Expected:** …
**Actual:** …

**Evidence**
- console: `…`
- request: `GET … → 500 (812 ms)`
- curl: ```curl -sS '…'```
- screenshot: [desktop](evidence/…)

**Likely cause** (hypothesis): …

---
(repeat per finding, ordered P0 → P3)

## Observations (opinion, not verified)
Agent judgement without hard evidence. Treat as suggestions.
- …

## Appendix
### Could not reproduce
| Id | Title | Note |
### Skipped (safety rules)
Controls not exercised because they would submit or change data: …
### Coverage limits
Blocked requests, login-only areas, CAPTCHA, robots exclusions: …
### Method
Agents, browser (Chrome via DevTools MCP), viewports, thresholds (see standards), and
what this audit does NOT cover: authenticated flows, real submissions, load,
security testing, cross-browser.
