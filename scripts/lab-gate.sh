#!/bin/sh
# lab-gate.sh — the lab's gate (Dustin's). One command, every step printed with its own exit
# code, no pipes, no fail-fast, so one red step never hides the rest.
#
#   sh scripts/lab-gate.sh quick   changed-file lint + domain types + tests related to the diff
#   sh scripts/lab-gate.sh full    lint, both type configs, behavior tests, build  (BLOCKING)
#                                  + the friend's process tests and dist check     (INFO)
#   sh scripts/lab-gate.sh help
#
# BLOCKING steps decide the exit code. INFO steps are the friend's own policing tests
# (tests/lint, docs, scripts, build, architecture, config, ops, soak-harness) and his
# first-paint check. They always run and are always printed; they do not fail the lab
# gate, because they police his process (frozen counts, doc freshness, baselines).
# They DO block a pull request to him: his CI runs them, so `npm run check:tail` must be
# green on the port branch before any PR (docs/LANE_RULES.md, "Porting").
#
# Exit: 0 all BLOCKING steps green, 1 any BLOCKING step red, 2 usage.
# Logs: $TMPDIR/lab-gate.<pid>/<step>.log (path printed at the end).

MODE="${1:-help}"
case "$MODE" in quick|full) ;; *)
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; [ "$MODE" = help ] && exit 0; exit 2 ;;
esac

ROOT="$(git rev-parse --show-toplevel)" || exit 2
cd "$ROOT" || exit 2
DIR="${TMPDIR:-/tmp}/lab-gate.$$"
mkdir -p "$DIR"
FAILED=0
SUMMARY="$DIR/summary.txt"
: >"$SUMMARY"

# step <BLOCKING|INFO> <name> <command...>
step() {
  kind="$1"; name="$2"; shift 2
  start=$(date +%s)
  "$@" >"$DIR/$name.log" 2>&1
  code=$?
  secs=$(( $(date +%s) - start ))
  if [ "$code" -eq 0 ]; then verdict=PASS; else verdict=FAIL; fi
  if [ "$code" -ne 0 ] && [ "$kind" = BLOCKING ]; then FAILED=1; fi
  line=$(printf '%-9s %-4s %-26s exit=%-3s %4ss' "$kind" "$verdict" "$name" "$code" "$secs")
  echo "$line" | tee -a "$SUMMARY"
  if [ "$code" -ne 0 ]; then echo "          last lines of $DIR/$name.log:"; tail -n 12 "$DIR/$name.log" | sed 's/^/          | /'; fi
}

# The ledger branch must exist locally for a few suites (docs/LANE_RULES.md, "Setup").
git rev-parse --verify -q refs/heads/review-fixes-2026-07-08 >/dev/null \
  || echo "note: local branch review-fixes-2026-07-08 is missing; run: sh scripts/lab-setup.sh"

if [ "$MODE" = quick ]; then
  BASE="${LAB_BASE:-}"
  if [ -z "$BASE" ]; then
    if git rev-parse --verify -q origin/lab >/dev/null; then BASE=origin/lab; else BASE=HEAD~1; fi
  fi
  CHANGED="$DIR/changed.txt"
  { git diff --name-only --diff-filter=d "$BASE"; git diff --name-only --diff-filter=d; git ls-files --others --exclude-standard; } \
    | sort -u | grep -E '\.(js|jsx|mjs|cjs)$' >"$CHANGED"
  echo "quick: $(wc -l <"$CHANGED" | tr -d ' ') changed JS files against $BASE"
  if [ -s "$CHANGED" ]; then
    step BLOCKING lint-changed sh -c 'xargs npx eslint <"$1"' _ "$CHANGED"
    step BLOCKING tests-related sh scripts/gate-mutex.sh --run -- sh -c 'xargs npx vitest related --run <"$1"' _ "$CHANGED"
  fi
  step BLOCKING typecheck-domain node scripts/check-domain-strict.mjs
else
  step BLOCKING lint npm run lint
  step BLOCKING typecheck-domain node scripts/check-domain-strict.mjs
  step BLOCKING typecheck-ratchet node scripts/check-full-typecheck.mjs
  step BLOCKING tests-behavior sh scripts/gate-mutex.sh --run -- npx vitest run \
    --exclude 'tests/lint/**' --exclude 'tests/docs/**' --exclude 'tests/scripts/**' \
    --exclude 'tests/build/**' --exclude 'tests/architecture/**' --exclude 'tests/config/**' \
    --exclude 'tests/ops/**' --exclude 'tests/soak-harness/**' --exclude 'e2e/**'
  step BLOCKING build npm run build
  step INFO tests-friend-process sh scripts/gate-mutex.sh --run -- npx vitest run \
    tests/lint tests/docs tests/scripts tests/build tests/architecture tests/config tests/ops tests/soak-harness
  step INFO verify-dist npm run verify:dist
fi

echo
if [ "$FAILED" -eq 0 ]; then echo "lab-gate $MODE: BLOCKING steps green (exit 0)"; else echo "lab-gate $MODE: a BLOCKING step is RED (exit 1)"; fi
echo "logs: $DIR"
exit "$FAILED"
