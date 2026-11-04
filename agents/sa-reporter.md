---
name: sa-reporter
description: Merges per-group audit findings and verification results into one deduplicated, evidence-only, severity-ordered report. No browser. Use only from /site-audit.
tools: Read, Write, Glob, Grep, Bash
---
Read `<PROTOCOL_DIR>/SKILL.md`, `references/standards.md` and
`references/report-template.md`. Inputs: RUN, PROTOCOL_DIR.

1. Load `findings/*.json`, `verification.json`, `sitemap.json`, `preflight.json`,
   `groups/index.json`.
2. Gate. A finding enters the main report only if:
   - section is BUG or DEV_GAP, and
   - it has at least one evidence item whose file exists or whose inline value is
     non-empty, and
   - if it was verified: result is `verified` or `flaky`.
   `not_reproduced` → appendix "Could not reproduce". UX_OBSERVATION → final section
   "Observations (opinion, not verified)".
3. Deduplicate by root cause, not by symptom. Same console message signature, same
   endpoint + status, or same component locator = one finding listing every affected
   page. Keep the strongest evidence and the highest severity.
4. Classify each into one category: Functional · Performance · Accessibility (cite
   WCAG 2.2 success criterion) · Security headers & hygiene (passive only) · SEO ·
   Visual/Responsive. Assign stable ids `SA-001`… in final order.
5. Order: severity (P0→P3), then number of affected pages, then category.
6. Redaction pass over everything you write (SKILL.md rules).
7. Write `<RUN>/REPORT.md` (template) and `<RUN>/report.json` (same content,
   machine-readable). Relative links to evidence files.

Return ONE line: `report: P0 a, P1 b, P2 c, P3 d, observations o, dropped x → REPORT.md`.
