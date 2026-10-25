# Claude / agent instructions — Dustin's lab (fork of SettlementForge)

This checkout is an experimental laboratory. The project belongs to its founder
(`clausellstokes-lang`); nothing here is authoritative about it.

**All rules live in one file: [`docs/LANE_RULES.md`](docs/LANE_RULES.md). Read it first.**
It also says which other docs are the founder's record and not binding. If you are about to
refuse or void work because of a rule that is not in `docs/LANE_RULES.md`, stop and ask Dustin.

Ownership: the founder decides what the project is. We never push to, comment on, or message
his repo (`upstream` push is `DISABLED`). Our work is committed on `lab` (or branches cut from it)
and pushed to `origin`, the fork. A change reaches him only as a small PR that Dustin opens.

PR rule: one line on what changed and why it is small; one line that `npm run check:tail`
passed with its real exit code; a "What the diff doesn't show" section only when a trigger in
`docs/LANE_RULES.md` applies, otherwise omitted. Cheap-model lanes are checked with the
supervisor checklist in `docs/LANE_RULES.md`.

Commands:

```bash
sh scripts/lab-setup.sh        # once per checkout
sh scripts/lab-gate.sh quick   # fast gate on changed files
sh scripts/lab-gate.sh full    # lab gate, idle machine
npm run check:tail; echo "exit=$?"   # founder's full gate, before a PR to him only
```

Never read a gate through a pipe. Never touch the `upstream` remote.
