#!/usr/bin/env bash
# Drives the /quiet entry-and-exit scenarios against the real fleet scripts in
# throwaway FM_HOMEs. Usage: drive-quiet-scenarios.sh <repo-root>
set -u
ROOT=$1
BASE_SNAPSHOT=${2:-}
# Pin a daemon-running harness (the Pi scenario overrides it explicitly).
unset PI_CODING_AGENT FM_PI_HARNESS CURSOR_AGENT CURSOR_INVOKED_AS GEMINI_CLI ATLASSIAN_AGENT_TYPE ROVODEV_CLI
export CLAUDECODE=1
LAUNCH="$ROOT/bin/fm-afk-launch.sh"
RETURN="$ROOT/bin/fm-afk-return.sh"
FAILED=0
hdr() { printf '\n========== %s ==========\n' "$1"; }
verdict() { if [ "$1" = 0 ]; then printf 'SCENARIO RESULT: PASS - %s\n' "$2"; else printf 'SCENARIO RESULT: FAIL - %s\n' "$2"; FAILED=1; fi; }
newhome() {
  local h; h=$(mktemp -d "${TMPDIR:-/tmp}/fm-quiet-live.XXXXXX")
  mkdir -p "$h/state" "$h/data"
  printf '## In flight\n\n## Queued\n\n## Done\n' > "$h/data/backlog.md"
  printf '%s' "$h"
}
mode() { head -n 1 "$1/state/.afk" 2>/dev/null; }
winstart() { sed -n '2p' "$1/state/.afk" 2>/dev/null; }

# ---------------------------------------------------------------- scenario 1
hdr 'S1 quiet entry without an away-posture record (the reported failure)'
H=$(newhome)
if [ -n "$BASE_SNAPSHOT" ]; then
  BH=$(newhome)
  printf '$ # BASE %s\n$ FM_AFK_MODE=quiet bin/fm-afk-launch.sh start-native\n' "$BASE_SNAPSHOT"
  FM_HOME=$BH FM_STATE_OVERRIDE=$BH/state FM_AFK_MODE=quiet bash "$BASE_SNAPSHOT/bin/fm-afk-launch.sh" start-native 2>&1
  printf 'exit=%s   state/: %s\n' "$?" "$(ls -A "$BH/state" | tr '\n' ' ')"
fi
printf '\n$ # TARGET\n$ FM_AFK_MODE=quiet bin/fm-afk-launch.sh start-native\n'
FM_HOME=$H FM_STATE_OVERRIDE=$H/state FM_AFK_MODE=quiet bash "$LAUNCH" start-native 2>&1
rc=$?
printf 'exit=%s\n$ cat state/.afk\n%s\n$ ls -A state/\n%s\n' "$rc" "$(cat "$H/state/.afk")" "$(ls -A "$H/state" | tr '\n' ' ')"
ok=1
[ "$rc" -eq 0 ] || ok=0
[ "$(mode "$H")" = quiet ] || ok=0
[ ! -e "$H/state/.afk-contract" ] || ok=0
[ ! -e "$H/state/afk-contracts" ] || ok=0
verdict $((1-ok)) 'quiet mode entered with exit 0, flag reads quiet, and no away-posture record was created'

# ---------------------------------------------------------------- scenario 2
hdr 'S2 bare quiet refresh keeps quiet and the original window start'
printf '$ # backdate the window start to an hour ago, then refresh with FM_AFK_MODE unset\n'
BEFORE=$(( $(date +%s) - 3600 ))
printf 'quiet\n%s\n' "$BEFORE" > "$H/state/.afk"
FM_HOME=$H FM_STATE_OVERRIDE=$H/state bash "$LAUNCH" start-native 2>&1
rc=$?
printf 'exit=%s\n$ cat state/.afk\n%s\n' "$rc" "$(cat "$H/state/.afk")"
ok=1
[ "$rc" -eq 0 ] || ok=0
[ "$(mode "$H")" = quiet ] || ok=0
[ "$(winstart "$H")" = "$BEFORE" ] || ok=0
[ ! -e "$H/state/.afk-contract" ] || ok=0
verdict $((1-ok)) "refresh needed no record, kept mode=quiet and window start $BEFORE"

