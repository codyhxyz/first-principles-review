# first-principles-review

> A Claude Code skill that reviews codebases the way a senior engineer does: **WHY** (goal) → **WHAT** (architecture) → **HOW** (implementation) → improvements ranked by leverage.

The antidote to the default LLM code-review failure mode — flat lists of style nitpicks that catalog lint issues while missing that the architecture is wrong for the goal.

## What it does

Most coding agents, asked to "review this codebase," skim the files, surface a list of formatting and naming critiques, and call it done. Architectural problems go unmentioned. Goal mismatches go unnoticed.

`first-principles-review` forces a different shape:

1. **WHY** — Reconstruct the goal *from first principles*, not from the code. What problem does this exist to solve? What are the hard constraints? If unclear, ask the user before continuing.
2. **WHAT** — Map the architecture. Major components, data flow, trust boundaries — without judgment yet.
3. **HOW** — Now read the code, using WHY and WHAT as your lens. Where does the implementation diverge from the architecture? What's load-bearing? What's confused?
4. **Improve** — Group findings by *leverage*, not by file. Goal-level → architectural → implementation → polish. Surface the **one or two changes that matter most**, don't bury them in a list of twenty.

## When to invoke it

- Reviewing a codebase, extension, app, or project (especially AI-generated code)
- "What could be better here?" / "Make this killer"
- Inheriting an unfamiliar project and you need a real opinion
- Before any non-trivial refactor or rewrite

**Don't use for:** small diffs or single-file PRs (use a normal code review), or greenfield work with no code yet (use brainstorming).

Claude Code will trigger this skill automatically when your request matches.

## Installation

### Claude Code (recommended)

```bash
/plugin marketplace add codyhxyz/first-principles-review
/plugin install first-principles-review@first-principles-review
```

### Manual install

```bash
mkdir -p ~/.claude/skills/first-principles-review
curl -fsSL https://raw.githubusercontent.com/codyhxyz/first-principles-review/main/skills/first-principles-review/SKILL.md \
  -o ~/.claude/skills/first-principles-review/SKILL.md
```

Restart Claude Code. The skill becomes available via the `Skill` tool.

## Usage

Just ask Claude Code to review something:

> "Review this Chrome extension and tell me what could be better."

> "Take a first-principles look at this repo and propose improvements."

The skill kicks in automatically. You'll get a structured review you can actually act on, instead of a flat list of style nits.

## Example output shape

```
## WHY
- Lets users annotate any webpage and share annotations with peers
- Hard constraint: must work without server-side state for v1
- Out of scope: real-time collaboration

## WHAT
- background.ts: storage + sync (chrome.storage.local + later Supabase)
- content.ts: injects annotation UI; uses MutationObserver for SPA navigation
- popup.tsx: viewer for the current page's annotations
- Data flow: user selects → content.ts builds Range → background.ts persists

## HOW
- background.ts is doing too much — sync logic is interleaved with storage logic
- MutationObserver fires on every DOM change; debouncing exists but threshold is 16ms (way too aggressive)
- popup.tsx re-fetches all annotations on every render

## Improvements (ranked by leverage)

1. **[Architectural]** Split background.ts into storage.ts + sync.ts. The interleaving is why your offline-mode bug from issue #14 is hard to fix — they share state they shouldn't.
2. **[Implementation]** Bump MutationObserver debounce to 250ms. Will eliminate the CPU spike users reported on Twitter.
3. **[Polish]** popup.tsx — memoize the annotation list. Free win.
```

Notice: the architectural change is called out *first*, with a reason tied back to a real bug — not buried under naming preferences.

## Why this skill exists

When asked to "review this code," LLMs default to nitpicks because nitpicks are easy. Architectural critique requires understanding the goal, and most reviews skip that step.

Forcing the WHY → WHAT → HOW order is a small constraint that produces dramatically better reviews. The skill exists to make that constraint stick.

## Contributing

Issues and PRs welcome. If you have a great before/after where this skill caught something a normal review would miss, open an issue and I'll add it as an example.

## License

[MIT](LICENSE) © 2026 Cody Hergenroeder
