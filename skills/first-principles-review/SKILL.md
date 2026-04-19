---
name: first-principles-review
description: Use when reviewing an existing codebase, extension, plugin, app, or project — especially AI-generated code — to understand it deeply and propose meaningful improvements. Triggers on phrases like "review this code", "review this repo", "review this extension/app/project", "audit this repo", "tell me what to change", "what could be better", "make this killer", or any request to analyze and improve an existing implementation.
---

# First Principles Code Review

## Overview

A three-layer review where each layer pairs description with its own improvements, then closes on the decision the user now faces.

- **WHY** — reconstruct the goal, then goal-level improvements
- **WHAT** — map the architecture, then architectural improvements
- **HOW** — read the implementation, then implementation improvements
- **The call** — the one or two that matter most across all three, polish nits, and the trade-off the user has to reason about

Each section pairs past/present (what is) with forward-looking (what should change). The pairing is what makes every improvement structurally tied to its layer — an architectural improvement can't live under WHY; an implementation tweak can't hide under WHAT.

**Core principle:** You cannot evaluate code quality without first knowing what the code is *trying to do*. Skipping to "the implementation has bugs" without grounding in purpose produces nitpicks, not insight.

This is the antidote to the default LLM review failure mode: surface-level critique that catalogs lint issues while missing that the architecture is wrong for the goal.

**Lineage.** WHY → WHAT → HOW mirrors David Marr's three levels of analysis (*Vision*, 1982): computational (what is the system trying to do, and why?) → algorithmic (what representations and processes does it use?) → implementational (how is it physically realized?). Marr's argument was that you cannot meaningfully understand a system at one level without understanding the level above it. Code review collapses without the same discipline — which is why each layer's improvements live in that layer, not in a flat ranked list at the bottom.

## When to Use

- User asks to review a codebase, repo, extension, plugin, app, or project
- User wants improvements to existing work ("make this killer", "what would you change")
- Reviewing code produced by another model or an earlier version of yourself
- Inheriting an unfamiliar project and need to form a real opinion
- Before any non-trivial refactor or rewrite

**When NOT to use:** Small diffs / single-file PRs (use a normal code review). Greenfield work with no existing code (use brainstorming instead).

## The Four Phases

Run them in order. Do not skip ahead. Within each phase, describe before you improve — the description is the lens the improvements must answer to.

### Phase 1 — WHY (goal, then goal-level improvements)

**Describe first.** Reconstruct the goal *without* deferring to what the code currently does.

- What problem does this exist to solve? Who has this problem?
- What would success look like for the user?
- What are the hard constraints (platform, privacy, latency, offline, etc.)?
- What is explicitly *out of scope*?

**Sources in order:** README → package metadata / manifest files (`package.json`, `plugin.json`, `manifest.json`, `Cargo.toml`, `pyproject.toml`) → top-level docs → the user's own framing.

**If the README is missing, stale, or contradicts the code:** reconstruct WHY from manifest files + directory structure + top-of-file comments, then *confirm the reconstructed goal with the user* before proceeding.

**Hard halt — do not skip.** State the goal in one sentence before writing anything else. If you cannot, STOP and ask the user. Guessing the WHY corrupts everything downstream.

**Then improve.** Is the WHY itself wrong, missing, or timidly scoped? Is the project solving a problem worth solving? Is the framing a liability? Most projects have no goal-level gap — say so in one line and move on. When there IS one, it dwarfs everything else, so don't bury it.

**Output:** 3–6 bullets stating purpose and constraints in your own words, then goal-level improvements (or a one-line "none" if the framing holds).

### Phase 2 — WHAT (architecture, then architectural improvements)

**Describe first, without judgment.** Map the system so you can critique it against the WHY you just stated.

- What are the major components and how do they communicate?
- Where does state live? What's the data model?
- What are the trust boundaries (process, network, browser context)?
- What are the external dependencies and integration points?
- What's the build / load / runtime surface?

**Method:** Glob the tree, read entry points, follow imports one hop. Don't read every file — read the seams.

**Big-repo escape hatch.** If the repo has more than ~30 source files, or you find yourself wanting to open more than ~15 files, dispatch the mapping work to an `Explore` subagent with a focused brief (entry points, data flow for the primary action, external integrations). Synthesize its report in the main context. Reading everything yourself pollutes context on exactly the repos where a good review matters most.

**Then improve.** Where does the architecture fail the goal? Wrong abstraction, wrong boundary, wrong data model, wrong component split? This is where the highest-leverage findings usually land — a single architectural observation, tied to a real symptom, often matters more than every implementation tweak combined.

**Output:** A short component map (text or ASCII) plus the data flow for the primary user action, then architectural improvements — each tied explicitly to a WHY constraint it violates or obscures.

### Phase 3 — HOW (implementation, then implementation improvements)

**Describe first.** Read the code with WHY and WHAT as lenses.

- For each major component, what does the code *actually* do?
- Where does the implementation match the architecture, and where does it diverge?
- What are the **load-bearing files**? Read those carefully.
- What's clever, what's confused, what's dead, what's fine?

**Load-bearing file heuristic:** entry points (`main`, `index`, `background`, route handlers), files imported by many others, files that straddle multiple domains (e.g., storage + network), and anything >~200 LOC that isn't config or types. For large repos, delegate file-reading to an `Explore` subagent with targeted questions; read only the 2–4 most load-bearing files yourself.

**Then improve.** Implementation-level fixes — cleaner, faster, safer, simpler. Rank within the section by impact × ease. If an "implementation" fix is actually architectural (changes the component split, the data model, the boundaries), it belongs in Phase 2, not here.

