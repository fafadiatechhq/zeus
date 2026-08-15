# Zeus — Developer Notes

Technical reference for engineers working on the Zeus codebase — Flutter mobile app and ERPNext backend.

---

## Project Setup

**Requirements**
- Flutter SDK (`^3.12.2`) — check with `flutter --version`
- Dart SDK (bundled with Flutter)
- Android SDK / Android Studio for emulator and device builds
- Xcode (macOS) for iOS builds

**Install & run**
```bash
cd app
flutter pub get
flutter run               # picks up any connected device / running emulator
flutter run -d <id>       # target a specific device (see flutter devices)
```

**Useful commands**
```bash
flutter devices           # list connected devices and emulators
flutter analyze           # static analysis (must pass with zero issues before commit)
flutter test              # run unit and widget tests
flutter build apk         # release APK
flutter build apk --debug # debug APK
```

---

## Project Structure

```
app/
├── lib/
│   ├── main.dart               # Entry point — ZeusApp widget
│   ├── theme/
│   │   └── app_theme.dart      # Single source of truth for ALL colors, text styles, component themes
│   ├── models/
│   │   ├── user.dart           # User model
│   │   ├── attendance.dart     # AttendanceRecord + AttendanceStatus enum
│   │   ├── task.dart           # TaskItem, ChecklistItem, TaskStatus, TaskPriority enums
│   │   └── expense.dart        # Expense, ExpenseStatus, ExpenseCategory enums
│   ├── data/
│   │   └── mock_data.dart      # In-memory mock data (replace with API layer)
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── main_shell.dart     # Bottom nav host (IndexedStack)
│   │   ├── home_screen.dart
│   │   ├── attendance_screen.dart
│   │   ├── tasks_screen.dart
│   │   ├── task_detail_screen.dart
│   │   ├── expenses_screen.dart
│   │   ├── expense_form_screen.dart
│   │   └── profile_screen.dart
│   └── widgets/
│       ├── stat_card.dart      # Metric tile used on Home
│       └── task_card.dart      # Task list item with priority dot, status badge, progress bar
├── screenshots/                # App screenshots for README
├── test/
│   └── widget_test.dart
├── pubspec.yaml
├── README.md                   # Product-facing documentation
└── DEVNOTES.md                 # This file
```

---

## Theme System

**All colors, text styles, and component themes live exclusively in `lib/theme/app_theme.dart`.** No raw `Color(0xFF...)` literals anywhere else in the codebase.

### Color tokens

```dart
// Brand
AppTheme.primary       // #233A66  navy blue  — primary actions, AppBar, buttons
AppTheme.primaryDark   // #162344  deep navy  — checked-out state, SnackBar
AppTheme.accent        // #FFD691  golden yellow — AppBar subtitles, highlights
AppTheme.gold          // #D7A859  warm gold  — warning states, medium priority

// Semantic
AppTheme.success       // #2E7D52  green
AppTheme.warning       // #D7A859  gold (reuses AppTheme.gold)
AppTheme.danger        // #FF6E80  coral pink

// Text hierarchy (always use these, never hardcode)
AppTheme.textPrimary   // #1E293B  headings, labels
AppTheme.textSecondary // #475569  body copy
AppTheme.textMuted     // #64748B  meta, timestamps
AppTheme.textSubtle    // #94A3B8  hints, placeholders
AppTheme.textOnPrimary // #FFFFFF  text on dark backgrounds
AppTheme.textOnAccent  // #233A66  navy on gold

// Surfaces
AppTheme.surface       // #FFF8EE  warm cream scaffold background
AppTheme.cardBg        // #FFFFFF  card background
AppTheme.divider       // #EDE8DF  warm card borders, dividers
AppTheme.borderLight   // #CBD5E1  input borders, inactive states

// Task priority
AppTheme.priorityLow    // #94A3B8  grey
AppTheme.priorityMedium // #D7A859  gold
AppTheme.priorityHigh   // #EA580C  orange
AppTheme.priorityUrgent // #FF6E80  coral pink
```

