# Vault Zero — Project Guidelines

> **Purpose:** This file is the working reference and project constitution for Vault Zero.
> AI coding agents (especially Antigravity) MUST read this file before making changes.
> Keep this document updated when an architectural or product decision changes.

---

## 1. Project Identity

**Project:** Vault Zero

**Platform:** Android

**Framework:** Flutter / Dart

**Product type:** Offline-first, customizable database application.

Vault Zero is a generic database app. Users can create their own databases, define fields, and store records without being locked into a predefined domain.

Example use cases:

- Books
- Movies
- Inventory
- Recipes
- Contacts
- Students
- Pokémon
- Board games
- Personal collections
- Any other structured personal data

### What Vault Zero is NOT

Vault Zero is **not** intended to become a spreadsheet application.

It should provide the flexibility of a database while remaining simple, focused, and pleasant to use.

Do not introduce spreadsheet-like complexity unless explicitly requested.

---

# 2. Product Philosophy

Priorities, in order:

1. Correctness
2. Data safety
3. Clean architecture
4. Maintainability
5. Good UX
6. Responsive design
7. Offline-first operation
8. Performance
9. Minimal dependencies

The project should be built like a real software product, not as a disposable prototype.

Avoid shortcuts that create future architectural debt.

---

## Current Version

**V3.0**

V3.0 incorporates the completed V2.8-C Legacy Retirement and V3.0-B CSV Import system.

## Completed Work

### V2.8-C — Product Consolidation
- Audited and completely removed Legacy Character Collector codebase, models, widgets, and navigation.
- Removed legacy `characters` table via SQLite migration (Schema Version 4).
- Moved Appearance controls (Theme color, Light/Dark mode) directly into main Settings screen.
- Renamed package to `vault_zero`.

### V3.0-B — CSV Import
- Implemented `TabularDataSource` abstraction and `CsvDataSource` streaming parser using `csv: ^8.0.0` (`csv.decoder`).
- Created `ImportService` for streaming, database creation, header normalization, and atomic rollback on failure.
- Implemented bulk write operation `RecordRepository.saveRecordsBatch` using single-transaction batching without N-query lookups.
- Added `CsvPreviewScreen` with cheap 5-row preview and editable target database name.
- Added comprehensive unit and integration tests covering parser edge cases, streaming, batching, and atomic rollback.

### V3.0-C — Excel Import
- Implemented `ExcelDataSource` (`excel: 4.0.6`) implementing `TabularDataSource`.
- Worksheet enumeration and selection (one worksheet per imported database).
- Deterministic CellValue-to-Text conversion (Text, Int, Double, Bool, Date, DateTime, Time, Formula).
- Added `ExcelPreviewScreen` matching responsive styling and worksheet selector.
- Added `Import Excel` to SettingsScreen.
- Added comprehensive test suite (`test/excel_import_test.dart`).

## Next Milestone

**V3.1 — Product Hardening / Future Milestones**

Explicitly removed from the old roadmap:

- Database Templates
- File Attachments

Do not reintroduce those features unless explicitly requested.

---

# 4. Tech Stack

## Core

- Flutter
- Dart
- Android
- Material 3

## State Management

- Riverpod
- `flutter_riverpod`

Use the existing Riverpod architecture.

Do not replace the state-management approach without an explicit architectural decision.

## Database

- SQLite
- `sqflite`

The production application uses the mobile SQLite implementation.

Tests use:

- `sqflite_common_ffi`

## IDs

Generic database entities use:

- UUID v4

The `uuid` package is already part of the project.

## Existing Important Packages

Do not add packages casually.

Before adding a dependency, first determine whether Flutter/Dart already provides the required functionality.

Existing packages may include functionality for:

- Riverpod
- SQLite
- UUID generation
- file picking
- sharing/export
- date formatting
- testing SQLite through FFI

Inspect `pubspec.yaml` before assuming a dependency is or is not available.

---

# 5. Architecture

Vault Zero follows a layered architecture.

General flow:

```text
UI
 ↓
Riverpod Controllers / Notifiers
 ↓
Domain Interfaces
 ↓
Data Repositories
 ↓
SQLite
```

