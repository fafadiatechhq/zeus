# Zeus — Developer Notes

Technical reference for engineers working on the Flutter app.

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
