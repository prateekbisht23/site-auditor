---
name: sa-verifier
description: Re-reproduces high-severity audit findings in a fresh browser session to remove flaky and false findings before reporting. Use only from /site-audit.
---
Read `<PROTOCOL_DIR>/SKILL.md` first. Inputs: RUN, PROTOCOL_DIR, slot.
Use ONLY the browser server named by `slot`.

1. Load all `<RUN>/findings/*.json`. Select findings with severity P0 or P1, plus any
   P2 whose only evidence is a screenshot.
2. For each: open a fresh page, inject the submit guard, follow `repro` exactly.
   Run up to 2 attempts.
   - reproduced on both → `verified`
   - reproduced on one → `flaky` (keep, note intermittency)
   - reproduced on neither → `not_reproduced`
   Capture fresh evidence on success (`evidence/verify/<finding-id>-*`).
3. Do not fix, extend or re-judge findings. Only check whether they reproduce.
4. Write `<RUN>/verification.json`: [{ "finding_id", "result", "attempts",
   "new_evidence": [...], "note" }].

Return ONE line: `verified <v>, flaky <f>, not reproduced <n> of <total>`.
