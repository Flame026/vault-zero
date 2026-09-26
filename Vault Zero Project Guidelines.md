# Vault Zero — Project Guidelines & Constitution

> **Purpose:** This document is the definitive working reference, technical specification, and engineering constitution for Vault Zero.
> AI coding agents (especially Antigravity) and human contributors MUST read and adhere to this file before making any changes.
> Always keep this document synchronized whenever an architectural, domain, or product decision evolves.

---

## 1. Project Identity

- **Project Name:** Vault Zero
- **Package Name:** `vault_zero`
- **Platform:** Android
- **Framework:** Flutter / Dart (SDK `^3.12.2`)
- **Product Type:** 100% Offline-First, Customizable Generic Database Application

Vault Zero is a generic, customizable database application for mobile devices. It empowers users to build their own structured databases, define custom fields, and store, organize, edit, import, and export records without being locked into any predefined domain.

### Example Use Cases
- Personal Collections & Inventories
- Book & Movie Logs
- Recipes & Meal Planners
- Contacts & Directory Lists
- Study Notes & Flashcards
- Gaming Logs & Pokémon Trackers
- Board Game Records
- Any structured personal data

### What Vault Zero is NOT
- **Vault Zero is NOT a spreadsheet application.** It provides the structure, relationships, and integrity of a relational database while remaining simple, fast, and pleasant to use on a phone or tablet. Do not introduce spreadsheet-like complexity (e.g. formula engines, arbitrary cell calculations, infinite grid navigation) unless explicitly requested.
- **Vault Zero is NOT a cloud SaaS app.** It is strictly offline-first. User data belongs entirely to the user and stays on their device.
- **Vault Zero is NOT a bloated multi-tool.** Its strength is simplicity, visual elegance, fast sequential data entry, and bulletproof data safety.

---

## 2. Product Philosophy & Priorities

Engineering decisions must strictly adhere to the following priority hierarchy:

```text
1. Correctness              (Zero data corruption, exact type handling)
2. Data Safety              (Foreign key integrity, atomic transactions, reliable backup/restore)
3. Clean Architecture       (Layered separation: UI → Controllers → Domain → Data → SQLite)
4. Maintainability          (Readable, self-explanatory code with minimal moving parts)
5. User Experience (UX)     (Fast sequential entry, sensible defaults, clear dialogs)
6. Responsive Design        (Adaptive phone, tablet, and wide-screen layouts)
7. Offline-First Operation  (No cloud dependency, no silent network reliance)
8. High Performance         (Keyset pagination, single-transaction batching)
9. Minimal Dependencies     (Strict evaluation before adding external packages)
```

The project is built as a production-grade software product, not a disposable prototype. Avoid shortcuts, hacky workarounds, or premature abstractions that create future architectural debt.

---

## 3. Version History & Milestone Status