**Output:** Notes per component — what it does, how well it serves its role, what's noteworthy — then implementation improvements, each tied to a specific HOW observation above.

### Phase 4 — The call

You've already laid out the improvements in their home sections. This phase does three small things:

1. **Surface the one or two that matter most.** Point back at them — don't re-explain. *"From above: the architectural split in WHAT and the debounce fix in HOW."*
2. **Polish / nits, unranked.** One-liners. Bury here anything that isn't tied to a real WHY / WHAT / HOW gap. If it fits nowhere above, it's probably a nit — drop it or polish it.
3. **End with the decision, not the recommendation.** The review exists to change what the user does next — so the closing move's job is to make the decision they now face clearer, not to push them toward one answer. Name the trade-off the user actually has to reason about in their context (which you can't see): the cost of doing the top item now vs. deferring it, and what that deferral specifically buys. A recommendation can follow — as a sentence, not the frame. "Want me to start on #1?" turns the reviewer into a hand-raiser; "The call is whether to pay down X now (unblocks Y, costs a day) or defer and let Y compound — I'd do it, but your read of the roadmap trumps mine" respects the user as the decision-maker.

## Worked Example

Concrete sample of the expected output shape. Imagine the target is a Chrome extension that lets users annotate any webpage.

```
## WHY
- Lets users annotate any webpage and share annotations with peers
- Hard constraint: must work without server-side state for v1
- Must survive SPA navigation (no hard reload) on sites like Twitter, Notion
- Out of scope: real-time collaboration, mobile

*Goal-level improvements:* none. The scope is clean and the constraint set is coherent.

## WHAT
- background.ts: storage + (future) sync — chrome.storage.local today, Supabase planned
- content.ts: injects annotation UI; uses MutationObserver for SPA navigation detection
- popup.tsx: viewer for the current page's annotations
- Data flow: user selects text → content.ts builds serialized Range → sends to background.ts → persisted in chrome.storage.local → popup.tsx reads on open

*Architectural improvements:*
1. **Split background.ts into storage.ts + sync.ts.** The sync half is dormant but already entangled with storage calls — that's why the offline-mode bug from issue #14 is hard to fix. Do this before adding Supabase. Tied to WHY: the "no server-side state for v1" constraint is invisible in the current shape, which is why the entanglement went unnoticed.

## HOW
- background.ts interleaves storage and sync — the "sync" half is dormant but already entangled with storage calls
- MutationObserver fires on every DOM change; debouncing exists but the 16ms threshold is effectively always-on
- popup.tsx re-fetches all annotations on every render; no memoization
- content.ts Range serialization is solid — handles shadow DOM correctly, which most web-highlighting code breaks on
- chrome.storage.local writes go through a single queue in background.ts; concurrent-write edge cases are already handled

*Implementation improvements:*
1. **Raise MutationObserver debounce to 250ms.** Will eliminate the CPU spike on Twitter/Notion without losing annotation accuracy (Range rebuild only needs to run after navigation settles). Tied to the SPA-navigation WHY constraint.
2. **Memoize popup.tsx's annotation list.** Free win.

## The call

The two that matter most: the background.ts split (WHAT) and the debounce bump (HOW).

*Polish:* rename `doSync()` → `flushPendingAnnotations()`; current name obscures what it does.

The call is whether to do the background.ts split now — costs a day but unblocks the offline bug and makes the Supabase work tractable — or keep shipping features and let the entanglement compound. I'd split; your read of the roadmap trumps mine.
```

Notice the shape: each section pairs description with its own improvements, so every improvement sits structurally next to the evidence that motivates it. The closing only points at what's already been laid out; it names no new findings.

## Mindset

- **Bring fresh eyes.** Be willing to question the architecture, not just the style. Reviews that only rename variables are not reviews.
- **Be specific.** "Improve error handling" is useless. "Replace the try/catch in `sync.ts:42` with a retry queue because syncs fail silently when offline" is useful.
- **Be honest about uncertainty.** If you'd need to run the code to know, say so.
- **Don't gold-plate.** Bias toward the smallest change that unlocks the most value. Three lines of duplication beats a premature framework.
- **Tie every major suggestion back to a WHY or WHAT gap.** The paired-section structure makes this structural, not aspirational — if a finding doesn't fit the layer it's in, move it or drop it.

## Pitfalls — You're Doing It Wrong If…

| Symptom | Fix |
|---------|-----|
| You started reading source files before reading the README | Back up. Do Phase 1 first, even if it feels obvious. |
| You can't state the project's goal in one sentence | STOP. Ask the user before continuing. |
| Your review is a flat list of 20 nits with no architectural observation | Regroup by leverage; surface the 1–2 that matter. |
| Your "improvements" don't reference any specific file or function | Add concrete `file:line` anchors or drop the item. |
| You suggested a rewrite or new framework without naming the WHY/WHAT gap it closes | Either name the gap or don't suggest it. |
| You read every file in a large repo | Delegate mapping to an `Explore` subagent; read only load-bearing files yourself. |
| You're asking the user to confirm trivia before starting | Only ask when the WHY is genuinely ambiguous. |
| Your "architectural" improvement fits under HOW (or vice versa) | You're mixing leverage layers. Move it to the layer whose description motivates it — if it changes the component split / data model / boundaries, it's architectural. |
| "The call" names something that wasn't described in WHY / WHAT / HOW | The closing only points at things already laid out above. If it's new, it belongs in a section. |
