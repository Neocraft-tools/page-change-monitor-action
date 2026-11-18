#!/usr/bin/env bash
# Detect changes on web pages (text, prices, policies) between scheduled runs.
set -euo pipefail
. "$(dirname "$0")/apify.sh"
check_prereqs

URLS="$(split_list "${INPUT_URLS:-}")"
[ "$(jq length <<<"$URLS")" -gt 0 ] || fail "Input 'urls' is required (separate several URLs with commas or new lines)"
NAME="${INPUT_MONITOR_NAME:-}"
[ -z "$NAME" ] && NAME="$(printf '%s' "${GITHUB_REPOSITORY:-github-action}" | tr -c 'A-Za-z0-9._\n-' '-')"

BASE="$(jq -c -n --argjson urls "$URLS" --arg name "$NAME" --arg mode "${INPUT_MODE:-auto}" \
  --argjson ign "$(split_list "${INPUT_IGNORE_SELECTORS:-}")" \
  --argjson shots "$(bool "${INPUT_SCREENSHOTS:-}" false)" \
  '{urls: $urls, monitorName: $name, mode: $mode, screenshots: $shots}
   + (if ($ign | length) > 0 then {ignoreSelectors: $ign} else {} end)')"
[ -n "${INPUT_SELECTOR:-}" ] && BASE="$(jq -c --arg s "$INPUT_SELECTOR" '. + {selector: $s}' <<<"$BASE")"
INPUT="$(merge_extra "$BASE" "${INPUT_EXTRA_INPUT:-}")"

CAP="${INPUT_MAX_TOTAL_CHARGE_USD:-0.10}"
OUT="${INPUT_OUTPUT_FILE:-page-changes.json}"
apify_run "neocraft~page-change-monitor" "$INPUT" "$CAP" "${INPUT_TIMEOUT_SECS:-600}" "$OUT"

CHANGED="$(jq -c '[.[] | select(.status == "changed")]' "$OUT")"
NC="$(jq length <<<"$CHANGED")"
NB="$(jq '[.[] | select(.status == "baseline")] | length' "$OUT")"
NE="$(jq '[.[] | select(.status == "error" or .status == "blocked")] | length' "$OUT")"
DIFF_FILE="${OUT%.json}-diff.md"
jq -r '.[] | "### \(.label // .url)\n\(.url)\n\n\(.summary // "")\n",
  ((.values // [])[] | "- **\(.type // "value")**: \(.before) → \(.after)"),
  ((.diff.changed // [])[:20][] | "```diff\n- \(.before)\n+ \(.after)\n```"),
  ((.diff.added // [])[:20][] | "```diff\n+ \(.)\n```"),
  ((.diff.removed // [])[:20][] | "```diff\n- \(.)\n```"), ""' <<<"$CHANGED" > "$DIFF_FILE"

{
  echo "## Page change monitor: \`${NAME}\`"
  echo
  echo "| Page | Status | Summary |"
  echo "|---|---|---|"
  jq -r '.[] | select(.url != null) | "| \(.url) | \(.status // "?")\(if .errorCode then " (" + .errorCode + ")" else "" end) | \((.summary // .errorMessage // "") | gsub("\\|"; "/") | gsub("\n"; " ") | .[0:200]) |"' "$OUT"
  echo
  if [ "$NB" -gt 0 ]; then echo "_${NB} page(s) checked for the first time: baseline saved, changes will be reported from the next run._"; echo; fi
  if [ "$NC" -gt 0 ]; then echo "### Changes"; cat "$DIFF_FILE"; fi
  true
} | summary
footer "$CAP"

set_output changed "$([ "$NC" -gt 0 ] && echo true || echo false)"
set_output changed-count "$NC"
set_output error-count "$NE"
set_output diff-file "$DIFF_FILE"
set_output changes "$(jq -c 'map({url, label, summary, values, diff: (.diff | if . then {addedCount, removedCount, changedCount} else null end)})' <<<"$CHANGED" | head -c 60000)"

if [ "$NC" -gt 0 ] && [ "$(bool "${INPUT_FAIL_ON_CHANGE:-}" false)" = "true" ]; then
  echo "::error::${NC} page(s) changed: $(jq -r 'map(.url) | join(", ")' <<<"$CHANGED")"
  exit 1
fi
if [ "$NE" -gt 0 ] && [ "$(bool "${INPUT_FAIL_ON_ERROR:-}" false)" = "true" ]; then
  echo "::error::${NE} page(s) could not be checked"
  exit 1
fi
echo "Done: ${NC} changed, ${NB} baseline, ${NE} error(s)"
