# site-auditor

A Claude Code plugin that audits a website the way a QA engineer and a frontend dev would,
together: it clicks, hovers and types through every interactive element, then opens the
DevTools view (console, network, performance, accessibility) to explain what broke.
Every finding comes with proof. Nothing gets submitted.

```
/site-audit https://example.com
```
→ `.site-audit/example.com-20261104-1530/REPORT.md`

## How it works

```
                   /site-audit <url>   (orchestrator: reads only tiny status files)
                          │
        ┌─────────────────┼──────────────────────────────────────────────┐
        ▼                 ▼                                              │
  sa-preflight        sa-mapper ──► groups/*.json                        │
  (≤90s: reach,       (discover pages, collapse templates,               │
   robots, Node,       global components audited once,                   │
   Chrome, browser     flows kept together, balanced sizes)              │
   slots, login/                  │                                      │
   CAPTCHA walls)                 ▼                                      │
                 ┌────────── sa-auditor × N (parallel, 1 browser each) ──┐
                 │  UX pass: every element — hover, focus, click, type   │
                 │  Dev pass: console, network, perf trace, a11y, layout │
                 │  → findings/<group>.json + evidence/<group>/          │
                 └───────────────────────────┬───────────────────────────┘
                                             ▼
                              sa-verifier (re-runs P0/P1 in a fresh
                              browser, 2 attempts → verified/flaky/dropped)
                                             ▼
                              sa-reporter (dedupe by root cause, evidence
                              gate, WCAG/CWV/OWASP refs → REPORT.md + .json)
```

**Context stays small.** Subagents write everything to disk and return one line. The
orchestrator never reads findings, so a 50-page audit costs it about as much context as
a 5-page one.

**Real parallelism.** The plugin ships three isolated Chrome DevTools MCP servers
(`cdp-1..3`). Each auditor owns one browser, so parallel agents never fight over the
same tab.

## Install

Requirements: Claude Code, Node 20+, Google Chrome.

```
/plugin marketplace add prateekbisht23/site-auditor
/plugin install site-auditor@site-auditor
```
Restart Claude Code, run `/mcp` and check `cdp-1`, `cdp-2`, `cdp-3` are connected.

## Usage

```
/site-audit https://example.com                  # 20 pages, 3 parallel auditors
/site-audit https://example.com --pages 8        # quick pass
/site-audit https://example.com --concurrency 1  # gentle on small sites / your laptop
/site-audit --resume .site-audit/example.com-20261104-1530   # continue an interrupted run
```

## What you get

- `REPORT.md`: summary table, top issues, then each finding with steps to reproduce,
  expected vs actual, evidence (console lines, failing requests, `curl` repros, perf
  numbers, screenshots) and a likely cause when the evidence supports one.
- Findings ordered P0 → P3, deduplicated by root cause across pages.
- Agent opinions without proof are kept out of the findings and listed last as
  "Observations".
- `report.json`: the same, machine-readable (CI, dashboards, diffing runs).

## Safety model

This tool is for sites you own or have permission to test. It asks you to confirm that
before every run (`--yes` skips the prompt).

- **Read-only.** A guard script is injected into every page. It blocks form
  submissions and any non-GET request the page tries to send, and logs them.
  Forms get filled; they never get sent.
- **Logged-out only.** No credentials, no sign-ups.
- **No security testing.** No payloads, fuzzing, bypasses or CAPTCHA solving. Security
  notes are limited to what a browser passively receives (headers, mixed content).
- **Polite.** One navigation per 2 s per browser, robots.txt respected, stops on rate
  limits or bot challenges.
- **Redaction.** Tokens, cookies, keys and personal contact data are masked in all output.

## Limitations

- Lab measurements from one machine and network; not field data.
- Features that read data via POST (e.g. some GraphQL apps) get blocked by the guard and
  are listed under coverage limits.
- Finds a subset of accessibility issues. It never claims WCAG conformance.
- Chrome only. No authenticated flows yet.

## Repo layout

```
.claude-plugin/        plugin + marketplace manifests
.mcp.json              three isolated chrome-devtools-mcp browser slots
commands/site-audit.md orchestrator
agents/                sa-preflight · sa-mapper · sa-auditor · sa-verifier · sa-reporter
skills/audit-protocol/ shared rules, schema, standards, report template,
                       preflight.sh, submit-guard.js
```

## Roadmap

- [ ] PreToolUse hook that hard-blocks clicks on forbidden controls (defence in depth)
- [ ] `--diff <old-run>`: show what's new, fixed, and regressed between runs
- [ ] Authenticated audits with a user-provided test account (opt-in)
- [ ] HTML report with inline screenshots
- [ ] Cross-browser (Firefox/WebKit) via Playwright MCP slots

## License
MIT
