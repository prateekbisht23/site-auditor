# Standards used by the report

## Severity rubric
| Sev | Meaning | Examples |
|---|---|---|
| P0 | Core flow unusable for most users | search/results never load; listing page 500; page blank on mobile |
| P1 | Feature broken or seriously degraded | filter has no effect; map stuck loading; LCP poor on a core page; keyboard can't reach primary CTA |
| P2 | Defect with workaround / non-core | layout overflow at 390px; broken image; console errors w/o visible impact; unlabeled non-core input |
| P3 | Polish, best practice, info | missing security headers; missing meta description; minor contrast on decorative text |

Raise one level if it affects most pages; lower one level if only at an unusual viewport.

## Core Web Vitals (lab values from traces)
| Metric | Good | Needs improvement | Poor |
|---|---|---|---|
| LCP | ≤ 2.5 s | ≤ 4.0 s | > 4.0 s |
| INP (interaction latency proxy) | ≤ 200 ms | ≤ 500 ms | > 500 ms |
| CLS | ≤ 0.1 | ≤ 0.25 | > 0.25 |
Lab traces are one machine and one network. Say so in the report.

## Accessibility: WCAG 2.2 AA criteria most often hit
1.1.1 Non-text Content · 1.3.1 Info and Relationships · 1.4.3 Contrast (Minimum, 4.5:1) ·
1.4.10 Reflow · 1.4.11 Non-text Contrast · 2.1.1 Keyboard · 2.1.2 No Keyboard Trap ·
2.4.3 Focus Order · 2.4.7 Focus Visible · 2.5.8 Target Size (Minimum, 24×24 px) ·
3.3.2 Labels or Instructions · 4.1.2 Name, Role, Value.
Automated + agent checks find a subset of WCAG issues. The report must not claim conformance.

## Passive security hygiene (OWASP Secure Headers Project)
Check presence on the main document only: Content-Security-Policy, Strict-Transport-Security,
X-Content-Type-Options: nosniff, Referrer-Policy, frame-ancestors (or X-Frame-Options),
Permissions-Policy. Also: mixed content, cookies without Secure/HttpOnly/SameSite as seen
by the browser, source maps or env/config values visible in normal page source.
Always P3 unless something sensitive is plainly exposed (then P1, and recommend private
disclosure rather than publishing it).
