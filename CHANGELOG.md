# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] — 2026-04-19

### Changed
- **Output shape:** each phase now pairs description with its own improvements — WHY + goal-level improvements, WHAT + architectural, HOW + implementation — instead of collecting all improvements in a separate Phase 4. Phase 4 becomes "the call": the top 1–2 findings, polish nits, and the user-facing trade-off. Fixes the tense/purpose mismatch where HOW read as prescriptive while WHY and WHAT were descriptive.
- Worked example and README "How it works" rewritten to match the paired-section shape.
- Pitfalls table: added rows for layer-mixing (architectural fix under HOW, etc.) and "the call names something not described above."
- SKILL.md restructured with worked example, big-repo escape hatch, and hardened Phase 1 halt condition.
- Merged mistakes/red-flags sections in SKILL.md to reduce redundancy.
- README slimmed; verbose inline guidance moved into SKILL.md.
- README rewritten with sharper problem framing, side-by-side default-vs-first-principles example, and Installation moved below Usage.
- `private/` added to `.gitignore` to keep marketing docs out of the repo.
- Phase 4: added "End with the decision, not the recommendation" closing rule; worked example updated to demonstrate it.

## [0.1.0] — 2026-04-16

### Added
- Initial release of the `first-principles-review` skill.
- Claude Code plugin manifest (`.claude-plugin/plugin.json`).
- Single-plugin marketplace manifest (`.claude-plugin/marketplace.json`) so the repo can be installed directly via `/plugin marketplace add`.
