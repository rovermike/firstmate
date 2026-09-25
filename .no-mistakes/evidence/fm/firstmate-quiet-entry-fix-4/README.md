# Live validation: /quiet entry without an away-posture record

Branch `fm/firstmate-quiet-entry-fix-4`, base `c60f0ab`, target `faf1fe9`.
Everything here was produced by driving the real fleet scripts in throwaway
`FM_HOME`s on 2026-09-25. No default Herdr session, fleet pane, or real
`FM_HOME` was touched; the only terminal-backend work is a throwaway,
uniquely-named tmux session (`scenario-10`) and the launcher test file's own
throwaway-lab e2e.

## This round (target `faf1fe9`)

| file | what it shows |
| --- | --- |
| `scenario-1-quiet-entry.txt` | The reported failure reproduced on base `c60f0ab` ("an away-posture record is required", exit 1) and fixed on target: the same `/quiet` command exits 0, writes `quiet` into `state/.afk`, and writes no away-posture record |
| `scenario-2-4-guards.txt` | The adversarial guards: `/afk` still refuses the daemon with no record (explicit and unset `FM_AFK_MODE`); `/quiet` refuses while an away record stands and leaves it intact; `/afk` out of quiet rewrites the flag to `away` without ever removing the daemon's presence gate |
| `scenario-5-quiet-off-return.txt` | The whole `/quiet off` path through the real `bin/fm-afk-return.sh` and the real launcher `stop`: a bare refresh keeps the window start, the brief header reads `Return brief (quiet ... 2h00m)`, the flag and the catch-up gate clear, and nothing is archived |
| `scenario-6-pi-quiet.txt` | The restored Pi carve-out: `/quiet` on `pi` and `pi-signed` launches nothing and writes nothing durable, on both `start` and `start-native`, and the refusal names "never run enter for /quiet"; plus the shared-home case where a standing flag still makes the ordinary return the exit |
| `scenario-7-supervision-host.txt` | A `config/supervision-host` claude home: `/quiet` and its bare refresh still prepare the daemon, and once `/afk` rewrites the flag to `away` the daemon is refused again with the record intact |
| `scenario-8-session-start-digest.txt` | The real `bin/fm-session-start.sh` AFK subsection for a home whose only posture is a quiet flag |
| `scenario-9-skill-references.txt` | The two `afk`-skill sections the quiet skill now cites, resolved against the afk skill's actual headings |
| `scenario-10-quiet-start-tmux.txt` | The terminal-backed half of the fix: `/quiet` through `bin/fm-afk-launch.sh start` in a throwaway tmux session - daemon in a detached session, captain pane count unchanged at 1, `stop` reports "quiet mode stopped ... no posture record stood" and tears everything down |
| `fm-afk-launch-suite.txt` | `bash tests/fm-afk-launch.test.sh` - 100 ok, exit 0 |
| `fm-afk-return-suite.txt` | `bash tests/fm-afk-return.test.sh` - stops at the pre-existing host-dependent failure below |
| `fm-afk-return-suite-minus-hostdep.txt` | The same file with only that one invocation skipped - 23 ok, exit 0 |
| `test-fm-session-start-afk-digest.txt` | The two AFK-digest tests from `tests/fm-session-start.test.sh`, run as a targeted subset |

## The one skipped test

`tests/fm-afk-return.test.sh` is fail-fast, and
`test_evidence_publication_failure_preserves_wake_for_redrain` fails on this
macOS host: it redirects the return's stdout onto a read-only fd and expects
exit 3, but the run exits 1 (the write failures themselves happen as designed -
`printf: write error: Bad file descriptor`). It was re-confirmed to fail
identically on base `c60f0ab` from a `git archive` snapshot, so it is
pre-existing and untouched by this change. To see the rest of the file locally
only that one invocation was skipped; every other test in the file ran
unmodified.

## Earlier round (target `8546605`, before the Pi carve-out restore)

`quiet-live-scenarios.txt`, `drive-quiet-scenarios.sh`,
`quiet-supervision-host.txt`, `skill-reference-resolution.txt`,
`check-skill-refs.py`, `quiet-session-start-digest.txt`,
`test-fm-afk-launch.txt`, and `test-fm-afk-return.txt` are from the previous
review round and are kept for continuity; the `scenario-*` files above supersede
them against the current target.
