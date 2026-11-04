#!/usr/bin/env bash
# site-auditor deterministic preflight. Fast (< 30s), no installs.
# Usage: preflight.sh <url> <out.json>
set -uo pipefail
URL="${1:?usage: preflight.sh <url> <out.json>}"
OUT="${2:?usage: preflight.sh <url> <out.json>}"
CHECKS=()   # entries: name|PASS/WARN/FAIL|detail

esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr '\n\r\t' '   '; }
add() { CHECKS+=("$1|$2|$3"); }

# Node >= 20
if command -v node >/dev/null 2>&1; then
  NV="$(node -v 2>/dev/null)"; MAJOR="${NV#v}"; MAJOR="${MAJOR%%.*}"
  if [ "${MAJOR:-0}" -ge 20 ] 2>/dev/null; then add node PASS "$NV"; else add node FAIL "$NV (need >= 20)"; fi
else add node FAIL "node not found"; fi

command -v npx  >/dev/null 2>&1 && add npx PASS "found"  || add npx FAIL "npx not found"
command -v curl >/dev/null 2>&1 && add curl PASS "found" || add curl FAIL "curl not found"

# Chrome
CHROME=""
for p in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "/c/Program Files/Google/Chrome/Application/chrome.exe" \
         "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"; do
  [ -e "$p" ] && CHROME="$p" && break
done
if [ -z "$CHROME" ]; then
  for b in google-chrome google-chrome-stable chromium chromium-browser; do
    command -v "$b" >/dev/null 2>&1 && CHROME="$(command -v "$b")" && break
  done
fi
[ -n "$CHROME" ] && add chrome PASS "$CHROME" || add chrome FAIL "Chrome not found (install Google Chrome stable)"

# Reachability
FINAL_URL=""; HTTP=""; TTOTAL=""
if command -v curl >/dev/null 2>&1; then
  R="$(curl -sS -o /dev/null -L --max-time 15 -A 'site-auditor-preflight' \
        -w '%{http_code} %{time_total} %{url_effective}' "$URL" 2>/dev/null)"
  HTTP="${R%% *}"; REST="${R#* }"; TTOTAL="${REST%% *}"; FINAL_URL="${REST#* }"
  case "$HTTP" in
    2??|3??) add reachable PASS "HTTP $HTTP in ${TTOTAL}s → $FINAL_URL"
             awk "BEGIN{exit !($TTOTAL > 5)}" 2>/dev/null && add speed WARN "first response ${TTOTAL}s (> 5s)" ;;
    *)       add reachable FAIL "no 2xx/3xx response (HTTP ${HTTP:-000}) from $URL" ;;
  esac

  # robots.txt (heuristic: blanket Disallow for *)
  ORIGIN="$(printf '%s' "${FINAL_URL:-$URL}" | sed -E 's#^(https?://[^/]+).*#\1#')"
  ROBOTS="$(curl -sS -L --max-time 8 "$ORIGIN/robots.txt" 2>/dev/null || true)"
  if [ -n "$ROBOTS" ]; then
    BLANKET="$(printf '%s\n' "$ROBOTS" | tr -d '\r' | awk '{l=tolower($0)}
      l ~ /^user-agent:/ {ua=($2=="*")} ua && l ~ /^disallow:[[:space:]]*\/[[:space:]]*$/ {print "yes"; exit}')"
    if [ "$BLANKET" = "yes" ]; then add robots FAIL "robots.txt disallows / for *"
    else add robots PASS "present, no blanket disallow"; fi
  else add robots PASS "none"; fi
fi

# Emit JSON
STATUS=PASS
for c in "${CHECKS[@]}"; do
  s="$(printf '%s' "$c" | cut -d'|' -f2)"
  [ "$s" = FAIL ] && STATUS=FAIL
  [ "$s" = WARN ] && [ "$STATUS" = PASS ] && STATUS=WARN
done
{
  printf '{"status":"%s","url":"%s","final_url":"%s","http":"%s","checks":[' \
    "$STATUS" "$(esc "$URL")" "$(esc "$FINAL_URL")" "$(esc "$HTTP")"
  first=1
  for c in "${CHECKS[@]}"; do
    n="${c%%|*}"; r="${c#*|}"; s="${r%%|*}"; d="${r#*|}"
    [ $first -eq 1 ] && first=0 || printf ','
    printf '{"name":"%s","status":"%s","detail":"%s"}' "$(esc "$n")" "$s" "$(esc "$d")"
  done
  printf ']}\n'
} > "$OUT"
echo "preflight $STATUS → $OUT"