### Adding new colors
Add the `static const Color` to `AppTheme` and wire it into the relevant `ThemeData` component theme. Never pass a raw `Color(0xFF...)` to a widget.

### Adding new component themes
Add to `AppTheme.light` in `app_theme.dart`. Widgets automatically inherit via `Theme.of(context)` — avoid per-widget `styleFrom(...)` overrides unless the variation is genuinely one-off and semantic (e.g. a destructive confirm button).

---

## Mock Data

All data currently lives in `lib/data/mock_data.dart` as static in-memory state.

| Field | Mock value |
|---|---|
| Logged-in user | Rajesh Kumar, Field Sales Executive |
| Today's attendance | Starts as `notCheckedIn`; mutated by check-in/out actions |
| Attendance history | 4 past records (3 Present, 1 On Leave) |
| Tasks | 5 tasks across all statuses (Open, In Progress, Completed, Blocked) |
| Expenses | 5 expense records across all statuses (Draft, Submitted, Approved) |

**Replacing with real API:** swap `MockData.*` references in each screen with repository/service calls. The models (`User`, `AttendanceRecord`, `TaskItem`, `Expense`) are already shaped to map directly to ERPNext DocType fields — no structural change needed.

---

## Navigation

The app uses a flat `BottomNavigationBar` hosted in `MainShell` with an `IndexedStack` so each tab preserves its scroll/state across tab switches.

```
LoginScreen
  └── MainShell (IndexedStack)
        ├── [0] HomeScreen
        ├── [1] AttendanceScreen
        ├── [2] TasksScreen
        │         └── TaskDetailScreen (push)
        ├── [3] ExpensesScreen
        │         └── ExpenseFormScreen (push)
        └── [4] ProfileScreen
```

---

## State Management

Currently using plain `StatefulWidget` + `setState`. State is shared by mutating `MockData` static fields directly (e.g. `MockData.todayAttendance = updated`). This is intentional for the mock phase — no external state management library is needed yet.

**When connecting to a real backend:** introduce a lightweight solution (Riverpod recommended for this scale) with repository classes per domain (AttendanceRepository, TaskRepository, ExpenseRepository). The screen widgets are already structured to make this a clean extraction.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Framework |
| `cupertino_icons` | `^1.0.8` | iOS-style icons |
| `intl` | `^0.19.0` | Date/number formatting (`DateFormat`, `NumberFormat`) |

No state management, routing, or HTTP packages yet — kept minimal for the mock phase.

---

## Known Limitations (Mock Phase)

- **No persistence** — all state resets on hot restart. Check-in/out state survives hot reload only.
- **No real GPS** — check-in location is a hardcoded string (`"Andheri East, Mumbai"`).
- **No API calls** — all data is in-memory mock.
- **No push notifications** — not wired up.
- **Android only** tested — iOS simulator should work but not validated.
- **No auth** — login screen simulates a 1.2s delay then navigates unconditionally.

---

## Emulator Tips

If you hit `not enough space` on the Android emulator:
```bash
# Free up Google services cache (fast, no data loss)
adb shell pm clear com.google.android.gms
adb shell pm clear com.android.vending
adb shell pm clear com.google.android.gsf

# Nuclear option — trim all caches
adb shell cmd package trim-caches 1000G
```

For a permanent fix: Android Studio → Virtual Device Manager → Edit → Show Advanced Settings → increase Internal Storage to 4 GB+.

---

## Linting

The project uses `flutter_lints` with the default recommended rule set (`analysis_options.yaml`). All commits must pass `flutter analyze` with zero issues.

---

---

# ERPNext Backend