# ---------------------------------------------------------------- scenario 3
hdr 'S3 ADVERSARIAL: quiet start refused while an away-posture record stands'
FM_HOME=$H FM_STATE_OVERRIDE=$H/state bash "$LAUNCH" stop >/dev/null 2>&1
A=$(newhome)
FM_HOME=$A FM_STATE_OVERRIDE=$A/state bash "$ROOT/bin/fm-afk-contract.sh" enter --words 'ship the fix' >/dev/null 2>&1
printf '$ # away posture recorded; now try to sneak into quiet mode\n$ FM_AFK_MODE=quiet bin/fm-afk-launch.sh start-native\n'
FM_HOME=$A FM_STATE_OVERRIDE=$A/state FM_AFK_MODE=quiet bash "$LAUNCH" start-native 2>&1
rc=$?
printf 'exit=%s   state/: %s\n' "$rc" "$(ls -A "$A/state" | tr '\n' ' ')"
ok=1
[ "$rc" -ne 0 ] || ok=0
[ ! -e "$A/state/.afk" ] || ok=0
[ -f "$A/state/.afk-contract" ] || ok=0
verdict $((1-ok)) 'quiet start refused, no flag written, the standing away record left intact'

# ---------------------------------------------------------------- scenario 4
hdr 'S4 ADVERSARIAL: an away start still requires its record'
B=$(newhome)
printf '$ FM_AFK_MODE=away bin/fm-afk-launch.sh start-native   # no record on disk\n'
FM_HOME=$B FM_STATE_OVERRIDE=$B/state FM_AFK_MODE=away bash "$LAUNCH" start-native 2>&1
rc=$?
printf 'exit=%s   state/: [%s]\n' "$rc" "$(ls -A "$B/state" | tr '\n' ' ')"
printf '$ bin/fm-afk-launch.sh start-native                    # implicit away, no record\n'
FM_HOME=$B FM_STATE_OVERRIDE=$B/state bash "$LAUNCH" start-native 2>&1
rc2=$?
printf 'exit=%s   state/: [%s]\n' "$rc2" "$(ls -A "$B/state" | tr '\n' ' ')"
ok=1
[ "$rc" -ne 0 ] && [ "$rc2" -ne 0 ] || ok=0
[ ! -e "$B/state/.afk" ] || ok=0
verdict $((1-ok)) 'both away entries still refuse without the record and write no flag'

# ---------------------------------------------------------------- scenario 5
hdr 'S5 /afk out of quiet mode rewrites the flag to away and keeps the presence gate'
C=$(newhome)
FM_HOME=$C FM_STATE_OVERRIDE=$C/state FM_AFK_MODE=quiet bash "$LAUNCH" start-native >/dev/null 2>&1
printf '$ # in quiet mode: state/.afk = %s\n' "$(mode "$C")"
printf '$ bin/fm-afk-launch.sh enter --words "go fix prod"\n'
FM_HOME=$C FM_STATE_OVERRIDE=$C/state bash "$LAUNCH" enter --words 'go fix prod' 2>&1 | sed -n '1,6p'
printf '$ cat state/.afk\n%s\n$ test -f state/.afk-contract -> %s\n' "$(cat "$C/state/.afk")" "$([ -f "$C/state/.afk-contract" ] && echo present || echo MISSING)"
ok=1
[ "$(mode "$C")" = away ] || ok=0
[ -e "$C/state/.afk" ] || ok=0
[ -f "$C/state/.afk-contract" ] || ok=0
verdict $((1-ok)) 'the quiet flag became away, the flag (the daemon presence gate) still stands, and the record was written'
printf '$ bin/fm-afk-launch.sh stop\n'
FM_HOME=$C FM_STATE_OVERRIDE=$C/state bash "$LAUNCH" stop 2>&1

# ---------------------------------------------------------------- scenario 6
hdr 'S6 /quiet off: the real return brief names the quiet posture'
Q=$(newhome)
FM_HOME=$Q FM_STATE_OVERRIDE=$Q/state FM_DATA_OVERRIDE=$Q/data FM_AFK_MODE=quiet bash "$LAUNCH" start-native >/dev/null 2>&1
printf 'quiet\n%s\n' "$(( $(date +%s) - 3600 ))" > "$Q/state/.afk"
printf '$ # one hour of quiet mode, then the captain says /quiet off\n$ bin/fm-afk-return.sh\n'
out=$(FM_HOME=$Q FM_STATE_OVERRIDE=$Q/state FM_DATA_OVERRIDE=$Q/data bash "$RETURN" 2>&1)
rc=$?
printf '%s\nexit=%s   state/: [%s]\n' "$out" "$rc" "$(ls -A "$Q/state" | tr '\n' ' ')"
ok=1
[ "$rc" -eq 0 ] || ok=0
printf '%s' "$out" | grep -F '=== Return brief (quiet ' >/dev/null || ok=0
printf '%s' "$out" | grep -F ', 1h00m) ===' >/dev/null || ok=0
printf '%s' "$out" | grep -F 'quiet mode stopped' >/dev/null || ok=0
printf '%s' "$out" | grep -F 'no posture record stood' >/dev/null || ok=0
printf '%s' "$out" | grep -F 'away mode stopped' >/dev/null && ok=0
[ ! -e "$Q/state/.afk" ] || ok=0
verdict $((1-ok)) 'the brief header reads quiet, measures the full 1h window from the flag, the stop names quiet and claims no record archive'

