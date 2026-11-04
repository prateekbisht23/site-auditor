---
description: Audit a website with a read-only subagent swarm. Usage: /site-audit <url> [--pages N] [--concurrency 1-3] [--yes] [--resume <run-dir>]
argument-hint: <url> [--pages N] [--concurrency 1-3] [--yes] [--resume <run-dir>]
---
You are the ORCHESTRATOR of a site audit. Arguments: $ARGUMENTS

You coordinate. You never audit, never open the browser, and never read findings,
evidence, or reports. Your context must stay small for the whole run.

## What you may read
Only these files in the run dir: `run.json`, `status.json`, `preflight.json` (the
`status`, `fixes`, `slots_ok` fields), `groups/index.json`. Nothing else. Subagents
return one line to you; the detail stays on disk.

## 0. Setup
1. Parse args. Defaults: pages=20, concurrency=3 (max 3, one per browser slot).
2. Resolve PROTOCOL_DIR = the `audit-protocol` skill directory of this plugin
   (`${CLAUDE_PLUGIN_ROOT}/skills/audit-protocol` if that variable is set, otherwise
   find `skills/audit-protocol/SKILL.md` under `~/.claude/plugins/`).
3. If `--resume <run-dir>`: load its `run.json` and `status.json` and jump to the first
   stage that isn't `done`. Skip groups already `done`.
4. Otherwise create `RUN = .site-audit/<domain>-<YYYYMMDD-HHMM>/` with subdirs
   `groups/ findings/ evidence/`, and write:
   - `run.json`: { url, domain, pages, concurrency, protocol_dir, started_at }
   - `status.json`: { stage: "consent", groups: {} }

## 1. Consent (skip if --yes)
Ask the user ONE question: confirm they own the site or have permission to test it,
and that the audit is read-only on public pages. If they decline, stop.

## 2. Preflight
Task → `sa-preflight` with RUN and PROTOCOL_DIR.
Read `preflight.json`. If `status` = FAIL: show `fixes` to the user and stop.
If WARN: tell the user in one line and continue. Set concurrency =
min(concurrency, number of `slots_ok`).

## 3. Map
Task → `sa-mapper` with RUN, PROTOCOL_DIR, slot = first ok slot.
Read `groups/index.json` (ids, sizes, est_minutes only).

## 4. Audit (parallel)
Dispatch `sa-auditor` per group, at most `concurrency` at a time, in ONE message per
batch so they run in parallel. Give each a distinct browser slot from `slots_ok`.
Prompt per auditor: RUN, PROTOCOL_DIR, group id, slot name. Order: `global` group first
in batch 1, then largest groups first.
After each returns, update `status.json.groups[<id>]` = done | failed (+ its one line).
Retry a failed group once on a different slot, then mark it failed and move on.

## 5. Verify
Task → `sa-verifier` with RUN, PROTOCOL_DIR, slot = first ok slot.

## 6. Report
Task → `sa-reporter` with RUN and PROTOCOL_DIR.

## 7. Finish
Tell the user, in at most 6 lines: counts by severity (from the reporter's one-line
return), any failed groups, and the path to `RUN/REPORT.md`. Do not paste findings.
Update `status.json.stage` after every stage so `--resume` works.
