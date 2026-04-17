---
name: first-principles-review
description: Use when reviewing an existing codebase, extension, app, or project — especially AI-generated code — to understand it deeply and propose meaningful improvements. Triggers on phrases like "review this code", "review this extension/app/project", "what could be better", "make this killer", or any request to analyze and improve an existing implementation.
---

# First Principles Code Review

## Overview

A three-layer review that derives meaning top-down before judging anything: **WHY** (the goal from first principles) → **WHAT** (the architecture) → **HOW** (the implementation) → **improvements**.

**Core principle:** You cannot evaluate code quality without first knowing what the code is *trying to do*. Skipping to "the implementation has bugs" without grounding in purpose produces nitpicks, not insight.

This is the antidote to the default LLM review failure mode: surface-level critique that catalogs lint issues while missing that the architecture is wrong for the goal.

## When to Use

- User asks to review a codebase, repo, extension, app, or project
- User wants improvements to existing work ("make this killer", "what would you change")
- Reviewing code produced by another model or earlier version of yourself
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

**Sources:** README, package metadata, manifest files, top-level docs, the user's own framing. If the goal is unclear, ask the user before continuing — guessing the WHY corrupts everything downstream.

**Output:** 3–6 bullets stating the purpose and constraints in your own words.

### Phase 2 — WHAT (Architecture)

Map the system without judgment yet.

- What are the major components and how do they communicate?
- Where does state live? What's the data model?
- What are the trust boundaries (process, network, browser context)?
- What are the external dependencies and integration points?
- What's the build / load / runtime surface?

**Method:** Glob the tree, read entry points, follow imports one hop. Don't read every file — read the seams.

**Output:** A short component map (text or ASCII diagram) plus the data flow for the primary user action.

### Phase 3 — HOW (Implementation)

Now read the actual code, with WHY and WHAT as your lens.

- For each major component, what does the code *actually* do?
- Where does the implementation match the architecture, and where does it diverge?
- What are the load-bearing functions? Read those carefully.
- What's clever, what's confused, what's dead?

**Output:** Notes per component — what it does, how well it serves its role, what's noteworthy.

### Phase 4 — Lay It Out & Identify Improvements

Present all three layers to the user *first*, then improvements. The user needs to see your model of their system before they trust your suggestions.

Group improvements by **leverage**, not by file:

1. **Goal-level** — the WHY is wrong, missing, or could be more ambitious
2. **Architectural** — the WHAT doesn't fit the WHY (wrong abstraction, wrong boundary, wrong data model)
3. **Implementation** — the HOW could be cleaner, faster, safer, simpler
4. **Polish** — naming, comments, dead code, small wins

Within each group, rank by impact × ease. Call out the **one or two changes that matter most** explicitly — don't bury them in a list of twenty.

## Quick Reference

| Phase | Question | Primary tool | Output |
|-------|----------|--------------|--------|
| WHY | What's the goal? | README, user, manifest | Purpose + constraints |
| WHAT | How is it built? | Glob, entry points, imports | Component map + data flow |
| HOW | Does the code serve the goal? | Read load-bearing files | Per-component notes |
| Improve | What should change? | Synthesis | Ranked list by leverage |

## Mindset

You are likely a more capable model than the one that produced the code. Use that asymmetry honestly:

- **Be ambitious.** If the architecture is wrong, say so — don't just suggest renaming variables.
- **Be specific.** "Improve error handling" is useless. "Replace the try/catch in `sync.ts:42` with a retry queue because syncs fail silently when offline" is useful.
- **Be honest about uncertainty.** If you'd need to run the code to know, say so.
- **Don't gold-plate.** Bias toward the smallest change that unlocks the most value. Three lines of duplication beats a premature framework.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Jumping to implementation critique before understanding the goal | Force yourself through Phase 1 even if it feels obvious |
| Reading every file | Read entry points + load-bearing files only; skim the rest |
| Producing a flat list of 20 nitpicks | Group by leverage; surface the 1–2 that matter |
| Suggesting rewrites without justifying the *why* | Each major suggestion ties back to a WHY or WHAT gap |
| Asking the user to confirm trivia before starting | Only ask when the WHY is genuinely ambiguous |
| Silently assuming the goal | If unsure, ask — wrong WHY poisons everything |

## Red Flags — You're Doing It Wrong

- You started reading source files before reading the README
- Your review is a list of style nits with no architectural observation
- You can't state the project's goal in one sentence
- Your "improvements" don't reference any specific file or function
- You suggested a framework / rewrite without a concrete reason tied to the WHY
