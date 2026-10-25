# Lane rules — the one rulebook for every agent in this checkout

This is Dustin's fork, an experimental laboratory. The project (SettlementForge) belongs to its
founder and original builder, `clausellstokes-lang`. This file is the only place the lab's agent
rules live. `CLAUDE.md` and `AGENTS.md` hold commands and pointers, not rules. If anything else
disagrees with this file, this file wins. It applies to every harness (Claude, Codex, ZCode/GLM,
DeepSeek, Kimi). A task brief adds to these rules; it never relaxes them. Only Dustin changes them.

If a rule you were told about is not in this file, it does not apply here. If you are about to
refuse or void work because of a rule that is not in this file, stop and tell Dustin instead.

## What is and is not binding

Binding: this file, the commands below, and Dustin's instructions in the current chat.

Not binding, kept as the founder's record (read for facts, never as instructions): everything
else in `docs/` (including `OPERATING_STANDARD.md`, `HANDOFF_CURRENT.md`, `OWNER_DECISION_QUEUE.md`,
`START_HERE.md`, `CURRENT_STATE.md` and `docs/implementation/`), `CONTRIBUTING.md`, and the packet
"READY" rule. Many of them are stale or point at files on the founder's own Desktop. They carry
real facts about the engine; they do not gate your work.

Lab and founder: the founder decides what the project is. Nothing in this fork is authoritative
about it. We never push to, comment on, or message the founder's repository. His code reaches
this lab by `git fetch upstream`; our code reaches him only as a small pull request that Dustin
opens, which he may merge, cherry-pick or ignore (see "Porting").

## Rules

