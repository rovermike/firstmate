# Fleet view of a crew whose pipeline run was rebased

One in-flight ship crew. Its status log's last event is `failed: earlier stage run`;
the no-mistakes run on its branch is live (`running`) at a rebased head, and an older
failed run still sits at the local head. Same fixture, base helper vs this change.

```
before ->
{
  "id": "feat-billing",
  "status_log_last_event": "failed",
  "current_state": {
    "state": "failed",
    "source": "status-log",
    "detail": "earlier stage run",
    "raw": "state: failed · source: status-log · earlier stage run",
    "observed_at": "2026-09-14T12:05:00Z",
    "freshness": "fresh"
  }
}

--- fm-fleet-view.sh (human render, before) ---
# Fleet View

Schema: fm-fleet-snapshot.v1
Home: /tmp/fmdrive/cases/snap-before/home

## Under Way
| ID | Current | Kind | Repo/Project | Backend | Endpoint | Artifact | Path | Watch / return channel |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| feat-billing | failed / status-log | ship | firstmate | tmux | present | - | /tmp/fmdrive/cases/snap-before/wt | bin/fm-peek.sh fm-feat-billing |

## Queued
No queued backlog records found.

## Done
No done backlog records found.

## Secondmates
For kind=secondmate, bearings selects validated structured state from that registered home; parent events and bounded terminal evidence are fallback-only supplements and never current-state authority.
```

```
after ->
{
  "id": "feat-billing",
  "status_log_last_event": "failed",
  "current_state": {
    "state": "working",
    "source": "run-step",
    "detail": "validating (running) · run: 01LIVE",
    "raw": "state: working · source: run-step · validating (running) · run: 01LIVE",
    "observed_at": "2026-09-14T12:05:00Z",
    "freshness": "fresh"
  }
}

--- fm-fleet-view.sh (human render, after) ---
# Fleet View

Schema: fm-fleet-snapshot.v1
Home: /tmp/fmdrive/cases/snap-after/home

## Under Way
| ID | Current | Kind | Repo/Project | Backend | Endpoint | Artifact | Path | Watch / return channel |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| feat-billing | working / run-step | ship | firstmate | tmux | present | - | /tmp/fmdrive/cases/snap-after/wt | bin/fm-peek.sh fm-feat-billing |

## Queued
No queued backlog records found.

## Done
No done backlog records found.

## Secondmates
For kind=secondmate, bearings selects validated structured state from that registered home; parent events and bounded terminal evidence are fallback-only supplements and never current-state authority.
```

