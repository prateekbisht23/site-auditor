---
name: sa-mapper
description: Maps a site into audit groups so parallel auditors cover everything exactly once. Discovers pages, clusters by route template and user flow, isolates shared components. Use only from /site-audit.
---
Read `<PROTOCOL_DIR>/SKILL.md` first (safety rules apply to you too).
Inputs: RUN, PROTOCOL_DIR, slot. Use ONLY the browser server named by `slot`.

## 1. Discover (read-only, max `pages` from run.json)
- Sources: `/sitemap.xml` (and nested sitemaps), nav, footer, homepage links, plus
  links found one level deep from core pages. Same origin only. Respect robots Disallow.
- Normalize: drop fragments and tracking params (utm_*, fbclid, gclid).
- Template: collapse URLs that differ only by ids/slugs (`/flat/123`, `/flat/456`
  → `/flat/:id`). Keep 1 sample URL per template (2 if the template is a core flow).

## 2. Identify shared components
Elements that appear on most pages — header, nav, footer, cookie banner, chat widget,
global search, auth modal — go into ONE group `global`, audited once on the homepage.
Record a CSS/ARIA locator for each so other auditors can skip them.

## 3. Group
- Pages that form one user flow belong to the same group so the flow is tested end to
  end once (e.g. search → results → map → listing detail).
- Static/legal pages share one cheap group.
- Estimate size per page = number of interactive elements (snapshot count). Balance
  groups so none is > 2x the median; split a big flow by step if needed.
- Rank groups: core flows (P0 risk) first.

## 4. Write
- `<RUN>/groups/<id>.json`:
  { "id", "kind": "global|flow|section|static", "purpose", "pages": [{url, template,
    role}], "flow_steps": [...], "skip_locators": [...global components...],
    "est_elements", "notes" }
- `<RUN>/groups/index.json`: [{ "id", "kind", "pages": n, "est_elements", "est_minutes" }]
- `<RUN>/sitemap.json`: all discovered URLs → template → group id (for coverage stats).

Return ONE line: `mapped <N> urls → <T> templates → <G> groups`.
