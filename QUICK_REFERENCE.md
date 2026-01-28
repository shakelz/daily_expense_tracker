# Quick Reference Guide

## Installation & Launching

### Step 1: Connect Device
```bash
# Enable Developer Mode on Motorola Edge 40:
# Settings → About phone → Tap "Build number" 7 times → Developer options enabled

# Enable USB Debugging:
# Settings → Developer options → USB Debugging (toggle ON)

# Connect via USB cable
```

### Step 2: Verify Connection
```bash
adb devices -l
# Output should show: ZD222CZQKZ   device   usb:1-3
```

### Step 3: Install APK
```bash
# Copy to your project directory
cd /home/shakelz/flutter\ projects/my_expense_tracker

# Install release build
adb -s ZD222CZQKZ install -r build/app/outputs/flutter-apk/app-release.apk

# Wait for "Success" message
```

### Step 4: Launch App
```bash
adb -s ZD222CZQKZ shell am start -n \
  com.example.my_expense_tracker/.MainActivity
```

---

## Using the App

### First Launch
1. ✅ Grant permissions when prompted:
   - Overlay permission (for bubble)
   - Notification permission
   - Biometric permission (optional)

2. 🔒 Set a PIN (Settings tab)

3. 📊 Navigate to Analysis tab to see dashboard

### Adding Transactions

**Method 1: Floating Action Button**
- Tap + button in home
- Enter amount (€)
- Select category
- Save

**Method 2: Floating Bubble**
- Background the app
- Bubble appears on screen
- Tap bubble
- Form opens with amount field focused
- Enter transaction
- Save

### Navigation

| Tab | Purpose | Icon |
|-----|---------|------|
| Transactions | View/edit all expenses | 📋 |
| Recurring | Manage recurring payments | 🔁 |
| Analysis | **New dashboard with all insights** | 📊 |
| Settings | App config & data | ⚙️ |

### Analysis Tab Sections

**Scroll Down to See:**

1. **Summary Cards (Top)**
   - 🟢 Income (total)
   - 🔴 Expense (total)
   - ⚪ Balance (net)

2. **Pie Chart (Category Breakdown)**
   - Shows last 30 days
   - Percentages displayed
   - Color-coded by category

3. **Bar Chart (Hourly Spending)**
   - 24-hour visualization
   - Hover for exact amounts
   - Purple gradient bars

4. **Recent Transactions (Bottom)**
   - Last 10 transactions
   - Date, category, amount
   - Swipe left to delete

### Pull-to-Refresh

**On any tab:**
- Swipe down from top
- Release to refresh data
- Useful after adding transactions

---

## Database Management

### View Data
```bash
adb -s ZD222CZQKZ shell sqlite3 \
  /data/data/com.example.my_expense_tracker/databases/expense_tracker.db

# Inside sqlite3:
sqlite> .tables
sqlite> SELECT * FROM transactions;
sqlite> SELECT category, SUM(amount) FROM transactions WHERE isIncome=0 GROUP BY category;
sqlite> .exit
```

### Backup Database
```bash
adb -s ZD222CZQKZ pull \
  /data/data/com.example.my_expense_tracker/databases/expense_tracker.db \
  ~/expense_tracker_backup.db
```

### Clear Data
```bash
adb -s ZD222CZQKZ shell pm clear com.example.my_expense_tracker
```

---

## Troubleshooting

### Issue: APK Won't Install
**Solution:**
```bash
# Uninstall existing version
adb -s ZD222CZQKZ uninstall com.example.my_expense_tracker

# Clear cache
adb -s ZD222CZQKZ shell pm clear com.example.my_expense_tracker

# Try install again
adb -s ZD222CZQKZ install build/app/outputs/flutter-apk/app-release.apk
```

### Issue: Bubble Doesn't Appear
**Solution:**
1. Grant overlay permission: Settings → Apps → My Expense Tracker → Permissions → Display over other apps
2. Ensure app is backgrounded (not in recent tasks)
3. Check device has Android 5.0+

### Issue: App Crashes on Startup
**Solution:**
```bash
# Clear app data
adb -s ZD222CZQKZ shell pm clear com.example.my_expense_tracker

# Reinstall
adb -s ZD222CZQKZ install build/app/outputs/flutter-apk/app-release.apk

# Check logs
adb -s ZD222CZQKZ logcat | grep -i flutter
```

### Issue: Bubble Closes When App Resumes
**Expected Behavior** - This is by design:
- Bubble shows when app is backgrounded
- Bubble hides when app is foregrounded
- This is controlled by `didChangeAppLifecycleState()`

---

## CSV Export

### Export Transactions
1. Tap share icon (📤) in Transactions tab header
2. Select "Save to file"
3. Choose location
4. Opens in spreadsheet app (Google Sheets, Excel, etc.)

**CSV Format:**
```csv
Title,Amount,Category,Date,Type
Rewe City,€23.50,Shopping,2026-01-28,Expense
Monthly Salary,€3200.00,Salary,2026-01-28,Income
```