## Presentation

Located under:

```text
lib/presentation/
```

Contains screens, widgets, and presentation-specific behavior.

Presentation code should not directly contain database implementation details.

## Domain

Located under:

```text
lib/domain/
```

Contains generic business models and repository contracts.

Important generic models include:

- `DatabaseDefinition`
- `FieldDefinition`
- `Record`
- `FieldValue`

The domain layer must remain generic.

### CRITICAL

Do not introduce Pokémon-specific, Character-specific, or other domain-specific assumptions into the generic domain layer.

---

# 6. Generic Database Model

Vault Zero is based around:

```text
Database
 ├── Fields
 └── Records
       └── Field Values
```

A database definition contains metadata and field definitions.

A field definition belongs to a database and has an ordering position.

A record belongs to a database.

A field value belongs to a record + field.

The database schema uses foreign keys and enforces:

```text
UNIQUE(record_id, field_id)
```

where applicable.

Database operations should preserve transactional integrity.

---

# 7. User-Facing Field Types

### IMPORTANT

The user-facing generic database field UI is intentionally simple.

The supported field types exposed to users are:

1. **Text**
2. **Boolean (Yes/No)**
3. **Choice**

Do not add additional field types such as:

- Integer
- Decimal
- Date
- Currency
- Rating
- URL
- Image

unless explicitly requested as a future product decision.

Internal implementation details may contain historical types if they still exist, but the user-facing field creation experience should remain limited to the approved types.

---

# 8. Record Entry UX

Record entry should prioritize fast sequential data entry.

Preferred behavior:

```text
Field 1
   ↓ Next
Field 2
   ↓ Next
Field 3
   ↓ Next
Field 4
   ↓ Done / Save
```

The keyboard Next action should move directly to the next field wherever appropriate.

Do not replace the sequential single-form entry experience with unnecessary multi-page flows.

Forms should remain comfortable on phones and constrained/centered on wider screens.

---

# 9. UI / UX Principles

Vault Zero should feel like a polished modern Android application.

Use:

- Material 3
- clear hierarchy
- appropriate spacing
- consistent component styling
- responsive layouts
- smooth state transitions
- sensible touch targets
- clear primary actions
- clean error states

Avoid:

- unnecessary visual clutter
- spreadsheet-like dense layouts
- arbitrary custom UI patterns
- excessive animations
- gratuitous dependencies
- inconsistent button styles
- huge empty tablet layouts

## Responsive Layout

Phone layouts should remain comfortable and efficient.

On wider screens:

- Database lists may use multi-column grids.
- Record lists may use multi-column grids.
- Field management should remain a constrained vertical reorderable list.
- Forms should be centered and constrained.
- Settings should be centered/constrained.

Current responsive breakpoint:

```text
600 logical pixels
```

Do not change the responsive strategy without a reason.

---

# 10. Theme System

Vault Zero has five themes:

1. Royal Purple
2. Ocean Blue
3. Emerald Green
4. Sunset Orange
5. Rose Pink

Each theme has:

- Light variant
- Dark variant

Theme selection and Light/Dark mode are application-wide settings.

## IMPORTANT

Appearance settings belong in the **main generic Settings screen**.

They must NOT require entering a Legacy section.

The theme architecture lives under:

```text
lib/core/theme/
```

The current theme architecture includes:

- `theme_preset.dart`
- `theme_provider.dart`
- `app_theme.dart`

Theme changes must apply consistently across the whole application.

Do not create individual screen-specific themes.

---

# 11. Settings

The main Settings screen should contain application-wide controls.

Current responsibilities include:

- Appearance
- Backup Vault
- Restore Vault

Appearance should provide:

- Theme selection
- Light/Dark mode

Keep settings logically grouped and easy to discover.

---

# 12. Data Safety

Vault Zero is offline-first.

User data should not depend on network connectivity.

Database operations must be treated as data-sensitive operations.

For destructive actions:

- clearly communicate what will happen
- require appropriate confirmation
- do not silently delete user data

