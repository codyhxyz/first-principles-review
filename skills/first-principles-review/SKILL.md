---
name: first-principles-review
description: Use when reviewing an existing codebase, extension, plugin, app, or project — especially AI-generated code — to understand it deeply and propose meaningful improvements. Triggers on phrases like "review this code", "review this repo", "review this extension/app/project", "audit this repo", "tell me what to change", "what could be better", "make this killer", or any request to analyze and improve an existing implementation.
---

# First Principles Code Review

## Overview

A three-layer review that derives meaning top-down before judging anything: **WHY** (the goal from first principles) → **WHAT** (the architecture) → **HOW** (the implementation) → **improvements**.

**Core principle:** You cannot evaluate code quality without first knowing what the code is *trying to do*. Skipping to "the implementation has bugs" without grounding in purpose produces nitpicks, not insight.

This is the antidote to the default LLM review failure mode: surface-level critique that catalogs lint issues while missing that the architecture is wrong for the goal.

## When to Use

- User asks to review a codebase, repo, extension, plugin, app, or project
- User wants improvements to existing work ("make this killer", "what would you change")
- Reviewing code produced by another model or an earlier version of yourself
- Inheriting an unfamiliar project and need to form a real opinion
- Before any non-trivial refactor or rewrite

**When NOT to use:** Small diffs / single-file PRs (use a normal code review). Greenfield work with no existing code (use brainstorming instead).

## The Four Phases

Run them in order. Do not skip ahead. Each phase's output feeds the next.

### Phase 1 — WHY (First Principles)

Reconstruct the goal *without* deferring to what the code currently does.

- What problem does this exist to solve? Who has this problem?
- What would success look like for the user?
- What are the hard constraints (platform, privacy, latency, offline, etc.)?
- What is explicitly *out of scope*?

**Sources in order:** README → package metadata / manifest files (`package.json`, `plugin.json`, `manifest.json`, `Cargo.toml`, `pyproject.toml`) → top-level docs → the user's own framing.

**If the README is missing, stale, or contradicts the code:** reconstruct WHY from manifest files + directory structure + top-of-file comments, then *confirm the reconstructed goal with the user* before proceeding.

**Hard halt — do not skip.** Before moving to Phase 2, state the goal in one sentence. If you cannot, STOP and ask the user. Guessing the WHY corrupts everything downstream.

**Output:** 3–6 bullets stating the purpose and constraints in your own words.

### Phase 2 — WHAT (Architecture)

Map the system without judgment yet.

- What are the major components and how do they communicate?
- Where does state live? What's the data model?
- What are the trust boundaries (process, network, browser context)?
- What are the external dependencies and integration points?
- What's the build / load / runtime surface?

**Method:** Glob the tree, read entry points, follow imports one hop. Don't read every file — read the seams.

**Big-repo escape hatch.** If the repo has more than ~30 source files, or you find yourself wanting to open more than ~15 files, dispatch the mapping work to an `Explore` subagent with a focused brief (entry points, data flow for the primary action, external integrations). Synthesize its report in the main context. Reading everything yourself pollutes context on exactly the repos where a good review matters most.

**Output:** A short component map (text or ASCII) plus the data flow for the primary user action.

### Phase 3 — HOW (Implementation)

Now read the actual code, with WHY and WHAT as your lens.

- For each major component, what does the code *actually* do?
- Where does the implementation match the architecture, and where does it diverge?
- What are the **load-bearing files**? Read those carefully.
- What's clever, what's confused, what's dead?

**Load-bearing file heuristic:** entry points (`main`, `index`, `background`, route handlers), files imported by many others, files that straddle multiple domains (e.g., storage + network), and anything >~200 LOC that isn't config or types. For large repos, delegate file-reading to an `Explore` subagent with targeted questions; read only the 2–4 most load-bearing files yourself.

**Output:** Notes per component — what it does, how well it serves its role, what's noteworthy.

### Phase 4 — Improve (Lay It Out & Rank)