Zeus is a custom [Frappe](https://frappeframework.com) app that runs on ERPNext v15. The backend is fully containerised — no local bench installation required.

---

## Running Locally (Docker)

**Requirements:** Docker Desktop (or Engine + Compose plugin)

```bash
# First run — builds the image, creates the site, installs all apps, seeds demo data
# Takes ~10–15 min on first boot; subsequent starts are instant
docker compose up

# Subsequent starts (no rebuild needed)
docker compose up -d

# Rebuild image after code changes to the zeus Python app
docker compose up --build

# Full reset — wipe all data and start fresh
docker compose down -v && docker compose up
```

| Service | URL |
|---|---|
| ERPNext desk | http://localhost:8000 |
| Socket.IO | http://localhost:9000 |

**Default credentials**

| Field | Value |
|---|---|
| Username | `Administrator` |
| Password | `admin` |
| Site name | `localhost` |

Override via `.env` (copy from `.env` in repo root; never commit changes to `.env`).

---

## Repository Layout

```
zeus/                           # repo root
├── Dockerfile                  # extends frappe/erpnext:v15 with Zeus pre-installed
├── docker-compose.yml          # full stack: MariaDB, Redis, backend, workers, websocket
├── docker/
│   └── init.sh                 # one-time site setup: new-site → install-app → seed data
├── .env                        # local overrides (SITE_NAME, DB_ROOT_PASSWORD, ADMIN_PASSWORD)
├── pyproject.toml              # flit_core package metadata for the Zeus Python app
├── app/                        # Flutter mobile app (see above)
└── zeus/                       # Frappe/Python app root
    ├── __init__.py             # exposes __version__ = "0.0.1"
    ├── hooks.py                # Frappe app hooks (custom fields on Expense Claim, etc.)
    ├── modules.txt             # declares module "Zeus"
    ├── demo_data.py            # idempotent demo data seeder (see below)
    └── zeus/                   # "Zeus" module directory (Frappe resolves doctypes here)
        ├── doctype/
        │   ├── zeus_site/                   # Zeus Site
        │   ├── zeus_field_task/             # Zeus Field Task (+ checklist child)
        │   ├── zeus_task_checklist_item/    # child of Zeus Field Task
        │   ├── zeus_visit_log/              # Zeus Visit Log
        │   ├── zeus_journey_plan/           # Zeus Journey Plan (+ stops child)
        │   ├── zeus_journey_plan_stop/      # child of Zeus Journey Plan
        │   └── zeus_attendance_regularization/
        └── workspace/
            └── zeus/
                └── zeus.json   # Zeus workspace definition (auto-loaded on install)
```

> **Frappe app layout rule:** DocTypes must live inside the *module* subdirectory (`zeus/zeus/doctype/`), not the package root (`zeus/doctype/`). Frappe resolves the "Zeus" module to `apps/zeus/zeus/zeus/` in the container — putting files at the package root causes Frappe to look for controllers at `frappe.core.doctype.*`.

---

## DocTypes

| DocType | Description | Key fields |
|---|---|---|
| **Zeus Site** | Physical location / customer site with geofence | `site_name`, `customer`, `latitude`, `longitude`, `geofence_radius_meters`, `is_active` |
| **Zeus Field Task** | Task assigned to a field employee | `title`, `assigned_to`, `assigned_by`, `status`, `priority`, `due_date`, `site`, `customer`, `requires_geo_verification`, `checklist` (child) |
| **Zeus Task Checklist Item** | Child row of Zeus Field Task | `label`, `is_done` |
| **Zeus Visit Log** | GPS-stamped record of a field visit | `employee`, `visit_datetime`, `site`, `customer`, `purpose`, `notes`, `latitude`, `longitude` |
| **Zeus Journey Plan** | Planned route for a field employee for a day | `employee`, `plan_date`, `status`, `stops` (child) |
| **Zeus Journey Plan Stop** | Child row of Zeus Journey Plan | `sequence`, `stop_type`, `site`, `customer`, `planned_time`, `actual_time`, `status` |
| **Zeus Attendance Regularization** | Request to correct a missed/wrong punch | `employee`, `attendance_date`, `regularization_type`, `reason`, `requested_check_in`, `requested_check_out`, `status`, `approver` |

**Custom fields added to ERPNext DocTypes** (defined in `hooks.py`):

| DocType | Field | Type | Purpose |
|---|---|---|---|
| Expense Claim | `zeus_section` | Section Break | Groups Zeus fields |
| Expense Claim | `zeus_task` | Link → Zeus Field Task | Links expense to a field task |
| Expense Claim | `zeus_visit_log` | Link → Zeus Visit Log | Links expense to a visit |

---

## Demo Data

The `configurator` service runs `docker/init.sh` once on first boot. After installing apps it calls the seeder:

```bash
bench --site localhost execute zeus.demo_data.seed
```

The seeder is **idempotent** — safe to re-run; it skips records that already exist.

**What gets seeded:**

| Entity | Records |
|---|---|
| Company | Zeus Demo Co |
| Employees | Priya Patel (manager), Ravi Sharma, Ankit Mehta, Deepa Nair |
| Customers | Sunrise Industries Pvt Ltd, Metro Electronics, City Hospital, Green Valley Farms |
| Zeus Sites | 5 Mumbai-area sites with coordinates and geofence radii |
| Zeus Field Tasks | 6 tasks (Open, In Progress, Completed, Blocked) with checklists |
| Zeus Visit Logs | 4 recent visit records |
| Zeus Journey Plans | 2 plans (Draft and Active) with stops |

To remove all seeded data:

```bash
bench --site localhost execute zeus.demo_data.teardown
```

---

## Workspace

The Zeus workspace (`zeus/zeus/workspace/zeus/zeus.json`) is loaded automatically when the app is installed. It appears as **Zeus ⚡** in the ERPNext sidebar and provides:

**Shortcuts** (live record counts):
- Zeus Field Task — Open/In Progress/Blocked count
- Zeus Visit Log
- Zeus Journey Plan — Active count
- Zeus Site
- Zeus Attendance Regularization — Pending count

**Cards** (links to lists):
- *Field Operations* — Field Tasks, Visit Logs, Journey Plans
- *Masters* — Sites, Employees, Customers
- *HR & Attendance* — Attendance Regularizations

---

## API Endpoints

All endpoints are Frappe whitelisted methods, callable at:

```
POST /api/method/zeus.api.<module>.<function>
```

Pass parameters as JSON body or form fields. Frappe returns `{ "message": <result> }`.

Authentication uses Frappe session cookies or API key/secret headers (`Authorization: token <api_key>:<api_secret>`).

---

### Sites — `zeus.api.site`

| Function | Parameters | Description |
|---|---|---|
| `get_sites` | `customer?`, `is_active?=1` | List sites |
| `get_site` | `site_name` | Single site |
| `create_site` | `site_name`, `address?`, `latitude?`, `longitude?`, `geofence_radius_meters?`, `customer?`, `is_active?` | Create site |
| `update_site` | `site_name`, any writable field | Patch site fields |

---

### Field Tasks — `zeus.api.task`

| Function | Parameters | Description |
|---|---|---|
| `get_tasks` | `assigned_to?`, `status?`, `priority?`, `site?`, `due_date?` | List tasks with filters |
| `get_my_tasks` | `status?` | Tasks for the logged-in employee |
| `get_task` | `task_name` | Full task doc including checklist rows |
| `create_task` | `title`, `due_date`, `assigned_to`, `status?`, `priority?`, `assigned_by?`, `customer?`, `site?`, `description?`, `requires_geo_verification?`, `checklist?` | Create task; `checklist` is a JSON array of `{label, is_done}` |
| `update_task_status` | `task_name`, `status` | Transition status (Open / In Progress / Completed / Blocked) |
| `complete_task` | `task_name`, `latitude?`, `longitude?`, `completion_notes?`, `completion_photo?` | Mark complete; lat/lng required if `requires_geo_verification=1` |
| `update_checklist_item` | `task_name`, `item_name`, `is_done` | Toggle a single checklist row |

---

### Visit Logs — `zeus.api.visit_log`

| Function | Parameters | Description |
|---|---|---|
| `get_visit_logs` | `employee?`, `customer?`, `site?`, `from_date?`, `to_date?` | List logs |
| `get_visit_log` | `log_name` | Single visit log |
| `create_visit_log` | `visit_datetime`, `customer?`, `site?`, `purpose?`, `notes?`, `photo?`, `latitude?`, `longitude?`, `linked_task?`, `employee?` | Log a visit; defaults employee to current user |

---

### Journey Plans — `zeus.api.journey_plan`

| Function | Parameters | Description |
|---|---|---|
| `get_journey_plans` | `employee?`, `status?`, `plan_date?` | List plans |
| `get_my_plan_today` | — | Today's Active or Draft plan for logged-in employee |
| `get_journey_plan` | `plan_name` | Full plan with stops |
| `create_journey_plan` | `plan_date`, `stops`, `employee?` | Create plan; `stops` is a JSON array of `{sequence, stop_type, linked_task?, site?, customer?, planned_time?}` |
| `activate_journey_plan` | `plan_name` | Draft → Active |
| `complete_stop` | `plan_name`, `stop_name`, `latitude?`, `longitude?`, `actual_time?` | Mark stop Completed; auto-completes plan when all stops done |
| `skip_stop` | `plan_name`, `stop_name` | Mark stop Skipped; same auto-complete logic |

---

### Attendance Regularization — `zeus.api.attendance`

| Function | Parameters | Description |
|---|---|---|
| `get_regularizations` | `employee?`, `status?`, `from_date?`, `to_date?` | List requests |
| `get_regularization` | `reg_name` | Single request |
| `create_regularization` | `attendance_date`, `regularization_type`, `reason`, `requested_check_in?`, `requested_check_out?`, `employee?` | Submit regularization; defaults to current user |
| `approve_regularization` | `reg_name`, `approver_remarks?` | Approve and trigger Attendance record creation |
| `reject_regularization` | `reg_name`, `approver_remarks?` | Reject request |

---

### Mobile / Utility — `zeus.api.mobile`

| Function | Parameters | Description |
|---|---|---|
| `get_dashboard` | — | Returns open tasks, today's journey plan, visit count, pending regularizations for the logged-in employee |
| `geo_verify_site` | `site_name`, `latitude`, `longitude` | Returns `{distance_meters, geofence_radius_meters, within_geofence}` using Haversine formula |

---

## Making Backend Changes

**Add a new DocType**

Place it in `zeus/zeus/doctype/<doctype_name>/` (the inner `zeus/zeus/` module directory). Then rebuild and full-reset:

```bash
docker compose build && docker compose down -v && docker compose up
```

Or, if the site already exists, just migrate:

```bash
docker compose exec backend bench --site localhost migrate
```

**Edit a DocType in the desk**

Make changes in the ERPNext desk, then export:

```bash
docker compose exec backend bash -c "cd /home/frappe/frappe-bench && \
  bench --site localhost export-fixtures --app zeus"
```

This writes the updated JSON back to the repo inside the container. Copy it out with `docker cp`.

**Run a bench command**

```bash
docker compose exec backend bash -c "cd /home/frappe/frappe-bench && bench --site localhost <command>"
```

**Open a Frappe console**

```bash
docker compose exec backend bash -c "cd /home/frappe/frappe-bench && bench --site localhost console"
```

---

## Environment Variables

All variables are set in `.env` at the repo root (copy from the committed `.env` file):

| Variable | Default | Purpose |
|---|---|---|
| `SITE_NAME` | `localhost` | Frappe site name — must match the HTTP Host header |
| `DB_ROOT_PASSWORD` | `root_password` | MariaDB root password |
| `ADMIN_PASSWORD` | `admin` | ERPNext Administrator password |
