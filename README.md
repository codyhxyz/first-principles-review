# first-principles-review

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
  <a href="https://claude.com/product/claude-code"><img src="https://img.shields.io/badge/built_for-Claude%20Code-d97706" alt="Built for Claude Code"></a>
  <a href="https://github.com/codyhxyz/codyhxyz-plugins"><img src="https://img.shields.io/badge/part_of-codyhxyz--plugins-ffd900?logo=github&logoColor=000" alt="Part of codyhxyz-plugins"></a>
</p>

<p align="center"><img src="docs/hero.gif" alt="first-principles-review" width="900"></p>

> Makes Claude stop and ask: is this code actually solving the right problem?

Run it after one-shotting something with Claude Code. It forces Claude to work out the WHY, WHAT, and HOW of your project before writing a review, instead of skimming the files and handing back a list of style nits.

## The problem

You one-shot a project with Claude. It looks fine. It runs. But you don't know what you don't know, and when you ask Claude to "review this code," it defaults to nitpicks because nitpicks are easy. The architectural stuff goes unmentioned. The goal mismatch goes unnoticed. You ship it.

## What you get

A review that catches goal and architecture mismatches instead of twenty formatting critiques.

What you usually get back:
- Rename `handleClick` to `onClick`
- Add JSDoc to exported functions
- Extract magic numbers to constants
- ...and a bunch more like that

What this skill gets you back:
- [Architectural] `background.ts` interleaves storage and sync. That's why your offline bug is hard to fix.
- [Implementation] `MutationObserver` debounce is 16ms, which is what's causing the CPU spike users reported.
- [Polish] Memoize the annotation list if you feel like it.

The architectural one goes first and gets tied to an actual bug. Polish goes at the bottom, unranked, and you can ignore it.

## Who this is for

Mostly: anyone shipping Claude-generated code they didn't fully read. Indie hackers, vibe coders, people one-shotting side projects. Also useful if you've inherited a repo you don't trust and want a real opinion before you start ripping things out.

## When to use it

Reach for it after one-shotting a project, before a non-trivial refactor, or any time you catch yourself typing "what could be better here" into Claude. Don't bother for small diffs or single-file PRs, normal code review is fine. And don't use it for greenfield work where there's no code yet, brainstorm instead.

## How it works

The skill forces a different shape than the default LLM review:

1. WHY. Reconstruct the goal from first principles, not from the code. What problem does this exist to solve? What are the hard constraints? Then call out any goal-level gaps — most projects have none, and that's fine.
2. WHAT. Map the architecture. Components, data flow, trust boundaries. Then propose architectural improvements, each tied to a WHY constraint.
3. HOW. Read the code, with WHY and WHAT as the lens. What's load-bearing? What's confused? What's fine? Then propose implementation improvements tied to what you just described.
4. The call. Point at the one or two from above that matter most, drop polish nits, and name the trade-off the user now faces.

Each layer pairs description with its own improvements, so an architectural finding can't hide under WHY and an implementation nit can't pose as architecture. The closing only points at what's already been laid out — no new findings.

The WHY → WHAT → HOW ordering is the whole trick. Small constraint, very different output. The skill is basically there to make sure Claude doesn't skip it.

Full phase-by-phase spec is in [`skills/first-principles-review/SKILL.md`](skills/first-principles-review/SKILL.md) if you want it.

## Usage

You don't have to invoke it by name. Claude Code picks it up when you ask for a review:

> "Review this Chrome extension and tell me what could be better."

> "Take a first-principles look at this repo and propose improvements."

## Examples

Example 1: "Review this Chrome extension and tell me what could be better." The skill reconstructs the goal from the manifest and README (WHY), maps the content-script/background/popup architecture (WHAT), reads the load-bearing files (HOW), and lands on the fact that `background.ts` is interleaving storage and sync, which explains an offline-mode bug that's been sitting in the issue tracker. Ranked above the naming nits.

Example 2: "I inherited this repo and I don't trust the previous AI's refactor. What should I change?" Instead of 20 style issues, it names the one architectural mismatch that matters (the sync queue has accreted complexity the original goal didn't call for) and proposes a targeted rewrite, with reasoning tied to the project's actual constraints. Polish at the bottom, unranked.

<details>
<summary>Sample output</summary>

```
## WHY
- Lets users annotate any webpage and share annotations with peers
- Hard constraint: must work without server-side state for v1
- Out of scope: real-time collaboration

*Goal-level improvements:* none. The scope is clean.

## WHAT
- background.ts: storage + sync (chrome.storage.local + later Supabase)
- content.ts: injects annotation UI; uses MutationObserver for SPA navigation
- popup.tsx: viewer for the current page's annotations
- Data flow: user selects → content.ts builds Range → background.ts persists

*Architectural improvements:*
1. Split background.ts into storage.ts + sync.ts. The interleaving is why the offline-mode bug from issue #14 is hard to fix — tied to the "no server-side state for v1" constraint, which the current shape obscures.

## HOW
- background.ts interleaves storage and sync; sync half dormant but entangled
- MutationObserver debounce is 16ms — basically no debounce
- popup.tsx re-fetches all annotations on every render
- content.ts Range serialization handles shadow DOM correctly (notable — most web-highlighting code breaks here)

*Implementation improvements:*
1. Bump the MutationObserver debounce to 250ms. Kills the CPU spike people reported on Twitter.
2. Memoize popup.tsx's annotation list. Free win.

## The call

The two that matter most: the background.ts split (WHAT) and the debounce bump (HOW). Polish: rename `doSync()` → `flushPendingAnnotations()`.

The call is whether to split background.ts now — costs a day, unblocks the offline bug, makes Supabase tractable — or keep shipping and let the entanglement compound. I'd split; your read of the roadmap trumps mine.
```

</details>

## Installation

### Claude Code (recommended)

```bash
/plugin marketplace add codyhxyz/first-principles-review
/plugin install first-principles-review@first-principles-review
```

See the full [codyhxyz-plugins marketplace](https://github.com/codyhxyz/codyhxyz-plugins) for my other plugins.

### Manual install

```bash
mkdir -p ~/.claude/skills/first-principles-review
curl -fsSL https://raw.githubusercontent.com/codyhxyz/first-principles-review/main/skills/first-principles-review/SKILL.md \
  -o ~/.claude/skills/first-principles-review/SKILL.md
```

Restart Claude Code. The skill shows up via the `Skill` tool.

> Heads up: this drops the skill straight into `~/.claude/skills/` and skips the plugin wrapper. No `plugin.json`, no marketplace metadata. That's fine if you just want the skill and don't care about the rest.

## Contributing

Issues and PRs welcome. If you've got a good before/after where this skill caught something a normal review would've missed, open an issue and I'll add it as an example.

## License

[MIT](LICENSE) © 2026 Cody Hergenroeder

---

<sub>Part of <a href="https://github.com/codyhxyz/codyhxyz-plugins"><b>codyhxyz-plugins</b></a> 🍋 — my registry of Claude Code plugins.</sub>