### Current Version: **V3.1+ (Product Hardened & Visually Refined)**

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                             MILESTONE STATUS                                │
├──────────┬─────────────────────────────────────────────────┬────────────────┤
│ Version  │ Focus / Scope                                   │ Status         │
├──────────┼─────────────────────────────────────────────────┼────────────────┤
│ V2.8     │ UI Polish, Theme Engine, Light/Dark Modes       │ Complete       │
│ V2.8-C   │ Product Consolidation & Legacy Retirement       │ Complete       │
│ V3.0-B   │ CSV Import Pipeline (Streaming & Batching)      │ Complete       │
│ V3.0-C   │ Excel Import Pipeline (Worksheet & Cell Parser) │ Complete       │
│ V3.1     │ Visual UX Refinement & Responsive Master-Detail │ Complete       │
│ V3.2+    │ Search, Filter, & Large-Dataset Hardening       │ Future / Active│
└──────────┴─────────────────────────────────────────────────┴────────────────┘
```

### Completed Milestones Detail

#### V2.8 — UI & Responsive Foundation
- Built the 5-preset theme engine with dedicated Light and Dark variants.
- Implemented responsive layout breakpoints for phone and tablet form factors.
- Standardized form entry components and navigation flows.

#### V2.8-C — Product Consolidation & Legacy Retirement
- Audited and completely removed all legacy Character Collector codebase, models, widgets, and navigation.
- Executed SQLite migration to Schema Version 4 (dropping legacy `characters` table).
- Moved Appearance controls (Theme picker, Light/Dark mode) directly into the main Settings screen.
- Renamed the Flutter package to `vault_zero`.

#### V3.0-B — CSV Import Pipeline
- Designed and implemented the generic `TabularDataSource` abstraction.
- Implemented `CsvDataSource` streaming parser using `csv: ^8.0.0` (`csv.decoder`).
- Built `ImportService` with streaming row processing, header normalization, and atomic rollback on failure.
- Implemented high-performance bulk write `RecordRepository.saveRecordsBatch` using single SQLite transaction batching.
- Added `CsvPreviewScreen` with cheap 5-row preview and editable target database name.
- Added full unit and integration test coverage for parser edge cases, malformed rows, and rollback behavior.

#### V3.0-C — Excel Import Pipeline
- Implemented `ExcelDataSource` using `excel: ^4.0.6` conforming to `TabularDataSource`.
- Added worksheet enumeration and user selection (one worksheet per imported database).
- Implemented deterministic `CellValue`-to-text conversion (Text, Int, Double, Bool, Date, DateTime, Time, Formula).
- Created `ExcelPreviewScreen` with responsive worksheet selection and preview table.
- Integrated Excel Import into `SettingsScreen` under Data Management.
- Added comprehensive test suite (`test/excel_import_test.dart`).

#### V3.1 — Visual UX Refinement Pass
- **Redesigned Theme Chooser (`ThemePickerSheet`):** Added human-readable labels, rich descriptions, active checkmark badges, and responsive modal presentation (bottom sheet on mobile, centered modal on tablet/desktop).
- **Responsive Settings Layout:** Implemented 3 adaptive breakpoints: single-column grouped cards (<720px), centered constrained (720–899px), and two-pane master-detail layout (≥900px).
- **Dashboard & Card Geometry:** Unified 16px corner radius, `surfaceContainerLow` elevation, squircle icon badges, and adaptive grid sizing across `DatabaseCard`, `RecordCard`, and `FieldCard`.
- **Global Visual Consistency:** Standardized typography hierarchy, section headers, 16px/24px geometry system, and polished empty/loading/error states across all screens.

---

## 4. Tech Stack & Dependencies

### Core Framework
- **Flutter SDK:** Flutter standard SDK
- **Dart SDK:** `^3.12.2`
- **UI System:** Material 3 (`useMaterial3: true`)
- **Target Platform:** Android (min SDK 21)

### State Management
- **Riverpod:** `flutter_riverpod: ^2.5.1`
- Use `AsyncNotifier` and `FamilyAsyncNotifier` for controllers.
- Use `FutureProvider` for asynchronous repository and service dependencies.
- Do NOT introduce alternate state management libraries (e.g. Bloc, Provider, GetX).

### Local Persistence & Storage
- **SQLite Engine:** `sqflite: ^2.4.2`
- **Test SQLite (Desktop/FFI):** `sqflite_common_ffi: ^2.3.3`
- **Path Resolution:** `path: ^1.9.1`, `path_provider: ^2.1.5`
- **File Picker:** `file_picker: ^12.0.0-beta.7`

### Data Ingestion & Export
- **CSV Parser:** `csv: ^8.0.0`
- **Excel Parser & Generator:** `excel: ^4.0.6`
- **Native Sharing:** `share_plus: ^13.3.0`

### Utilities & Formatting
- **ID Generation:** `uuid: ^4.4.0` (UUID v4 for all database entities)
- **Internationalization & Dates:** `intl: ^0.20.3`

### Development & Linting
- **Test Framework:** `flutter_test` (SDK)
- **Linter:** `flutter_lints: ^6.0.0`
- **Launcher Icons:** `flutter_launcher_icons: ^0.14.4`

### Dependency Policy
- **Never add dependencies casually.**
- Before proposing any package, verify whether Flutter/Dart built-in libraries or existing packages already provide the capability.
- Explain the technical rationale before introducing any new dependency.

---

## 5. Layered Architecture

Vault Zero follows a strict layered architecture:

```text
┌─────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                      │
│      Screens, Responsive Views, Dialogs, Sheets, Cards      │
└──────────────────────────────┬──────────────────────────────┘
                               │ watches / dispatches
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     CONTROLLER LAYER                        │
│      Riverpod AsyncNotifiers (State mutations, UI logic)    │
└──────────────────────────────┬──────────────────────────────┘
                               │ calls contracts
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                          │
│     Models (Entities), Service Logic, Repository Interfaces │
└──────────────────────────────┬──────────────────────────────┘
                               │ implements contracts
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                        DATA LAYER                           │
│   SQLite Repositories, JSON Backup Engine, Tabular Parsers  │
└──────────────────────────────┬──────────────────────────────┘
                               │ queries / writes
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    PERSISTENCE LAYER                        │
│       SQLite Database (sqflite) + Foreign Key Cascades      │
└─────────────────────────────────────────────────────────────┘
```

### Directory Structure & Responsibilities

```text
lib/
├── main.dart                               # App entry point, splash screen, theme attachment
├── core/
│   ├── database/
│   │   └── database_provider.dart          # SQLite openDatabase, schema migrations (v1-v4), FK pragma
│   ├── preferences/
│   │   └── preferences_repository.dart     # App-level preferences (theme preset, theme mode)
│   ├── providers.dart                      # Core Riverpod providers (repositories, services)
│   └── theme/
│       ├── app_theme.dart                  # Material 3 ThemeData generation, color schemes, component themes
│       ├── theme_preset.dart               # 5 Curated theme presets (Royal Purple, Ocean Blue, etc.)
│       └── theme_provider.dart             # Riverpod notifier for app-wide theme state & persistence
├── domain/
│   ├── models/
│   │   ├── database_definition.dart        # Database metadata entity
│   │   ├── field_definition.dart          # Field definition entity, FieldType enum, FieldConfig
│   │   ├── field_value.dart               # Polymorphic FieldValue hierarchy & JSON serialization
│   │   ├── record.dart                    # Record entity holding Map<String, FieldValue>
│   │   ├── record_page.dart               # Keyset cursor pagination models (RecordCursor, RecordPage)
│   │   └── vault_backup.dart              # Full-vault JSON backup schema & FK integrity validation
│   ├── repositories/
│   │   ├── backup_restore_service.dart     # Contract for exportVault() / restoreVault()
│   │   ├── record_repository.dart          # Contract for single/batch record CRUD & keyset pagination
│   │   └── schema_repository.dart          # Contract for database and field schema CRUD
│   └── services/
│       └── import_service.dart             # Tabular import pipeline, header normalization, batching, rollback
├── data/
│   ├── importers/
│   │   ├── tabular_data_source.dart        # TabularDataSource abstraction (getHeaders, getRows)
│   │   ├── csv_data_source.dart            # Streaming CSV parser implementation
│   │   └── excel_data_source.dart          # Excel parser implementation with CellValue conversion
│   └── repositories/
│       ├── json_backup_restore_service.dart # VaultBackup JSON export & atomic transaction restore
│       ├── sqlite_record_repository.dart   # SQLite implementation of RecordRepository (keyset paging, batching)
│       └── sqlite_schema_repository.dart   # SQLite implementation of SchemaRepository (db & field schema)
└── presentation/
    ├── databases/
    │   ├── controllers/
    │   │   └── database_list_controller.dart # AsyncNotifier for Database list CRUD
    │   ├── database_list_screen.dart       # Main dashboard screen (responsive grid / list)
    │   └── widgets/
    │       ├── database_card.dart          # Database item card with 16px geometry & action menus
    │       ├── database_form_dialog.dart   # Create/Edit database dialog
    │       └── delete_confirmation_dialog.dart # Destructive delete database confirmation
    ├── fields/
    │   ├── controllers/
    │   │   └── field_list_controller.dart  # AsyncNotifier for field management, reordering, unique check
    │   ├── field_form_screen.dart          # Create/Edit field screen
    │   ├── field_list_screen.dart          # Reorderable field list screen
    │   └── widgets/
    │       ├── delete_field_dialog.dart    # Destructive delete field confirmation
    │       └── field_card.dart             # Reorderable field card with badge & drag handle
    ├── import/
    │   ├── csv_preview_screen.dart         # CSV 5-row preview table & target database form
    │   └── excel_preview_screen.dart       # Excel worksheet selector & preview table
    ├── records/
    │   ├── controllers/
    │   │   ├── record_list_controller.dart # Keyset pagination controller, record save/delete
    │   │   └── v2_export_controller.dart   # Stream paginated export to .xlsx and trigger share
    │   ├── record_form_screen.dart         # Dynamic record entry/edit form with auto-advance
    │   ├── record_list_screen.dart         # Paginated records list / responsive grid view
    │   └── widgets/
    │       ├── delete_record_dialog.dart   # Destructive delete record confirmation
    │       ├── dynamic_field_input.dart    # Type-aware form field widgets (Text, Boolean, Choice)
    │       └── record_card.dart            # Record card with field preview summary
    └── settings/
        ├── settings_screen.dart            # 3-breakpoint master-detail settings screen
        └── widgets/
            └── theme_picker_sheet.dart     # Responsive bottom sheet / modal theme chooser