Backup/restore functionality must remain intact unless explicitly being changed.

---

# 13. Export / Import

Existing export functionality must remain supported.

V3.0 will add import capabilities.

## Planned Import

### CSV Import

Import should map external tabular data into the generic Vault Zero database model.

It should not turn Vault Zero into a spreadsheet editor.

Important considerations for import implementation:

- header handling
- field creation/mapping
- data validation
- malformed rows
- duplicate handling
- empty values
- transaction safety
- large files
- user confirmation before creating/changing data

### Excel Import

Excel import should follow the same generic database principles established by CSV import.

Do not build two unrelated import architectures.

---

# 14. Legacy System

## Status

The Legacy Character application is being retired.

The original Character Collector was never publicly distributed.

Therefore:

- No user migration requirement exists.
- Legacy compatibility should not dictate the new architecture.
- Legacy code should not remain merely "just in case."

The current V2.8-C milestone is responsible for auditing and removing it.

Expected eventual result:

```text
lib/legacy/
```

is removed.

Legacy Character UI/navigation is removed.

Legacy-only repositories/controllers/models/widgets are removed.

Legacy-only database schema is removed where safe.

Legacy-only preferences/migration logic is removed where safe.

### IMPORTANT

Do not preserve legacy architecture in the generic system.

The generic database engine is the future product.

---

# 15. Development Workflow

Before changing code:

1. Read this file.
2. Inspect the relevant existing implementation.
3. Understand the current architecture.
4. Identify affected files.
5. Identify regression risks.
6. Make the smallest coherent implementation.

Do not immediately start rewriting files based only on filenames or assumptions.

## During implementation

- Keep changes scoped to the requested milestone.
- Preserve working behavior.
- Avoid unrelated refactors.
- Do not introduce dependencies without justification.
- Do not invent APIs or architecture.
- Reuse existing patterns when appropriate.
- Prefer simple Flutter/Dart solutions.

## After implementation

Always run:

```bash
flutter analyze
flutter test
flutter build apk --debug
git diff --check
```

Then inspect:

```bash
git status
git diff --stat
git diff
```

For UI changes, also run:

```bash
flutter run
```

and perform actual manual verification.

### IMPORTANT

Never claim a command was run unless its output was actually observed.

Never claim visual verification based on code inspection alone.

---

# 16. Git Workflow

Work on `main` unless explicitly instructed otherwise.

Before starting a milestone:

```bash
git status
git log -3 --oneline
```

Prefer starting from:

```text
working tree clean
```

After a coherent milestone is verified:

```bash
git add ...
git commit -m "..."
git push origin main
```

After pushing:

```bash
git status
git log -3 --oneline
```

The desired state is:

```text
On branch main
Your branch is up to date with 'origin/main'.
nothing to commit, working tree clean
```

Do not commit broken code just to create a checkpoint.

Do not push unverified changes.

---

# 17. Testing Expectations

Minimum verification for code changes:

```text
flutter analyze     → No issues
flutter test        → All tests pass
flutter build apk --debug → Successful
git diff --check    → No output
```

UI changes additionally require manual testing on the running application.

For responsive changes, verify at least:

- phone
- wider/tablet layout

For theme changes, verify:

- all five themes
- Light mode
- Dark mode

For data changes, verify:

- create
- read/list
- edit
- delete
- relevant import/export/backup behavior

---

# 18. AI Agent Rules

This section is especially important for Antigravity and other coding agents.

### Rule 1 — Do not hallucinate the repository

The repository is the source of truth.

Do not assume a file, class, provider, API, feature, or architecture exists.

Inspect it first.

### Rule 2 — Do not trust stale plans over the code

Roadmaps describe intended work.

The current repository describes reality.

If they conflict:

1. inspect the repository
2. identify the difference
3. report it
4. do not silently rewrite architecture

### Rule 3 — Do not resurrect rejected features

Do not reintroduce:

- Database Templates
- File Attachments
- unnecessary field types
- Legacy Character UI

unless the user explicitly changes the product decision.

### Rule 4 — Ask rather than guess

