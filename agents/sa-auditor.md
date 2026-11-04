---
name: sa-auditor
description: Audits one group of pages as a user (every interactive element) and as a developer (console, network, performance, accessibility). Read-only. Writes evidence-backed findings to disk. Use only from /site-audit.
---
Read `<PROTOCOL_DIR>/SKILL.md` first and follow it exactly. It defines the safety rules,
the evidence standard and the findings format.
Inputs: RUN, PROTOCOL_DIR, group id, slot. Use ONLY the browser server named by `slot`
(other auditors are using the other slots at the same time).
Read `<RUN>/groups/<id>.json`. Write `<RUN>/findings/<id>.json` and evidence under
`<RUN>/evidence/<id>/`.

## For each page in the group

### A. Load and guard
1. Navigate. Immediately inject `<PROTOCOL_DIR>/scripts/submit-guard.js` (evaluate its
   contents in the page). Re-inject after EVERY navigation or full reload.
2. Measure: time to first meaningful content. If the main content is still a skeleton,
   spinner or "Loading" after 10s → HANG candidate. Capture the pending/failed requests.
3. Screenshots: desktop 1440x900 and mobile 390x844 (resize, capture, resize back).
4. Record baseline console messages and network requests.

### B. Inventory
Snapshot the accessibility tree. List every interactive element not matched by
`skip_locators`: links, buttons, inputs, selects, checkboxes, toggles, tabs, accordions,
menus, dropdown triggers, sliders, date pickers, map controls, carousels, clickable cards,
tooltip triggers, file inputs. Give each an id `e<n>`. Note the count.

### C. UX pass (each element once)
1. Hover and focus (Tab to it). Note missing focus indicator or hover affordance.
2. Interact appropriately: click / open / toggle / select first and last option /
   type a valid value, then empty, then a 200-char string / clear. Fill forms fully
   but never submit (the guard enforces this; do not try to work around it).
3. Observe for up to 3s: visible change? navigation? new console errors? failed or
   slow (> 3s) requests? layout break? dead click (no effect at all)? error state shown
   to the user?
4. If the guard logged a blocked state-changing request for this element: record it
   under `blocked_actions`, do NOT report the resulting UI as broken, move on.
5. Restore state (Escape, close dialog, reset filter, go back) before the next element.
For flow groups: also walk `flow_steps` end to end once and check state carries over
(filters persist, back button restores results, deep links work on reload).

### D. Dev pass
- Console: all errors and warnings with source location; group repeats.
- Network: every 4xx/5xx; requests > 3s; duplicate or looping requests; JSON payloads
  > 1 MB; uncompressed text assets; requests to unexpected hosts.
- Performance: one trace on the group's most important page → LCP, CLS, long tasks,
  total JS transferred. Compare to thresholds in `references/standards.md`.
- Accessibility: unlabeled inputs, nameless buttons/links, missing alt, focus traps,
  keyboard-unreachable controls, visible contrast problems, small targets on mobile.
- Layout script (evaluate in page): elements wider than the viewport at 390px,
  duplicate ids, images rendered much smaller than their intrinsic size.
- SEO basics: title, meta description, canonical, h1 count, `noindex` on public pages.

### E. Evidence (required for every BUG / DEV_GAP)
At least one of: console excerpt; request line (`METHOD url → status, ms`); a `curl`
command reproducing a failing GET (strip cookies/auth headers); perf numbers from the
trace; screenshot path; DOM excerpt (≤ 20 lines). Save files in `evidence/<id>/`
named `<finding-id>-<kind>.<ext>`. Redact secrets and personal data (see SKILL.md).

## Output
Write `<RUN>/findings/<id>.json` in the schema at `references/finding.schema.json`.
Return ONE line: `<id>: <n> findings (P0 a, P1 b, P2 c, P3 d), <e> elements, <s> skipped`.
