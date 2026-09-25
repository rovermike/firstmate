# Live validation: /quiet entry without an away-posture record

Branch `fm/firstmate-quiet-entry-fix-4` (base `a8572f6`, target `8546605`).
Everything here was produced by driving the real fleet scripts in throwaway
`FM_HOME`s on 2026-09-25. No default Herdr session, fleet pane, or real
`FM_HOME` was touched; the only terminal-backend work is the launcher test
file's own throwaway-tmux e2e.

| file | what it shows |
| --- | --- |
| `quiet-live-scenarios.txt` | The main transcript: S1 the reported failure reproduced on base and fixed on target, S2 refresh, S3/S4/S7 the adversarial guards, S5 /afk out of quiet, S6 the real `/quiet off` return, S8 the Pi carve-out premises |
| `drive-quiet-scenarios.sh` | The driver that produced the transcript (`drive-quiet-scenarios.sh <repo-root> [base-snapshot]`) |
| `quiet-supervision-host.txt` | A `config/supervision-host` claude home: `/afk` launches no daemon, `/quiet` still enters with no record |
| `skill-reference-resolution.txt` | Every `afk`-skill section the quiet skill cites, resolved against the afk skill's parsed headings: 2 dangling on base, all resolving on target |
| `check-skill-refs.py` | The reference resolver used above |
| `quiet-session-start-digest.txt` | The real `bin/fm-session-start.sh` AFK digest and next step for a standing quiet flag |
| `test-fm-afk-launch.txt` | `bash tests/fm-afk-launch.test.sh` - 100 ok, exit 0 (includes the throwaway-tmux terminal e2e) |
| `test-fm-afk-return.txt` | `bash tests/fm-afk-return.test.sh` - 23 ok, exit 0, with one test skipped (see below) |
| `test-fm-session-start-afk-digest.txt` | The two AFK-digest tests from `tests/fm-session-start.test.sh`, run as a targeted subset |

## The one skipped test

`tests/fm-afk-return.test.sh` is fail-fast, and
`test_evidence_publication_failure_preserves_wake_for_redrain` fails on this
macOS host: it redirects the return's stdout onto a read-only fd and expects
exit 3, but the run exits 1 (the write failures themselves happen as designed -
`printf: write error: Bad file descriptor`). It fails identically on the base
commit `a8572f6`, so it is pre-existing and not caused by this change. To see
the rest of the file locally it was skipped by commenting out only that one
invocation in a `git archive HEAD` snapshot of the target tree; every other
test in the file ran unmodified.
