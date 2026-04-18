# first-principles-review

> Forces Claude to stop and ask: **is this code actually solving the right problem?**

Use this after one-shotting something with Claude Code as a review step. It makes Claude take a step back and break down the **WHY**, **WHAT**, and **HOW** of your project — instead of skimming the files and handing you a list of style nits.

## The problem

You one-shot a project with Claude. It looks fine. It runs. But you don't know what you don't know — and when you ask Claude to "review this code," it defaults to nitpicks because nitpicks are easy. Architectural problems go unmentioned. Goal mismatches go unnoticed. You ship it.

## What you get

A review that catches goal and architecture mismatches — not a flat list of twenty formatting critiques.

**Default review:**
- Rename `handleClick` → `onClick`
- Add JSDoc to exported functions
- Extract magic numbers to constants
- [17 more style nits...]

**first-principles review:**
- **[Architectural]** `background.ts` interleaves storage + sync — this is why your offline bug is hard to fix
- **[Implementation]** `MutationObserver` debounce is 16ms, causing the CPU spike users reported
- **[Polish]** Memoize the annotation list — free win

The architectural change is called out *first*, tied back to a real bug. Polish goes at the bottom, unranked.

## Who this is for

- Anyone shipping AI-generated code they didn't fully read
- Indie hackers and vibe coders one-shotting projects with Claude Code
- Engineers inheriting an unfamiliar repo who need a real opinion, fast
- Anyone about to refactor or rewrite and wants to know what actually matters

## When to use it

- **After one-shotting a project** — the canonical use case
- Reviewing a codebase, extension, or app (especially AI-generated)
- "What could be better here?" / "Make this killer"
- Before any non-trivial refactor or rewrite

**Don't use for:** small diffs or single-file PRs (use a normal code review), or greenfield work with no code yet (use brainstorming).

## How it works

`first-principles-review` forces a different shape than default LLM review:

1. **WHY** — Reconstruct the goal *from first principles*, not from the code. What problem does this exist to solve? What are the hard constraints? If unclear, ask the user before continuing.
2. **WHAT** — Map the architecture. Major components, data flow, trust boundaries — without judgment yet.
3. **HOW** — Now read the code, using WHY and WHAT as your lens. Where does the implementation diverge from the architecture? What's load-bearing? What's confused?
4. **Improve** — Group findings by *leverage*, not by file. Goal-level → architectural → implementation → polish. Surface the **one or two changes that matter most**, don't bury them in a list of twenty.

Forcing the WHY → WHAT → HOW order is a small constraint that produces dramatically better reviews. The skill exists to make that constraint stick.

For the full phase-by-phase specification, see [`skills/first-principles-review/SKILL.md`](skills/first-principles-review/SKILL.md).

## Usage

You don't have to remember to invoke it — Claude Code picks it up when you ask for a review:

> "Review this Chrome extension and tell me what could be better."

> "Take a first-principles look at this repo and propose improvements."

## Examples

> **Example 1:** "Review this Chrome extension and tell me what could be better." — The skill reconstructs the goal from the manifest and README (WHY), maps the content-script/background/popup architecture (WHAT), reads the load-bearing files (HOW), and surfaces that `background.ts` interleaves storage and sync logic — tying the suggestion back to a real offline-mode bug in the issue tracker. Ranked above naming nits.

> **Example 2:** "I inherited this repo and I don't trust the previous AI's refactor. What should I change?" — Instead of flagging 20 style issues, the skill names the single architectural mismatch (the sync queue has accreted complexity the original goal didn't require) and proposes a targeted rewrite with justification tied to the project's actual constraints. Polish-tier issues go at the bottom, unranked.

<details>
<summary>Sample output</summary>

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

</details>

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

> **Note:** This installs the skill directly into `~/.claude/skills/` and does not register the plugin wrapper — no `plugin.json` or marketplace metadata. That's fine for most users who just want the skill.

## Contributing

Issues and PRs welcome. If you have a great before/after where this skill caught something a normal review would miss, open an issue and I'll add it as an example.

## License

[MIT](LICENSE) © 2026 Cody Hergenroeder