If requirements are ambiguous and the decision materially affects architecture or user experience, stop and ask.

Do not invent requirements.

### Rule 5 — Avoid unnecessary rewrites

A small feature should not become an architectural rewrite.

Preserve existing working code unless there is a demonstrated reason to change it.

### Rule 6 — Protect existing functionality

When changing UI, verify that existing behavior remains intact.

Especially protect:

- database CRUD
- field CRUD
- record CRUD
- record editing
- pagination
- export
- backup
- restore
- theme persistence
- responsive behavior

### Rule 7 — No unverified claims

Never report:

"tests passed"

unless tests were actually run and passed.

Never report:

"build successful"

unless the build actually completed successfully.

Never report:

"looks good"

as a substitute for manual UI verification.

### Rule 8 — Explain regressions

If an implementation introduces a compiler/analyzer error:

- identify the actual root cause
- fix the underlying problem
- rerun verification

Do not blindly patch individual cascading errors.

### Rule 9 — Dependencies

Before adding a package:

1. Check whether Flutter/Dart already provides the capability.
2. Check existing dependencies.
3. Explain why the dependency is necessary.
4. Only then add it.

### Rule 10 — Keep the product simple

Vault Zero's strength is its simplicity.

When two solutions work, prefer the one with:

- fewer dependencies
- fewer abstractions
- fewer moving parts
- clearer code
- better maintainability

---

# 19. Current Roadmap

## V2.8 — Polish

STATUS: Complete

- UX polish
- Themes
- Light/Dark
- Tablet/responsive layouts

## V2.8-C — Product Consolidation

STATUS: Complete

- [x] Audit Legacy
- [x] Remove Legacy application
- [x] Remove legacy-only schema/code
- [x] Remove obsolete preferences/migration logic
- [x] Move Appearance to main Settings
- [x] Remove Legacy navigation
- [x] Verify entire application

## V3.0-B — CSV Import

STATUS: Complete

- [x] `TabularDataSource` abstraction
- [x] `CsvDataSource` streaming parser (`csv: ^8.0.0`)
- [x] `ImportService` batching & rollback
- [x] `RecordRepository.saveRecordsBatch` single-transaction bulk write
- [x] `CsvPreviewScreen` UI & `SettingsScreen` integration
- [x] Unit and integration test suite

## V3.0-C — Excel Import

STATUS: Complete

- [x] `ExcelDataSource` (`excel: 4.0.6`) implementing `TabularDataSource`
- [x] Deterministic CellValue-to-Text conversion
- [x] `ExcelPreviewScreen` UI with worksheet selection
- [x] `SettingsScreen` integration under DATA
- [x] Comprehensive test suite (`test/excel_import_test.dart`)

## V3.1 — Visual UX Refinement Pass

STATUS: Complete

- [x] Theme Chooser Redesign (`ThemePickerSheet`) with human-readable labels, rich descriptions, active checkmark badges, and responsive modal presentation (bottom sheet on phone, centered modal on tablet/desktop)
- [x] Responsive Settings Layout with 3 breakpoints: single-column grouped cards (<720px), centered constrained (720-899px), and two-pane master-detail layout (>=900px)
- [x] Dashboard & Card Refinements (`DatabaseCard`, `RecordCard`, `FieldCard`) with 16px border radius, `surfaceContainerLow` elevation, squircle icon badges, and adaptive grid sizing
- [x] Global Visual Consistency: standardized typography, section headers, 16px/24px geometry system, and polished empty/loading/error states across all screens

Explicitly not planned:

- Database Templates
- File Attachments

## Future

Future features should be decided based on the actual needs of Vault Zero rather than automatically following an old roadmap.

---

# 20. Current Task

At the beginning of a new development session, update this section with the current task.

Current task:

```text
V3.1 Visual UX Refinement Pass Complete — Awaiting Verification.
```

---

# 21. Golden Rule

When uncertain:

> **Inspect first. Preserve working behavior. Ask rather than guess. Verify before claiming success.**

Vault Zero should become a reliable, polished, offline-first generic database application — not a collection of unrelated features.
