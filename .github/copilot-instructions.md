# AI Agent Instructions for my_expense_tracker

## Architecture Overview

This Flutter app implements a **dual-interface expense tracking system** with **local SQLite persistence**:

1. **Main App** ([lib/main.dart](lib/main.dart), [lib/screens/home_page.dart](lib/screens/home_page.dart)): Traditional UI entry point with FutureBuilder for database loading
2. **Floating Bubble Overlay** ([lib/bubble_overlay.dart](lib/bubble_overlay.dart)): Persistent notification-style overlay that survives app backgrounding using `flutter_overlay_window` package
3. **Database** ([lib/services/database_helper.dart](lib/services/database_helper.dart)): SQLite persistence layer with singleton pattern

The key insight: the bubble runs in a **separate Flutter instance** with its own `overlayMain()` entry point (marked with `@pragma("vm:entry-point")`). Main app and bubble share the same codebase but operate independently. All transactions are persisted to SQLite.

## Critical Data Flow: Automated Lifecycle Management

**App Backgrounding → Bubble Shows Automatically** → **App Resuming → Bubble Closes Automatically**

- [HomePage.didChangeAppLifecycleState()](lib/screens/home_page.dart#L34-L44) automatically monitors app state (paused/resumed)
- When app pauses: immediately calls `_startBubbleOverlay()` with no manual toggle required
- When app resumes: immediately calls `_closeOverlayWhenAppOpen()` to dismiss bubble
- No `_isBubbleActive` manual control — automation is always on for Berlin users

## Breathing Animation & Form Expansion

- **Bubble breathing**: Smooth scale animation from **1.0 to 1.1** (gentle, non-intrusive)
- **Form resize**: Uses **`resizeOverlay(-1, -1, false)`** for full-screen expansion (prevents bottom cutoff)
- **Form dragging**: Form can be dragged freely with `onPanUpdate` handler that updates `_formPosition` with screen boundary clamping
- **Animation lifecycle**: 
  - Stop animation with `_animationController.stop()` when opening form
  - Resume with `_animationController.repeat(reverse: true)` when closing form
  - Always include 100ms delay after resuming animation to allow UI sync

## Draggable Bubble & Draggable Form

- **Bubble dragging**: Enabled via `enableDrag: true` in `FlutterOverlayWindow.showOverlay()`
- **Form dragging**: Form card wraps in `GestureDetector` with `onPanUpdate` that updates `_formPosition` offset
  - Bounds checking: x-position clamped to `[0, screenWidth - 340]`
  - Bounds checking: y-position clamped to `[0, screenHeight - 600]`
- **Tap to expand**: `onTap()` opens form with full-screen resize

## Category System: Separate Income & Expense with Custom Entry

Categories are now **dynamically loaded** based on transaction type:

**Income Categories**: `['Salary', 'Freelance', 'Investment', 'Gift', 'Custom']`

**Expense Categories**: `['Food', 'Rent', 'Transport', 'Shopping', 'Utilities', 'Custom']`

**Custom Category Flow**:
- User selects 'Custom' from dropdown
- `_isCustomSelected` state flag activates
- TextField titled "Enter Custom Category" appears below dropdown
- Custom text captured in `_customCategoryController`
- On save, final category uses custom text if selected, otherwise dropdown selection

**Implementation Details**:
- [TransactionFormOverlay._currentCategories](lib/bubble_overlay.dart): getter returns income/expense list based on `_isIncome`
- Toggle buttons reset `_isCustomSelected = false` when switching transaction type
- Custom category input validated on form submission (final category set conditionally)
- **No direct state sharing** between main app and bubble
- Bubble's [overlayMain()](lib/bubble_overlay.dart#L9) creates isolated MaterialApp with transparent scaffolds
- Form resizing required on state transitions: `FlutterOverlayWindow.resizeOverlay(width, height, respectBoundary)`
- Always add 50-100ms delays after resize before UI changes (renderer sync issue)

### 2. Flutter Model: ExpenseEntry with Database Conversion
- [models/expense_entry.dart](lib/models/expense_entry.dart): Immutable class (final fields, const constructor)
- Fields: `id` (nullable int), `title`, `amount` (double), `category`, `date` (DateTime), `isIncome` (boolean)
- Includes `toMap()` for database insertion and `fromMap()` factory for database retrieval
- **Database persistence layer**: [DatabaseHelper](lib/services/database_helper.dart) handles all SQLite operations

### 3. Database Schema
Table `transactions`:
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `title` (TEXT NOT NULL)
- `amount` (REAL NOT NULL)
- `category` (TEXT NOT NULL)
- `date` (TEXT NOT NULL, stored as ISO8601 string)
- `isIncome` (INTEGER NOT NULL, 0 or 1)

Operations: INSERT (with validation), SELECT * ORDER BY date DESC, DELETE, CLEAR ALL

### 4. Widget Structure
- **[TransactionFormOverlay](lib/bubble_overlay.dart)**: Full-screen draggable form with dynamic category dropdown and custom entry. On Save, calls `DatabaseHelper().insertTransaction()`
- **[FloatingTransactionForm](lib/widgets/floating_transaction_form.dart)**: In-app draggable form with same category logic. On Save, calls `DatabaseHelper().insertTransaction()`
- Form state: `_isIncome`, `_selectedCategory`, `_isCustomSelected`, `_formPosition`, form controllers
- Custom category input appears conditionally when "Custom" is selected
- All TextEditingControllers disposed in widget lifecycle
- Form validation: both title and amount must be non-empty; amount parsed as double

## Currency Convention

**All transactions use Euro (€) symbol** — this is Berlin-based software (cite: 2025-12-23):
- Amount fields display: `€ 50.00`
- Summary cards show: `€1,250.50`
- Form labels: "Amount (€)"
- Console output: `Amount: €{value}`

## Critical Implementation Details

### Overlay Entry Point
```dart
@pragma("vm:entry-point")
void overlayMain() {  // Called by flutter_overlay_window package
  if (kIsWeb) return;  // Guard against web
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(...));
}
```
Without the pragma, Flutter tree-shaking removes the entry point.

### Lifecycle Automation (No Toggle)
```dart
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _startBubbleOverlay();  // Always show
  } else if (state == AppLifecycleState.resumed) {
    _closeOverlayWhenAppOpen();  // Always hide
  }
}
```
The manual toggle button has been removed — automation handles all transitions.

### Form Actions Pattern
Three parallel paths in [TransactionFormOverlay._handleSave()](lib/bubble_overlay.dart#L300+):
- **Save**: Prints transaction, triggers `onClose()` callback
- **Later**: Snoozes interaction (currently no-op, can extend to 15-min delay)
- **NoTransaction**: Cancel without saving

All paths call `widget.onClose()` which closes the overlay and resumes breathing.

## Development Conventions

### Printing vs Logging
- Use `print()` for transaction state tracking (bubble lifecycle, form actions)
- Format: `'=== ACTION NAME ===\nDetails...\n=================\n'`
- No structured logging framework yet

### Theming
- Dark theme hardcoded in [MyApp](lib/main.dart#L21-L31): seedColor `0xFF7C4DFF`, surface `0xFF0F1115`
- Overlay uses transparent scaffolds (requires explicit decoration on child widgets)
- Icons: use `Icons` from Material or `CupertinoIcons` for iOS style

### Directory Structure
- `lib/models/`: Data classes only (no business logic)
- `lib/widgets/`: Stateful components with local state management
- `lib/screens/`: Top-level navigable screens
- `lib/services/`, `lib/utils/`: Empty — add here for shared logic

## Build & Testing

### Flutter Commands
```bash
flutter pub get              # Install dependencies
flutter run -d <device>     # Run on physical device/emulator
flutter build apk           # Android release (signing required)
flutter build ios           # iOS release (Xcode required)
```

### Key Dependencies
- `flutter_overlay_window: ^0.5.0` — Overlay implementation (Android/iOS only)
- `sqflite: ^2.3.0` — SQLite database
- `path: ^1.8.3` — File path utilities for database
- `flutter_lints: ^6.0.0` — Lint rules
- `cupertino_icons` — Icon pack

### Database Persistence
- **Location**: `{app_documents_directory}/expense_tracker.db`
- **Singleton pattern**: `DatabaseHelper()` reuses single database instance across app
- **Thread-safe**: sqflite handles async operations properly
- **Auto-initialization**: Database created on first `database` getter call
- **Testing**: Persists across app restarts and emulator reboots

### Platform-Specific Notes
- Overlay unavailable on Web (`kIsWeb` checks throughout)
- Android requires overlay permission grant dialog (handled in `_showPermissionDialog()`)
- iOS requires native setup in Runner.xcodeproj

## Common Pitfalls to Avoid

1. **Forgetting @pragma on overlayMain()** → Overlay doesn't exist at runtime
2. **Not resizing overlay before form appears** → Form truncated/misaligned (use `-1, -1` for fullscreen)
3. **Missing lifecycle observer cleanup** → Memory leaks, phantom overlays (always `removeObserver()` in dispose)
4. **Not stopping animation controller** → CPU spin when bubble transitions to form (explicitly `stop()` then `repeat()`)
5. **TextEditingController leak** → Dispose in widget.dispose(), not in build()
6. **Manual toggle remaining** → Users expect auto-bubble behavior when app backgrounds
7. **Animation scale > 1.15** → Too aggressive, distracting breathing effect (keep to 1.15 max)

## Where to Add Features

- **Persistence**: Create `lib/services/expense_service.dart` (local DB or backend), update form handlers
- **Categories**: Extend dropdown in [TransactionFormOverlay](lib/bubble_overlay.dart#L260+), add to ExpenseEntry model
- **Statistics**: New screen in `lib/screens/`, consume expense list from service
- **Notifications**: Extend "Later" snooze logic in bubble_overlay.dart (15-min reschedule)
- **Filtering/Search**: Add filters to HomePageState expense list logic