# ---------------------------------------------------------------- scenario 7
hdr 'S7 ADVERSARIAL: on Pi, /quiet launches nothing and the refusal steers off enter'
for harness in pi pi-signed; do
  P=$(newhome)
  printf '$ # harness=%s\n$ FM_AFK_MODE=quiet bin/fm-afk-launch.sh start\n' "$harness"
  out=$(FM_HOME=$P FM_STATE_OVERRIDE=$P/state FM_AFK_MODE=quiet FM_TEST_HARNESS=$harness \
    bash -c '. "$1"; fm_afk_launch_primary_harness() { printf "%s" "$FM_TEST_HARNESS"; }; fm_afk_launch_main start' _ "$LAUNCH" 2>&1)
  rc=$?
  printf '%s\nexit=%s   state/: [%s]\n' "$out" "$rc" "$(ls -A "$P/state" | tr '\n' ' ')"
  ok=1
  [ "$rc" -ne 0 ] || ok=0
  printf '%s' "$out" | grep -F 'never run enter for /quiet' >/dev/null || ok=0
  [ -z "$(ls -A "$P/state")" ] || ok=0
  verdict $((1-ok)) "$harness: quiet start launched nothing, wrote nothing durable, and told the agent not to run enter"
  rm -rf "$P"
done

# ---------------------------------------------------------------- scenario 8
hdr 'S8 Pi /quiet off carve-out: no posture -> no return; a standing posture -> the ordinary return'
# 8a the hazard the carve-out avoids: running the return with no posture at all
# gates ordinary captain work on any open blocker.
N=$(newhome)
printf 'window=synthetic:fm-repair\nbackend=tmux\nkind=ship\n' > "$N/state/repair.meta"
printf 'blocked [key=synthetic-dependency]: firstmate can refresh the synthetic token\n' > "$N/state/repair.status"
printf '$ # a Pi home in quiet mode: no state/.afk, no state/.afk-contract, one open blocker\n$ ls -A state/\n%s\n$ bin/fm-afk-return.sh\n' "$(ls -A "$N/state" | tr '\n' ' ')"
out=$(FM_HOME=$N FM_STATE_OVERRIDE=$N/state FM_DATA_OVERRIDE=$N/data bash "$RETURN" 2>&1)
rc=$?
printf '%s\nexit=%s\n' "$out" "$rc"
ok=1
[ "$rc" -eq 3 ] || ok=0
[ -e "$N/state/.afk-return-catchup" ] || ok=0
verdict $((1-ok)) "running the return with no posture standing opens the catch-up gate (exit $rc) and blocks ordinary work - exactly what the restored carve-out tells the agent to skip"
# 8b the carve-out's other half: a flag entered from another session in the same
# shared home still stands, and then the ordinary return is what exits it.
rm -f "$N/state/.afk-return-catchup"
printf 'quiet\n%s\n' "$(( $(date +%s) - 600 ))" > "$N/state/.afk"
printf '\n$ # same home, but another session left state/.afk standing\n$ bin/fm-afk-return.sh\n'
out=$(FM_HOME=$N FM_STATE_OVERRIDE=$N/state FM_DATA_OVERRIDE=$N/data bash "$RETURN" 2>&1)
rc=$?
printf '%s\nexit=%s\n' "$(printf '%s' "$out" | sed -n '1,6p')" "$rc"
ok=1
printf '%s' "$out" | grep -F '=== Return brief (quiet ' >/dev/null || ok=0
[ ! -e "$N/state/.afk" ] || ok=0
verdict $((1-ok)) 'with a flag standing the ordinary return runs, names the quiet posture, and clears the flag'

hdr 'SUITE'
[ "$FAILED" -eq 0 ] && printf 'ALL SCENARIOS PASSED\n' || printf 'SOME SCENARIOS FAILED\n'
exit "$FAILED"
