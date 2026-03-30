# Daily Contribution Workflow

Use this workflow to build a real daily contribution habit (not fake activity).

## Daily Routine (10-20 minutes)

1. Run:

```bash
./scripts/daily_contribution.sh
```

2. Pick one meaningful micro-task:
- fix a small bug
- improve README/docs
- add a tiny UX improvement
- add/adjust a test

3. Record what you actually changed in `logs/daily/YYYY-MM-DD.md`.

4. Verify quickly:

```bash
swift build
```

5. Commit and push.

## Rules That Keep It Valuable

- Do not commit empty/no-op changes.
- Keep each daily change small but useful.
- Prefer one clear improvement over many noisy edits.
- If no code change today, improve docs with concrete value.
