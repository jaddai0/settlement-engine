#!/bin/sh
# lab-setup.sh — one-time (and re-runnable) setup for a lab checkout.
#   sh scripts/lab-setup.sh
# 1. Fetches the friend's ledger branch into a local branch of the same name (a few of his
#    suites read it by local ref; without it they are red for a reason unrelated to your change).
# 2. Confirms the remotes and that upstream push is disabled.
# 3. Installs dependencies if node_modules is missing.
cd "$(git rev-parse --show-toplevel)" || exit 2
git fetch upstream +refs/heads/review-fixes-2026-07-08:refs/heads/review-fixes-2026-07-08 || exit 1
echo "origin   : $(git remote get-url origin)"
echo "upstream : $(git remote get-url upstream)   push: $(git remote get-url --push upstream)"
[ "$(git remote get-url --push upstream)" = DISABLED ] || { echo "REFUSING: upstream push is not DISABLED. Run: git remote set-url --push upstream DISABLED"; exit 1; }
[ -d node_modules ] || npm ci
echo "lab-setup: ok"
