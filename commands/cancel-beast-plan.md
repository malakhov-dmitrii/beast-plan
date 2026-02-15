---
description: Cancel active beast-plan session(s)
---

Cancel beast-plan session(s) and optionally clean up directories.

## 1. Find All Sessions

**Pending sessions:**
```bash
ls -d .beast-plan/pending-* 2>/dev/null
```

**Active sessions:**
```bash
ls -d .beast-plan/sessions/* 2>/dev/null
```

**Legacy session:**
```bash
if [[ -f ".beast-plan/state.json" ]]; then
  echo ".beast-plan"
fi
```

## 2. Session Selection

**If only ONE session exists:**
- Auto-select it
- Show: "Cancelling session: {session-id} (phase: {phase})"

**If MULTIPLE sessions exist:**
- List all sessions with:
  - Session ID
  - Status (pending/active/inactive)
  - Phase
  - Task description (first 50 chars)
  - Started time
- Ask user: "Which session(s) to cancel?"
- Options:
  - "Select specific session by ID"
  - "Cancel ALL sessions"
  - "Cancel all PENDING sessions only"
  - "Cancel all INACTIVE sessions only"

**If NO sessions exist:**
- Show: "No active beast-plan sessions to cancel."
- Exit

## 3. Cancel Selected Session(s)

For each session to cancel:

1. **Read current state:**
   ```bash
   STATE=$(cat {session-dir}/state.json)
   ```

2. **Update state to cancelled:**
   ```bash
   jq '.active = false | .phase = "cancelled" | .updated_at = (now | todate)' \
      {session-dir}/state.json > {session-dir}/state.json.tmp
   mv {session-dir}/state.json.tmp {session-dir}/state.json
   ```

3. **Preserve artifacts:**
   - Do NOT delete directory automatically
   - Keep all files for debugging/reference

4. **Confirm:**
   - Show: "✓ Cancelled session: {session-id}"

## 4. Cleanup Option

After cancelling, ask user:

```
Session(s) cancelled but files preserved.

Remove cancelled session directories?
  [y] Yes, delete directories completely
  [n] No, keep for reference (recommended)
  [s] Show session contents before deciding
```

**If user selects "y" (delete):**
- For each cancelled session:
  ```bash
  rm -rf {session-dir}
  ```
- Confirm: "✓ Deleted {session-id}"

**If user selects "n" (keep):**
- Show: "Session files kept at: {paths}"

**If user selects "s" (show):**
- For each session:
  - List files: `ls -lh {session-dir}/`
  - Show state.json summary
  - Show iteration count and files
- Then ask delete/keep again

## 5. Special Cases

**Cancelling from within active session:**
- If currently in a beast-plan session and user cancels it
- After cancelling state.json, emit: `<bp-complete>`
- This allows hook to detect cancellation and permit exit

**Cancelling pending session:**
- Simple state update, no hook coordination needed
- Pending sessions can be deleted immediately if user confirms

**Cancelling legacy session:**
- Ask: "This is a legacy flat-structure session. Convert to new format first?"
  - If yes: migrate to `.beast-plan/sessions/legacy-{timestamp}/` then cancel
  - If no: just update `.beast-plan/state.json` to cancelled

## 6. Safety Checks

Before cancelling any session:
- Warn if session is in middle of pipeline iteration
- Warn if session has high critic score (might be valuable)
- Example: "⚠️  Session {id} has score 23/25 (APPROVED). Cancel anyway? [y/n]"

## 7. Example Usage

**Single session:**
```
/cancel-beast-plan

> Found 1 active session: abc123 (phase: pipeline, iteration: 2/5)
> Cancelling session: abc123
> ✓ Cancelled session: abc123
>
> Remove session directory? [y/n]: n
> Session files kept at: .beast-plan/sessions/abc123/
```

**Multiple sessions:**
```
/cancel-beast-plan

> Found 3 sessions:
>   1. pending-111 (pending, interview)
>   2. abc123 (active, pipeline 2/5)
>   3. def456 (inactive, complete)
>
> Which to cancel?
>   [1] Select specific session
>   [2] Cancel ALL sessions
>   [3] Cancel pending only
>   [4] Cancel inactive only
>
> Choice: 3
>
> ✓ Cancelled pending-111
> Remove directory? [y/n]: y
> ✓ Deleted pending-111
```