Present all three layers to the user *first*, then improvements. The user needs to see your model of their system before they trust your suggestions.

Group improvements by **leverage**, not by file:

1. **Goal-level** — the WHY is wrong, missing, or could be more ambitious
2. **Architectural** — the WHAT doesn't fit the WHY (wrong abstraction, wrong boundary, wrong data model)
3. **Implementation** — the HOW could be cleaner, faster, safer, simpler
4. **Polish** — naming, comments, dead code, small wins

Within each group, rank by impact × ease. Call out the **one or two changes that matter most** explicitly — don't bury them in a list of twenty.

**End with the decision, not the recommendation.** The review exists to change what the user does next — so the closing move's job is to make the decision they now face clearer, not to push them toward one answer. Name the trade-off the user actually has to reason about in their context (which you can't see): the cost of doing the top item now vs. deferring it, and what that deferral specifically buys. A recommendation can follow — as a sentence, not the frame. "Want me to start on #1?" turns the reviewer into a hand-raiser; "The call is whether to pay down X now (unblocks Y, costs a day) or defer and let Y compound — I'd do it, but your read of the roadmap trumps mine" respects the user as the decision-maker.

## Worked Example

Concrete sample of the expected output shape. Imagine the target is a Chrome extension that lets users annotate any webpage.

```
## WHY
- Lets users annotate any webpage and share annotations with peers
- Hard constraint: must work without server-side state for v1
- Must survive SPA navigation (no hard reload) on sites like Twitter, Notion
- Out of scope: real-time collaboration, mobile

## WHAT
- background.ts: storage + (future) sync — chrome.storage.local today, Supabase planned
- content.ts: injects annotation UI; uses MutationObserver for SPA navigation detection
- popup.tsx: viewer for the current page's annotations
- Data flow: user selects text → content.ts builds serialized Range → sends to background.ts → persisted in chrome.storage.local → popup.tsx reads on open

## HOW
- background.ts interleaves storage and sync logic — the "sync" half is dormant but already entangled with storage calls
- MutationObserver fires on every DOM change; debouncing exists but the threshold (16ms) is effectively always-on
- popup.tsx re-fetches all annotations on every render; no memoization
- content.ts Range serialization is solid — handles shadow DOM correctly

## Improvements (ranked by leverage)

The two that matter most:
1. **[Architectural]** Split background.ts into storage.ts + sync.ts. The interleaving is the reason the offline-mode bug is hard to fix — they share state they shouldn't. Do this before adding Supabase.
2. **[Implementation]** Raise MutationObserver debounce to 250ms. Will eliminate the CPU spike on Twitter/Notion without losing annotation accuracy (Range rebuild only needs to run after navigation settles).

Also worth doing:
3. **[Implementation]** Memoize popup.tsx's annotation list — free win.
4. **[Polish]** Rename `doSync()` → `flushPendingAnnotations()`; current name obscures what it does.

The call is whether to do the background.ts split now — costs a day but unblocks the offline bug and makes the Supabase work tractable — or keep shipping features and let the entanglement compound. I'd split; your read of the roadmap trumps mine.
```

Notice the shape: the architectural change is named *first*, with a reason tied back to a real symptom. Polish goes at the bottom, unranked. The review ends on the decision the user faces — not a "want me to start?" hand-raise.

## Mindset

- **Bring fresh eyes.** Be willing to question the architecture, not just the style. Reviews that only rename variables are not reviews.
- **Be specific.** "Improve error handling" is useless. "Replace the try/catch in `sync.ts:42` with a retry queue because syncs fail silently when offline" is useful.
- **Be honest about uncertainty.** If you'd need to run the code to know, say so.
- **Don't gold-plate.** Bias toward the smallest change that unlocks the most value. Three lines of duplication beats a premature framework.
- **Tie every major suggestion back to a WHY or WHAT gap.** If you can't, it's probably a nit — move it to the Polish bucket.

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
