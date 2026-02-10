# 🐻 Beast-Plan

**Automated iterative planning for Claude Code that produces one-shot-ready implementation plans.**

Give it a complex feature. Get back a bulletproof plan that a fresh Claude session can execute without asking a single question.

```
Interview → Research → [Planner → Skeptic → TDD Reviewer → Critic] ×N → Final Plan
                        \_____________________________________________/
                              Loops until consensus (max 5 iterations)
```

## How it works

You describe what you want to build. Beast-plan runs it through 5 specialized roles:

| Role | Model | Job |
|------|-------|-----|
| **Researcher** | Sonnet | Deep-dives your codebase, runs scripts, tests API calls, checks docs on the web — tags every finding with confidence level |
| **Planner** | Opus | Writes a step-by-step plan with TDD baked in. Every step is small enough to execute without ambiguity |
| **Skeptic** | Opus | Hunts "mirages" — assumptions disguised as facts. Phantom APIs, version mismatches, missing error handling. **Actually verifies** by reading code and running commands |
| **TDD Reviewer** | Sonnet | Ensures tests are genuinely test-first, not afterthoughts bolted on |
| **Critic** | Opus | Scores the plan out of 25. Below 20 → back to Planner with feedback. 20+ → approved |

The loop runs until the Critic approves or 5 iterations are reached. Typical run: 2-3 iterations, 15-50 minutes depending on complexity.

## Why

Because plans have blind spots. You write steps 1-4 beautifully, then step 5 is "integrate with auth middleware" with zero details. In practice, that's where everything breaks — and often those details change the entire plan.

Beast-plan's Skeptic catches every "we'll figure it out later" and forces the Planner to be honest. The result: no surprises during implementation.

## The Skeptic hunts 10 mirage patterns

1. **Phantom APIs** — references endpoints that don't exist or work differently
2. **Version mismatches** — assumes features from wrong library version
3. **Missing error paths** — happy path only, no edge cases
4. **Wrong assumptions** — "this returns an array" when it returns null
5. **Dependency conflicts** — incompatible package versions
6. **Race conditions** — concurrent access not handled
7. **Config gaps** — env vars, secrets, permissions not specified
8. **Schema drift** — plan assumes DB schema that doesn't match reality
9. **Auth blindness** — ignores permissions, tokens, session handling
10. **Test theater** — tests that pass but don't actually verify behavior

## Install

Clone into your Claude Code plugins directory:

```bash
# Claude Code plugins directory
cd ~/.claude/plugins
git clone https://github.com/malakhov-dmitrii/beast-plan.git
```

Then use `/beast-plan` command in Claude Code.

## Commands

- `/beast-plan` — Start a new planning session
- `/beast-plan-status` — Check current session progress
- `/cancel-beast-plan` — Cancel active session

## Structure

```
beast-plan/
├── agents/
│   ├── researcher.md    # Deep research with confidence tagging
│   ├── planner.md       # TDD-embedded plan creation
│   ├── skeptic.md       # Mirage detection specialist
│   ├── tdd-reviewer.md  # Test-first compliance checker
│   └── critic.md        # Final quality gate (scores /25)
├── commands/
│   ├── beast-plan.md
│   ├── beast-plan-status.md
│   └── cancel-beast-plan.md
├── hooks/
│   ├── hooks.json
│   ├── stop-hook.sh     # Drives the iteration loop
│   └── discover-skills.sh
├── skills/
│   └── beast-plan/
│       └── SKILL.md     # Full orchestration protocol
└── tests/
```

## License

MIT