---

## Settings Tab Features

### Security
- 🔒 Set PIN lock
- 👆 Enable biometric (fingerprint)
- 🔐 Change PIN

### Data Management
- 📥 Import backup
- 💾 Backup all data
- 🗑️ Clear all data
- 🔄 Reset app

### Other
- 🌙 Dark theme (always on)
- 📢 Notifications (toggle)
- 🔔 Recurring reminders (toggle)

---

## Keyboard Shortcuts

### When in Transaction Form
| Key | Action |
|-----|--------|
| Tab | Next field |
| Shift+Tab | Previous field |
| Enter/Done | Save transaction |
| Esc | Cancel (back) |

### In Lists
| Action | Result |
|--------|--------|
| Swipe left | Delete item |
| Long press | Copy amount |
| Tap | Edit item |

---

## Data Models

### Transaction Entry
```dart
class ExpenseEntry {
  int? id;                  // Auto-increment
  String title;             // e.g., "Rewe City"
  double amount;            // € value
  String category;          // e.g., "Shopping"
  DateTime date;            // When it happened
  bool isIncome;            // true for income, false for expense
}
```

### Recurring Payment
```dart
{
  'id': 1,
  'title': 'Rent',
  'amount': 850.00,
  'category': 'Rent',
  'day_of_month': 1,        // Auto-execute on 1st
  'isIncome': false,
  'last_executed': '2026-01-01'
}
```

---

## SQL Queries in Analysis Tab

### Income & Expense Totals
```sql
SELECT 
  SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as total_expenses,
  SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as total_income
FROM transactions
```

### Category Breakdown (with %)
```sql
WITH monthly_expenses AS (
  SELECT category, SUM(amount) as category_total
  FROM transactions
  WHERE isIncome = 0 AND date >= date('now', '-30 days')
  GROUP BY category
),
total_monthly AS (
  SELECT SUM(category_total) as overall_total FROM monthly_expenses
)
SELECT 
  category,
  category_total,
  ROUND((category_total * 100.0) / overall_total, 2) as percentage
FROM monthly_expenses
ORDER BY category_total DESC
```

### Hourly Spending
```sql
SELECT 
  CAST(strftime('%H', date) AS INTEGER) as hour,
  SUM(amount) as total
FROM transactions
WHERE isIncome = 0
GROUP BY hour
ORDER BY hour ASC
```

---

## Build Commands

### Development (with debug banner)
```bash
flutter run -d motorola\ edge\ 40
```

### Testing (debug APK)
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Production (release APK)
```bash
flutter build apk --release
# Size: ~50MB (tree-shaken)
# Location: build/app/outputs/flutter-apk/app-release.apk
```

### Rebuild Everything
```bash
flutter clean
flutter pub get
flutter build apk --release
```

---

## File Structure

```
my_expense_tracker/
├── android/              # Android native code
├── ios/                  # iOS files (optional)
├── lib/
│   ├── main.dart        # Entry point
│   ├── models/
│   ├── screens/         # ← analysis_tab.dart is here
│   ├── services/        # ← database_helper.dart with analytics
│   ├── widgets/
│   └── utils/
├── build/
│   └── app/outputs/
│       └── flutter-apk/
│           ├── app-debug.apk
│           └── app-release.apk  # ← Use this one
├── pubspec.yaml         # Dependencies
├── analysis_options.yaml # Lint rules
└── README.md
```

---

## Useful ADB Commands

```bash
# List devices
adb devices -l

# Install APK
adb -s <ID> install -r <path_to.apk>

# Uninstall app
adb -s <ID> uninstall com.example.my_expense_tracker

# View logs
adb -s <ID> logcat | grep -i flutter

# Pull file from device
adb -s <ID> pull <device_path> <local_path>

# Push file to device
adb -s <ID> push <local_path> <device_path>

# Clear app data
adb -s <ID> shell pm clear com.example.my_expense_tracker

# Open SQLite on device
adb -s <ID> shell sqlite3 <db_path>

# Reboot device
adb -s <ID> reboot
```

---

## Performance Tips

1. **Reduce data reload:**
   - Don't refresh tab if already loaded
   - Cache category colors
   - Lazy-load transactions

2. **Optimize charts:**
   - Limit hourly chart to 24 hours
   - Pie chart shows top 10 categories
   - Bar chart downsamples if needed

3. **Database optimization:**
   - Transactions indexed by date
   - Recurring payments cached
   - Use EXPLAIN QUERY PLAN for slow queries

---

## Support Resources

- **Flutter Docs:** https://flutter.dev/docs
- **fl_chart:** https://github.com/imaNNeo/fl_chart
- **dash_bubble:** https://pub.dev/packages/dash_bubble
- **SQLite:** https://www.sqlite.org/docs.html

---

**Version:** 1.0 Production Release
**Last Updated:** January 28, 2026
**Status:** Ready for deployment 🚀