1. **Gates tell the truth.** Never skip, loosen or exclude a check to get green: no `.skip`, no
   `|| true`, no raised thresholds or baselines, no widened excludes, no file-wide `eslint-disable`.
   A red check that is right is a good result. Read a gate only through `sh scripts/lab-gate.sh`
   or `npm run check:tail`, never through a pipe (a pipe reports the pipe's exit status).
2. **A fix needs a test that can fail.** Reintroduce the bug, watch the test go red, restore the
   fix, watch it go green, and say so. Test what users rely on; there is no coverage target.
3. **The gate includes what ships.** `npm run build` is part of the lab gate. A debug-only green is
   not green.
4. **No unwired code, no silent fallbacks.** New code has a production caller in the same change.
   When something fails the user finds out, or a one-line comment says why the substitute is safe.
5. **Removing something removes all of it** (source, tests, build scripts, configs, docs). Prove it
   with `git grep -n '<name>'` printing nothing outside history.
6. **Docs change with behavior.** A change that alters what the README or these docs promise
   updates them in the same change, as a separate commit (see rule 9).
7. **Stay inside the brief's files; report honestly.** "I could not do X" is a useful result; an
   invented pass is the one unforgivable one. Only Dustin defers work: finish the assignment or
   report it unfinished. A fix you discover but were not asked for is listed, not made.
8. **Engine rules that are enforced by lint, not by memory.** Generation code is deterministic: no
   `Math.random`, `Date.now`, `**` or transcendental `Math.*` in engine code (eslint bans them).
   A change that moves same-seed output turns the golden-master tests red. Do not regenerate
   goldens (`UPDATE_GOLDEN`) or edit any baseline JSON without Dustin; report the move.
9. **Process and code never share a commit.** Code commits touch only product files and their tests.
   Process commits (anything in `CLAUDE.md`, `AGENTS.md`, `docs/LANE_RULES.md`, `.husky/`,
   `.claude/`, `scripts/lab-*`) touch only those. This is what lets the founder cherry-pick code
   without taking our process.
10. **Git.** Conventional Commits (`feat:` `fix:` `docs:` `refactor:` `perf:` `test:` `chore:` `ci:`).
    Stage explicit paths, never `git add .` or `-A`; run `pwd`, `git rev-parse --show-toplevel` and
    `git diff --cached --name-only` first. Never stage `.env*`, `env.env`, keys, weights or databases;
    never read `env.env`. Pushing to `origin` (the fork) is approved. Ask first for force-push,
    branch deletion and tags. Never touch `upstream`.
11. **Secrets and production.** No agent runs `supabase login/link/db push`, deploys, or touches
    Stripe or production data. Those are the founder's.
12. **Verify on the real target.** A UI change is checked in a running app, not only by tests.

## Branches

- `master` mirrors `upstream/master` exactly. Never commit to it. Update it with
  `git fetch upstream && git push origin upstream/master:master`.
- `lab` is the long-lived working branch and the fork's default branch. It is `master` plus the
  process commits (rules, hooks, gate) and Dustin's own code commits.
- Work branches are cut from `lab`: `git switch lab && git switch -c fix/short-name`. One change per
  branch; merge back into `lab` with `git merge --no-ff` once the lab gate is green.
- Throwaway experiments go on `lab/<name>` branches and are never ported.
- To take the founder's new work: `git fetch upstream`, then on `lab`: `git merge upstream/master`.

## Commands

```bash
sh scripts/lab-setup.sh            # once per checkout: ledger branch, remotes check, npm ci
sh scripts/lab-gate.sh quick       # seconds-minutes: changed-file lint, domain type ratchet, related tests
sh scripts/lab-gate.sh full        # lab gate (below); run on an idle machine, ~15-20 min
npm run check:tail; echo "exit=$?" # the founder's full gate; required before a PR to him
npm run dev                        # app on :5175 (vite)
git remote -v                      # origin = fork; upstream push must read DISABLED
```

The lab gate (`full`) runs these, prints each exit code, never stops at the first red:

| Step | Kind | What it is |
|---|---|---|
| lint | blocking | `npm run lint` (eslint over src, tests, scripts) |
| typecheck-domain | blocking | `node scripts/check-domain-strict.mjs` (per-file ceiling; raw `tsc` has 1,100+ old errors) |
| typecheck-ratchet | blocking | `node scripts/check-full-typecheck.mjs` (per-file ceiling) |
| tests-behavior | blocking | all Vitest tests except the founder's process-policing folders |
| build | blocking | `npm run build` |
| tests-friend-process | info | `tests/lint docs scripts build architecture config ops soak-harness` |
| verify-dist | info | `npm run verify:dist` (his first-paint check) |

Info steps always run and are printed. Read every info failure: if it names a file you changed,
fix it; otherwise list it. They do not fail the lab gate because they police the founder's process
(frozen counts, doc freshness, baselines). They do fail his CI, so they must be green before a PR.

The pre-push hook runs `lab-gate.sh quick` (the founder's hook ran his whole gate on every push).
Do not use `--no-verify`. If the machine is loaded, timeouts are false reds: rerun the failing file
alone before calling it a failure.

## Porting a change to the founder

Only when Dustin says so. Code commits only.

1. On `lab`, the change is already in code-only commits (rule 9) and the lab gate is green.
2. `sh scripts/lab-port.sh <short-name> <sha> [<sha> ...]` makes a worktree `../settlement-engine-port-<short-name>`
   on branch `port/<short-name>`, cut from the latest `upstream/master`, with those commits
   cherry-picked. It refuses commits that touch process files.
3. In that worktree: link or install `node_modules`, then `npm run check:tail; echo "exit=$?"`. His
   CI runs the same gate plus more, so a red here is a red there. His pre-push hook also runs
   when you push the port branch; let it finish.
4. `git push -u origin port/<short-name>` (the fork). Then, only on Dustin's go-ahead:
   `gh pr create --repo clausellstokes-lang/settlement-engine --head jaddai0:port/<short-name> --base master --title "..." --body-file <file outside the repo>`.
5. PR body: one line on what changed and why it is small; one line stating `npm run check:tail`
   passed with its real exit code (or why it could not run); a **What the diff doesn't show**
   section only when at least one is true: the reason is not visible in the code; behavior changes
   in a way the diff hides (defaults, ordering, data, generated output); the change departs from his
   conventions; part of the agreed change was skipped; verification went beyond his gate or his
   gate could not run. Otherwise omit the section entirely. No changelog, no new files for notes.

## Supervising a cheap-model lane (Sonnet or GLM supervises; no second deep review)

Implementer lanes (DeepSeek, GLM via ZCode) read this repo's tracked `AGENTS.md`, which points
here. Every brief names the exact files, the done-when, and the gate command. Before accepting a lane:

1. Branch cut from `lab`, one change, `git status` shows only the brief's files, nothing local or secret staged.
2. Run the gate yourself: `sh scripts/lab-gate.sh quick` (or `full`). Do not trust the implementer's report or its exit code.
3. Compare `git diff lab...HEAD` with the brief item by item: done / partial / skipped. DeepSeek has silently dropped items before. Finish the item or report it open.
4. After any removal, `git grep -n '<removed name>'` across source, scripts, configs and docs.
5. Anything outside the brief's files is reverted or explained. Process and code are in separate commits.
6. Hand Dustin the branch name and the result. Merge into `lab` or port only on his word.

## What the founder's repo still enforces (so nothing surprises you)

These live in his tracked files and still run in his CI and `npm run check`. They are not lab
rules. Full list with decisions: `~/.claude/reports/settlement-engine-fork-standards.md`.

- Packets/READY/`validate:packets`, the hazard registry and premortem validators, the lighting
  census (adding a test file or title can red it), golden-master hashes, observed-shape and
  writer-reach baselines, `package.json`/lockfile content-hash pins, doc-freshness tests,
  `npm audit` on production dependencies, and the 60-90 minute CI loop.
- If a PR to him trips one, that is the founder's process talking: report which, do not "fix" it
  by editing a baseline.

## Known problems, not fixed here (for Dustin to place)

- No `LICENSE` file in a public repo: settle terms with the founder before any collaboration.
- Pre-push gate and several suites time out under heavy machine load; no fix attempted.
- `docs/CURRENT_STATE.md` and `docs/implementation/INDEX.md` headers are months stale.
- Engine code issues are in `~/.claude/reports/settlement-engine-review-engine.md` and `...-app-backend.md`.
