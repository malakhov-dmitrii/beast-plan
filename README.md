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

### Method 1: Direct Install (Recommended)

```bash
claude plugin install https://github.com/malakhov-dmitrii/beast-plan.git
```

### Method 2: Via Marketplace

```bash
# Add marketplace
mkdir -p ~/.claude/plugins/marketplaces/malakhov
cd ~/.claude/plugins/marketplaces/malakhov
git clone https://github.com/malakhov-dmitrii/beast-plan.git

# Create manifest
mkdir -p .claude-plugin
cat > .claude-plugin/marketplace.json << 'EOF'
{
  "name": "malakhov-marketplace",
  "plugins": {
    "beast-plan": {
      "versions": {
        "1.0.0": {"source": "beast-plan"}
      }
    }
  }
}
EOF

# Install
claude plugin install beast-plan@malakhov-marketplace
```

### Verify Installation

```bash
claude plugin list
# Should show: beast-plan
```

Then use `/beast-plan` command in Claude Code.

**⚠️ Note:** Simply cloning to `~/.claude/plugins` won't work - use the installation methods above.

## Commands

- `/beast-plan "task description"` — Start a new planning session
- `/beast-plan-status` — Check all session progress (shows pending, active, legacy)
- `/cancel-beast-plan` — Cancel active session(s) with optional cleanup

## 🔥 Multi-Session Support (New!)

Run multiple beast-plan sessions concurrently in the same project without interference!

### How It Works

Each Claude Code window gets its own isolated session:
- **Pending**: New sessions create `.beast-plan/pending-{timestamp}/`
- **Auto-Claiming**: Hook claims pending session using transcript path
- **Isolated**: Each session gets `.beast-plan/sessions/{session-id}/`
- **No Conflicts**: Sessions don't interfere with each other

### Example: Concurrent Sessions

**Terminal 1:**
```
/beast-plan "Implement authentication"
```

**Terminal 2 (same project):**
```
/beast-plan "Add payment processing"
```

Both run independently! Check status:
```
/beast-plan-status

SESSION ID   STATUS    PHASE      ITER  STARTED              UPDATED
abc123      ✓ active   pipeline   2/5   2026-02-16 10:30    2026-02-16 11:45
def456      ✓ active   research   1/5   2026-02-16 11:00    2026-02-16 11:15
```

**Backward Compatible:** Legacy flat-structure sessions (`.beast-plan/state.json`) still work unchanged.

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

## Troubleshooting

### "No such skill" error

**Problem:** Installed plugin but `/beast-plan` not recognized.

**Solution:**
1. Verify: `claude plugin list` (should show beast-plan)
2. If not listed, reinstall: `claude plugin install https://github.com/malakhov-dmitrii/beast-plan.git`
3. Restart Claude Code completely
4. Try `/beast-plan "test"` again

### Stale pending sessions

**Problem:** Crashed sessions leave `pending-*` directories.

**Solution:**
```bash
/beast-plan-status          # Shows stale sessions
/cancel-beast-plan          # Clean them up
```

### Hook not executing

**Problem:** Session stays in `pending-*` forever.

**Check:**
```bash
# Verify hook exists
ls ~/.claude/plugins/cache/*/beast-plan/*/hooks/stop-hook.sh

# Make executable
chmod +x ~/.claude/plugins/cache/*/beast-plan/*/hooks/stop-hook.sh
```

---

## 🇷🇺 Русская инструкция

### Установка

**Быстрая установка:**
```bash
claude plugin install https://github.com/malakhov-dmitrii/beast-plan.git
```

**Проверка:**
```bash
claude plugin list
# Должен быть: beast-plan
```

### Использование

```
/beast-plan "Реализовать аутентификацию"
```

**Статус:**
```
/beast-plan-status
```

### Что это?

Beast-plan создает качественные планы через проверку 5 специализированными агентами:
1. **Researcher** — исследует код и документацию
2. **Planner** — создает детальный план
3. **Skeptic** — ловит ошибки и нереальные предположения
4. **TDD Reviewer** — проверяет тесты
5. **Critic** — оценивает качество (≥20/25 для одобрения)

### Несколько сессий одновременно

Можно запускать несколько сессий в одном проекте — они не мешают друг другу!

### Проблема: "No such skill"

**Решение:**
1. `claude plugin list` — проверьте установку
2. `claude plugin install https://github.com/malakhov-dmitrii/beast-plan.git` — переустановите
3. Перезапустите Claude Code

⚠️ **Важно:** Просто `git clone` в `~/.claude/plugins` не работает! Используйте `claude plugin install`.

---

## License

MIT