```

### Architectural Guardrails
- **Presentation Layer** must never perform direct database transactions or raw SQL queries.
- **Domain Layer** must remain strictly generic. Do NOT introduce domain-specific entities (e.g. Pokémon, Characters, Books) into the core domain models.
- **Data Layer** must handle all SQLite type conversions, transaction boundaries, and foreign key validations.
- **State Management** must use Riverpod providers to decouple UI from business logic.

---

## 6. Database Schema & Migration Specification

Vault Zero uses SQLite via `sqflite`. The database file is initialized in `lib/core/database/database_provider.dart`.

### Schema Configuration
- **Database Filename:** `characters.db` (retained for migration continuity)
- **Current Version:** `4`
- **Foreign Keys:** Enabled via `PRAGMA foreign_keys = ON` inside `onConfigure`.

### Table Definitions

```sql
-- 1. Databases Table
CREATE TABLE databases (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 2. Fields Table
CREATE TABLE fields (
  id TEXT PRIMARY KEY,
  database_id TEXT NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  position INTEGER NOT NULL,
  is_required INTEGER NOT NULL,
  configuration TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
);

-- 3. Records Table
CREATE TABLE records (
  id TEXT PRIMARY KEY,
  database_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (database_id) REFERENCES databases (id) ON DELETE CASCADE
);

-- 4. Field Values Table (EAV Pattern with Dedicated Value Columns)
CREATE TABLE field_values (
  id TEXT PRIMARY KEY,
  record_id TEXT NOT NULL,
  field_id TEXT NOT NULL,
  text_value TEXT,
  integer_value INTEGER,
  decimal_value REAL,
  boolean_value INTEGER,
  date_value INTEGER,
  date_time_value INTEGER,
  choice_value TEXT,
  FOREIGN KEY (record_id) REFERENCES records (id) ON DELETE CASCADE,
  FOREIGN KEY (field_id) REFERENCES fields (id) ON DELETE CASCADE,
  UNIQUE(record_id, field_id)
);

-- 5. Keyset Pagination Index
CREATE INDEX IF NOT EXISTS idx_records_database_created_id 
ON records(database_id, created_at, id);
```

### Migration History
- **Version 1:** Initial legacy character collector database.
- **Version 2:** Creation of generic database tables (`databases`, `fields`, `records`, `field_values`).
- **Version 3:** Addition of composite keyset index `idx_records_database_created_id` on `records(database_id, created_at, id)` for efficient cursor pagination.
- **Version 4:** Final retirement of legacy schema (`DROP TABLE IF EXISTS characters`).

---

## 7. Field Types: User-Facing vs. Internal Support

### User-Facing Field Creation (Strict Rule)

To keep Vault Zero intuitive, clean, and focused, **the user-facing field creation UI is strictly limited to 3 types:**

```text
┌───────────────────┬─────────────────────────────────────────────────────────┐
│ User-Facing Type  │ Description & Usage                                     │
├───────────────────┼─────────────────────────────────────────────────────────┤
│ 1. Text           │ Single-line or multi-line general text input.           │
│ 2. Boolean        │ Yes/No toggle switch.                                   │
│ 3. Choice         │ Single selection from custom predefined option chips.   │
└───────────────────┴─────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> Do NOT expose additional field types (such as `Integer`, `Decimal`, `Date`, `DateTime`, `Rating`, `URL`, `Image`, `Formula`) in the field creation UI unless explicitly approved as a new product milestone.

### Internal Domain & Storage Support
The underlying domain and SQLite layer support the complete `FieldType` enum:
- `FieldType.text`
- `FieldType.longText`
- `FieldType.integer`
- `FieldType.decimal`
- `FieldType.boolean`
- `FieldType.date`
- `FieldType.dateTime`
- `FieldType.choice` (configured via `ChoiceConfig(options: List<String>)`)

Each field value populates exactly one typed column in `field_values` (e.g. `text_value`, `boolean_value`, `choice_value`), maintaining type safety without raw string serializations.

---

## 8. Record Entry UX & Interaction Design

Fast, friction-free sequential data entry is a core product differentiator.

### Form Behavior & Navigation
- When a user fills out a record form, pressing the keyboard **Next** action (`TextInputAction.next`) must automatically advance focus to the subsequent input field.
- The final field triggers **Done** / Save.
- Forms are presented in a single, clean scrollable view. Do NOT introduce multi-step wizard flows for single record creation.
- On wider screens (tablets, desktop), forms must remain horizontally constrained (max-width 640px) and centered to maintain comfortable reach and readability.

---

## 9. Design System, Geometry & Responsive Breakpoints

Vault Zero uses a tailored Material 3 design system built for visual polish and cross-device consistency.

### Geometry & Token System
- **Cards & Containers:** `BorderRadius.circular(16)` with subtle outline borders (`colorScheme.outlineVariant.withAlpha(50)`).
- **Elevation Hierarchy:** `elevation: 0` using Material 3 tonal surfaces (`surfaceContainer`, `surfaceContainerLow`, `surfaceContainerHighest`).
- **Form Inputs:** `BorderRadius.circular(16)` filled with subtle alpha tint.
- **Buttons:** `BorderRadius.circular(16)`, minimum height 52px, bold typography.
- **Dialogs:** `BorderRadius.circular(24)`.
- **Bottom Sheets:** Top radius `BorderRadius.vertical(top: Radius.circular(24))`.

### Responsive Breakpoint System

```text
┌───────────────────────┬─────────────────────────┬──────────────────────────────────────────┐
│ Screen Width          │ Form Factor             │ Layout Strategy                          │
├───────────────────────┼─────────────────────────┼──────────────────────────────────────────┤
│ Compact (< 600px)     │ Mobile Phones           │ Single-column vertical list, bottom      │
│                       │                         │ sheets for pickers, edge-to-edge padding.│
├───────────────────────┼─────────────────────────┼──────────────────────────────────────────┤
│ Medium (600px–899px)  │ Foldables & Tablets     │ Adaptive 2-column card grid, centered    │
│                       │ (Portrait)              │ modal dialogs, max-width forms.          │
├───────────────────────┼─────────────────────────┼──────────────────────────────────────────┤
│ Expanded (≥ 900px)    │ Tablets (Landscape)     │ Adaptive multi-column grid (max 440px),  │
│                       │ & Desktop               │ Master-Detail two-pane Settings view.    │
└───────────────────────┴─────────────────────────┴──────────────────────────────────────────┘
```

---

## 10. Theme System

Vault Zero provides 5 curated theme presets in `lib/core/theme/theme_preset.dart`, each with hand-crafted Light and Dark color schemes in `lib/core/theme/app_theme.dart`:

```text
┌──────────────────┬──────────────┬───────────────────────────────┬──────────────────────────┐
│ Preset Name      │ Seed Color   │ Light Mode Identity           │ Dark Mode Identity       │
├──────────────────┼──────────────┼───────────────────────────────┼──────────────────────────┤
│ 1. Royal Purple  │ #6F35D3      │ Primary: #6F35D3, Surf: #FBF9FF│ Primary: #9D65FF, Surf: #14101A│
│ 2. Ocean Blue    │ #1769AA      │ Primary: #1769AA, Surf: #F6FAFF│ Primary: #4DA8FF, Surf: #0C121A│
│ 3. Emerald Green │ #16835B      │ Primary: #16835B, Surf: #F5FCF8│ Primary: #45C492, Surf: #0E1713│
│ 4. Sunset Orange │ #D85B24      │ Primary: #D85B24, Surf: #FFFAF7│ Primary: #FF8A5C, Surf: #1A120E│
│ 5. Rose Pink     │ #C13D75      │ Primary: #C13D75, Surf: #FFF7FA│ Primary: #FF72AD, Surf: #1A1014│
└──────────────────┴──────────────┴───────────────────────────────┴──────────────────────────┘
```

### Theme Rules
- Theme selection and Light/Dark/System mode are application-wide settings.
- Appearance preferences are persisted via `preferencesRepositoryProvider` into JSON application preferences (`vault_zero_preferences.json`).
- Theme switching updates dynamically via `themeProvider` across the entire widget tree.
- Do NOT create screen-specific hardcoded color styles. Always reference `Theme.of(context).colorScheme`.

---

## 11. Settings & Vault Management

All global application preferences and data operations reside in `lib/presentation/settings/settings_screen.dart`.

### Settings Modules
1. **Appearance:**
   - Visual Theme Chooser (`ThemePickerSheet`) displaying all 5 presets with descriptions and active indicators.
   - Light / Dark Mode selector.
2. **Data Management:**
   - **Backup Vault:** Serializes entire database schema, fields, records, and values into a single versioned JSON file (`.vzbackup`) and opens the native share sheet.
   - **Restore Vault:** Imports a `.vzbackup` file, validates schema and foreign keys, prompts with a destructive confirmation dialog, and atomically replaces the vault data.
   - **Import CSV:** Launches file picker, opens `CsvPreviewScreen` for verification, and streams rows into a new database.
   - **Import Excel:** Launches file picker, opens `ExcelPreviewScreen` with worksheet selection, and imports into a new database.

---

## 12. Import / Export Architecture

### Tabular Ingestion Pipeline (`ImportService`)

```text
File Picker (.csv / .xlsx)
  ↓
TabularDataSource (CsvDataSource / ExcelDataSource)
  ↓
Preview Screen (5-row preview table, worksheet selector, editable name)
  ↓ User Confirms
ImportService:
  1. Normalize Headers (Trim, auto-generate "Column A..Z", deduplicate "Name (1)")
  2. Create Database & Field Definitions (Transaction)
  3. Stream Rows (Skip blank rows, normalize newlines to LF)
  4. Batch Insert (500 records per transaction via RecordRepository.saveRecordsBatch)
  5. Rollback on Failure (Deletes partial database on error)
```

### Export Pipeline (`ExportController` / `V2ExportController`)
- **Database Excel Export:** Streams database records page-by-page (100 records per chunk), writes to an `.xlsx` workbook with strongly-typed cell values (`IntCellValue`, `DoubleCellValue`, `BoolCellValue`, `DateCellValue`, `DateTimeCellValue`) using `excel: ^4.0.6`, sanitizes worksheet/file names, and invokes native sharing via `share_plus`.

---

## 13. Data Safety, Integrity & Transactions

Vault Zero prioritizes zero data loss:
- **Foreign Key Cascades:** `PRAGMA foreign_keys = ON` guarantees cascading deletions of fields, records, and values without orphan artifacts.
- **Batching & Transactions:** Bulk inserts and restore operations execute inside atomic SQLite transactions (`db.transaction`).
- **Destructive Action Confirmations:** Deleting a database, deleting a field, deleting a record, or restoring a backup requires an explicit modal confirmation dialog.
- **In-Memory Integrity Check:** `VaultBackup.fromJson` validates that all fields and records belong to existing databases before executing a restore.

---

## 14. Retired & Rejected Features Policy

The following features were evaluated and explicitly removed or rejected from the product roadmap:
- **Legacy Character Collector:** Completely retired. Never reintroduce legacy character models, repositories, or widgets.
- **Database Templates:** Rejected. Database creation remains clean, direct, and customizable without bloated preset templates.
- **File / Media Attachments:** Rejected. Keeps database lightweight, portable, and fast.
- **Complex Spreadsheet Formulas:** Rejected. Vault Zero is a database, not a spreadsheet calculator.

---

## 15. Testing Architecture & Quality Standards

The test suite is located under `test/` and executes using `sqflite_common_ffi` for headless, in-memory SQLite execution.

### Test Suites Map
- `test/backup_restore_service_test.dart` — Full backup generation, JSON serialization, and restore integrity.
- `test/csv_import_test.dart` — CSV streaming parser, header normalization, batching, and atomic rollback.
- `test/excel_import_test.dart` — Excel worksheet selection, CellValue conversion, and import pipeline.
- `test/database_list_controller_test.dart` — Database CRUD and state management.
- `test/field_list_controller_test.dart` — Field creation, reordering, unique name validation, and deletion.
- `test/record_list_controller_test.dart` — Record creation, updating, deletion, and local state sync.
- `test/record_pagination_test.dart` — Keyset cursor pagination limits and boundary conditions.
- `test/theme_preferences_test.dart` — Theme preset persistence and state updates.
- `test/v2_database_test.dart` — SQLite repository operations, cascading deletes, and unique constraints.
- `test/v2_export_test.dart` — Excel export generation and empty-state error handling.

### Verification Checklist Before Completing Any Task
Every code change must satisfy the following verification steps:

```bash
flutter analyze           # Must report 0 errors, 0 warnings, 0 lints
flutter test              # All 10 test suites must pass
flutter build apk --debug # APK must build successfully
git diff --check          # No whitespace or syntax formatting issues
```

---

## 16. Git & Commit Workflow

- Work directly on `main` unless an explicit branch is requested.
- Check workspace state before starting:
  ```bash
  git status
  git log -3 --oneline
  ```
- Make minimal, coherent, and surgical commits.
- Never commit broken builds, failed tests, or unverified changes.

---

## 17. AI Coding Agent Constitution (Rules for Antigravity)

1. **Rule 1 — The Repository is the Source of Truth:** Do not hallucinate files, classes, providers, or APIs. Always inspect actual code before making changes.
2. **Rule 2 — Code Reality Over Stale Plans:** If roadmap text conflicts with live code, verify the code, explain the discrepancy, and follow the live architecture.
3. **Rule 3 — Do Not Resurrect Retired Features:** Never reintroduce Legacy Character Collector code, database templates, file attachments, or unapproved user-facing field types.
4. **Rule 4 — Ask Rather Than Guess:** If a requirement is ambiguous and materially impacts architecture or UX, ask the user before writing code.
5. **Rule 5 — Surgical, Minimal Edits:** Make the smallest coherent change required. Avoid broad, unsolicited refactors.
6. **Rule 6 — Protect Existing Features:** Never regress database CRUD, field management, keyset pagination, backup/restore, CSV/Excel import/export, themes, or responsive layouts.
7. **Rule 7 — Zero Unverified Claims:** Never report that tests passed or builds succeeded without actually observing the command output.
8. **Rule 8 — Fix Root Causes:** If a compile or analyzer error occurs, diagnose the underlying cause. Do not apply superficial cascading band-aids.
9. **Rule 9 — Strict Dependency Discipline:** Check Flutter/Dart built-ins first before proposing any new package.
10. **Rule 10 — Value Simplicity:** When multiple solutions exist, choose the one with fewer moving parts, clearer readability, and superior maintainability.

---

## 18. Current Task

At the start of every session, update this section with the active task:

```text
Task: Project Guidelines & Constitution fully updated, synchronized with V3.1+ architecture.
Status: Ready for next feature / enhancement.
```

---

## 19. Golden Rule

> **Inspect first. Preserve working behavior. Ask rather than guess. Verify before claiming success.**

