# Contributing

This repository is a reference template. Changes should improve either the demo
application, the rules, or the tooling without making the template harder to
adopt in another iOS project.

## Workflow

1. Create a focused branch.
2. Keep the change scoped to one concern.
3. Update docs when behavior, rules, or workflow change.
4. Run local checks.
5. Open a PR with the completed checklist.

Recommended branch prefixes:

```text
codex/<task-name>
docs/<task-name>
tooling/<task-name>
feature/<task-name>
```

## Required Local Checks

For documentation-only changes:

```bash
make demo
```

For code, tooling, or CI changes:

```bash
make ci
```

When changing the linter, also run a negative fixture or another targeted check
that proves the rule fails when it should.

## Review Expectations

Review should focus on:

- FSD layer and slice boundaries;
- dependency direction;
- whether a new abstraction is justified;
- whether docs and tooling stay aligned;
- whether checks prove the relevant behavior.

Avoid unrelated refactors in the same PR. If a cleanup is valuable but not needed
for the current change, split it into a follow-up.

## Documentation Expectations

Rules belong in `docs/rules`. The root README is an entry point, not the place
for every detail.

When adding a new rule, describe:

- what the rule protects;
- good examples;
- bad examples;
- whether it is enforced by tooling or by review.
