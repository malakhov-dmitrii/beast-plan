---
description: Cancel the active beast-plan session
---

Cancel the active beast-plan session:

1. Read `.beast-plan/state.json`
2. If no active session exists, report "No active beast-plan session to cancel."
3. If active session exists:
   - Set `active` to `false` in state.json
   - Set `phase` to `"cancelled"`
   - Preserve ALL artifacts (iterations, reports, research, context)
   - Report: "Beast-plan session cancelled. All artifacts preserved in `.beast-plan/`."
4. Emit `<bp-complete>` to allow the stop hook to approve exit.
