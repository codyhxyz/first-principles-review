#!/usr/bin/env bash
# Deterministic simulated session for the first-principles-review hero GIF.
# Driven by docs/demo.tape via `vhs docs/demo.tape`.

set -e

CYAN=$'\033[36m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

slow_print() {
  local text="$1"
  local delay="${2:-0.025}"
  for (( i=0; i<${#text}; i++ )); do
    printf "%s" "${text:$i:1}"
    sleep "$delay"
  done
  echo
}

printf "%s" "${DIM}user prompt:${RESET} "
slow_print "review this codebase and tell me what to change"
sleep 0.7

echo
printf "%s\n" "${DIM}── typical review ──${RESET}"
sleep 0.5

cat <<EOF
${DIM}• Rename ${RESET}handleClick${DIM} to ${RESET}onClick
${DIM}• Add JSDoc to exported functions${RESET}
${DIM}• Extract magic numbers to constants${RESET}
${DIM}• Prefer ${RESET}const${DIM} over ${RESET}let${DIM} where possible${RESET}
${DIM}• Consider splitting long functions${RESET}
${DIM}• Add trailing commas for cleaner diffs${RESET}
EOF
sleep 1.8

echo
printf "%s\n" "${DIM}…twenty nits, zero architecture. The offline bug goes unmentioned.${RESET}"
sleep 1.6

echo
printf "%s\n" "${CYAN}[first-principles-review] grounding: WHY → WHAT → HOW…${RESET}"
sleep 1.3

echo
printf "%s\n" "${BOLD}── first-principles review ──${RESET}"
sleep 0.4

cat <<EOF

${BOLD}## WHY${RESET}
- Chrome extension for annotating any webpage, shareable with peers
- Hard constraint: works without server-side state for v1
- Out of scope: real-time collaboration

${BOLD}## WHAT${RESET}
- ${CYAN}background.ts${RESET} — storage + sync (chrome.storage.local, Supabase planned)
- ${CYAN}content.ts${RESET} — injects UI; MutationObserver for SPA navigation
- ${CYAN}popup.tsx${RESET} — viewer for the current page's annotations

${BOLD}## Improvements${RESET} ${DIM}(ranked by leverage)${RESET}

${RED}1. [Architectural]${RESET} ${BOLD}background.ts${RESET} interleaves storage and sync.
   ${DIM}→ That's why your offline bug (issue #14) is hard to fix.${RESET}

${YELLOW}2. [Implementation]${RESET} ${BOLD}MutationObserver${RESET} debounce is 16ms.
   ${DIM}→ That's what's causing the CPU spike users reported on Twitter.${RESET}

${GREEN}3. [Polish]${RESET} Memoize the annotation list in ${BOLD}popup.tsx${RESET} if you feel like it.
EOF

sleep 2.5
echo
printf "%s\n" "${DIM}The architectural one goes first, tied to a real bug. Polish goes last.${RESET}"
sleep 2.8
