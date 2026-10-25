#!/bin/sh
# lab-port.sh — prepare a pull request branch for the friend: his code, none of our process.
#   sh scripts/lab-port.sh <short-name> <code-commit-sha> [<sha> ...]
# Creates ../settlement-engine-port-<short-name> as a new worktree on branch lab-port-<short-name>,
# cut from the latest upstream/master, and cherry-picks the listed commits there. Refuses any
# commit that touches lab-only files. Nothing is pushed and no PR is opened.
set -u
[ "$#" -ge 2 ] || { echo "usage: sh scripts/lab-port.sh <short-name> <sha> [<sha> ...]"; exit 2; }
NAME="$1"; shift
ROOT="$(git rev-parse --show-toplevel)" || exit 2
cd "$ROOT" || exit 2
git fetch upstream || exit 1
# Files that exist only on lab (our rules, hooks and gate). A port commit must not touch them.
LABONLY='^(CLAUDE\.md|AGENTS\.md|docs/LANE_RULES\.md|scripts/lab-.*|\.husky/.*|\.claude/.*)$'
for sha in "$@"; do
  if git diff-tree --no-commit-id --name-only -r "$sha" | grep -E "$LABONLY"; then
    echo "REFUSING: $sha touches lab-only files above. Split the code from the process in separate commits."; exit 1
  fi
done
WT="$(dirname "$ROOT")/settlement-engine-port-$NAME"
git worktree add -b "lab-port-$NAME" "$WT" upstream/master || exit 1
cd "$WT" || exit 1
git cherry-pick -x "$@" || { echo "cherry-pick stopped; resolve in $WT, then 'git cherry-pick --continue'"; exit 1; }
# This worktree has HIS CLAUDE.md/AGENTS.md. Say what it is, in an untracked file.
cat >CLAUDE.local.md <<'LOCAL'
# Port worktree (Dustin's fork)
This worktree only carries cherry-picked code for a pull request to the friend. Do not edit
code here. His CLAUDE.md/AGENTS.md in this tree are HIS process, not rules for this work.
The rules are `docs/LANE_RULES.md` on branch `lab` in the main checkout. Port procedure there:
run `npm run check:tail; echo "exit=$?"` here, then stop and report to Dustin. No PR until he says so.
LOCAL
cp CLAUDE.local.md AGENTS.local.md
echo "ready: $WT (branch lab-port-$NAME). Next: ln -s \"$ROOT/node_modules\" node_modules  (or npm ci), then npm run check:tail; echo \"exit=\$?\""
