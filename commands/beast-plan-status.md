---
description: Check the current beast-plan session status
---

Read `.beast-plan/state.json` and present a concise status summary:

- **Session:** active or inactive
- **Phase:** current phase (interview, research, pipeline, finalize, complete)
- **Pipeline Actor:** current actor in the pipeline (if in pipeline phase)
- **Iteration:** current iteration / max iterations
- **Critic Verdict:** last verdict (if any)
- **Scores History:** scores from each completed iteration
- **Flags:** any special flags (NEEDS_RE_RESEARCH, NEEDS_HUMAN_INPUT)
- **Last Updated:** timestamp

If no `.beast-plan/state.json` exists, report "No active beast-plan session."
