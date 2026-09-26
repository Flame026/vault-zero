# Vault Zero — Antigravity Workspace Instructions

This repository is Vault Zero, a production-oriented Flutter/Dart Android application. Read and follow `Vault Zero Project Guidelines.md` before changing code. The live source tree is the source of truth when documentation and implementation disagree.

## Operating mode

When the user has asked for continuous improvement, operate autonomously until the user explicitly says `STOP`.

Use this loop repeatedly:

1. Inspect the current implementation and tests before editing.
2. Identify the highest-value, lowest-risk improvement that is consistent with the project's constitution and current task.
3. Make the smallest coherent change that solves it.
4. Format affected Dart files.
5. Run the relevant tests and then the project's full verification checklist when practical.
6. Inspect command output and the final diff.
7. Keep only verified changes and continue to the next useful improvement.

Do not pause for routine permission-style questions, routine implementation choices, or ordinary refactoring decisions. When a requirement is genuinely ambiguous but a safe, reversible interpretation exists, choose the interpretation that best matches the existing architecture and document the assumption in the task summary rather than stopping.

Stop and request user input only for decisions that are materially irreversible or product-defining, such as:
- destructive or lossy database migrations;
- changing backup/restore compatibility in a breaking way;
- exposing or replacing signing credentials;
- publishing/releasing software or pushing to a remote repository;
- intentionally removing established user-facing functionality;
- introducing a major architectural direction that the existing constitution does not support.

## Product invariants

Vault Zero is:
- offline-first;
- a generic customizable database application;
- deliberately simple rather than spreadsheet-like;
- data-safety-first;
- layered: Presentation → Controller → Domain → Data → SQLite;
- Riverpod-based for state management;
- SQLite-backed through `sqflite`.

Never introduce domain-specific entities or product logic for one use case into the generic core.

Do not resurrect retired/rejected features from the project constitution. In particular, do not introduce spreadsheet formulas, file/media attachments, database templates, or extra user-facing field types unless the user explicitly approves a product milestone.

Preserve:
- database CRUD;
- field management and ordering;
- record CRUD;
- keyset pagination;
- SQLite foreign-key integrity;
- backup/restore;
- CSV import;
- Excel import/export;
- theme presets and light/dark/system behavior;
- responsive layouts;
- sequential keyboard-driven record entry.

## Architecture rules

Presentation code must not perform raw SQL or direct database transactions.

Controllers must own UI-facing mutation/state orchestration and use Riverpod.

Domain models/services/repository contracts must remain infrastructure-agnostic where the existing architecture requires it.

Data-layer code owns SQLite conversion, transactions, persistence validation, and import/export plumbing.

Prefer existing abstractions over new abstractions. Do not create wrappers, helpers, registries, or frameworks merely for stylistic reasons.

Before adding a dependency, check whether Dart, Flutter, or an existing package already solves the problem.

## UX and visual rules

Treat the existing Material 3 geometry, theme system, breakpoints, typography hierarchy, and surface system in `Vault Zero Project Guidelines.md` as design tokens, not suggestions.

Do not add screen-specific hardcoded colors when a theme color is available.

Do not replace a simple screen with a wizard, tab maze, or spreadsheet-like interaction unless explicitly requested.

Maintain accessibility, sensible focus order, usable touch targets, and clear destructive-action confirmation.

## Database safety

Assume user data is valuable and potentially irreplaceable.

Never casually change schema versioning, migration behavior, foreign keys, backup format, import semantics, or serialization.

For database changes:
- preserve existing records during migrations;
- use transactions for multi-step mutations;
- add or update regression tests;
- verify foreign-key and uniqueness behavior;
- test upgrade paths rather than testing only a fresh database.

Never silently discard user data to make a test or migration pass.

## Verification

For every meaningful code change, verify the result rather than inferring success.

Use the project's existing checklist:

```bash
flutter analyze
flutter test
flutter build apk --debug
git diff --check
```

Also use `dart format` on changed Dart files before final verification.

Never report a test, analyzer, formatter, build, or command as successful unless its actual output was observed.

If a verification step fails:
1. diagnose the root cause;
2. fix the cause;
3. rerun the failed verification;
4. do not paper over errors with ignores, disabled lints, skipped tests, or unrelated changes.

## Change discipline

Prefer small, reviewable, coherent changes.

Do not perform broad cleanup while implementing an unrelated feature.

Do not rename public concepts or files simply to make naming "nicer" unless that rename is part of the active task and all references are updated.

Do not change generated assets or build artifacts unless the task requires it.

Do not commit unverified code.

Local Git commits are allowed when a coherent, verified unit of work is complete, but never push to a remote without explicit user instruction.

## Security and workspace boundaries

Treat the repository as trusted source code but do not treat secrets as source code.

Never inspect, print, copy, or modify:
- `android/key.properties`;
- private signing keys such as `.jks` or `.keystore`;
- `.env` or equivalent secret/config files;
- SSH credentials or other unrelated credentials.

Do not put secrets into source code, logs, test fixtures, commit messages, or task summaries.

Do not use blanket staging such as `git add -A` when it could sweep unrelated files into a commit. Inspect `git status` and the diff first.

Never modify `.git/` internals directly.

Do not use `sudo`, destructive recursive deletion, disk-wiping commands, or unrelated system administration as a shortcut.

Keep all work scoped to the configured Vault Zero workspace unless the user explicitly expands the scope.

## Documentation synchronization

`Vault Zero Project Guidelines.md` is the project's engineering constitution.

Do not rewrite it on every task. Update it only when a real architectural/product decision changes the documented truth, and keep the update synchronized with the implementation.

When live code contradicts an old statement, verify the code, implement against the live architecture when appropriate, and update the documentation as part of the same coherent change.

## Continuous improvement priority

When choosing the next improvement, prioritize in this order:

1. correctness and data integrity;
2. reproducible bugs and failing tests;
3. user-data safety;
4. architectural violations and maintainability problems;
5. performance issues supported by evidence;
6. accessibility and UX friction;
7. visual polish;
8. documentation and developer ergonomics.

Do not invent improvements just to keep changing files. A clean bill of health is a valid stopping point for a cycle until the user supplies a new direction.
