---
description: Check beast-plan session status (shows all active, pending, and legacy sessions)
---

Display beast-plan session status for all sessions.

## 1. Find All Sessions

**Pending sessions (unclaimed):**
```bash
ls -d .beast-plan/pending-* 2>/dev/null | while read dir; do
  if [[ -f "$dir/state.json" ]]; then
    echo "$dir"
  fi
done
```

**Active sessions (claimed):**
```bash
ls -d .beast-plan/sessions/* 2>/dev/null | while read dir; do
  if [[ -f "$dir/state.json" ]]; then
    echo "$dir"
  fi
done
```

**Legacy session:**
```bash
if [[ -f ".beast-plan/state.json" ]] && [[ ! -d ".beast-plan/sessions" ]] && [[ ! -d .beast-plan/pending-* ]]; then
  echo ".beast-plan"
fi
```

## 2. For Each Session, Extract:

- **Session ID**: Extract from directory name (e.g., `pending-1234567890`, `abc123`, or `legacy`)
- **Status**:
  - `⏳ pending` if in `pending-*/`
  - `✓ active` if in `sessions/*/` and `active: true`
  - `✗ inactive` if `active: false`
- **Phase**: from `state.json` field `phase`
- **Iteration**: from `state.json` field `iteration` and `max_iterations` (format: `2/5`)
- **Started**: from `state.json` field `started_at` (format: `YYYY-MM-DD HH:MM`)
- **Updated**: from `state.json` field `updated_at` (format: `YYYY-MM-DD HH:MM`)
- **Transcript**: from `state.json` field `transcript_path` (if claimed, show basename)

## 3. Format as Table

```
SESSION ID       STATUS      PHASE        ITER  STARTED              UPDATED              TRANSCRIPT
---------------  ----------  -----------  ----  -------------------  -------------------  --------------------
abc123           ✓ active    pipeline     2/5   2024-02-14 10:30    2024-02-14 11:45    transcript-abc123.json
pending-123456   ⏳ pending  interview    1/5   2024-02-14 11:50    2024-02-14 11:51    (unclaimed)
def456           ✗ inactive  complete     3/5   2024-02-14 08:00    2024-02-14 10:00    transcript-def456.json
```

Use proper column alignment for readability.

## 4. Additional Context

After the table, show:

- **Task descriptions** for each active session (from `task_description` field)
- **Warnings** for stale sessions:
  - If pending session is >1 hour old: "⚠️  Pending session {id} is stale (>1 hour old). Consider cleanup with /cancel-beast-plan"
  - If inactive session exists: "ℹ️  Inactive session {id} can be archived or deleted"

## 5. No Sessions Case

If no sessions found anywhere:
```
No active beast-plan sessions found.

Use /beast-plan "task description" to start a new session.
```

## 6. Cleanup Suggestions

If 3+ pending or inactive sessions detected:
```
💡 Tip: You have {count} old sessions. Clean them up with /cancel-beast-plan
```
