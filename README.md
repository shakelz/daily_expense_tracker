# 💰 Daily Expense Tracker

A professional, feature-rich Flutter application for tracking income and expenses with advanced analytics, secure authentication, and intelligent data management.

**Status**: ✅ Production Ready | **Version**: 1.0.0 | **Platform**: Cross-platform (Android, iOS, Web, Desktop)

---

## 🎯 Features

### Core Features
- ✅ **Income & Expense Tracking** - Easily log all financial transactions
- ✅ **Advanced Analytics** - Visual reports with pie charts and bar graphs
- ✅ **Budget Management** - Set and monitor spending budgets
- ✅ **Account Management** - Track multiple accounts with different types
- ✅ **Recurring Transactions** - Automate repeating payments
- ✅ **Category Organization** - Organize transactions by custom categories
- ✅ **Smart Filtering** - Filter by date range, category, and amount

### Advanced Features
- 🔐 **Biometric Authentication** - Fingerprint/Face ID security
- 💾 **Data Backup & Restore** - Automatic and manual backup options
- 📊 **Month-over-Month Analytics** - Compare spending trends
- 📈 **Top Expenses Tracking** - Identify your biggest spenders
- 💡 **Spending by Source** - Analyze spending by account/source
- 🔔 **Floating Bubble Overlay** - Quick access floating action interface
- 🌓 **Light & Dark Themes** - Adaptive theme support

### Technical Features
- 🗄️ **SQLite Database** - Local persistent data storage
- 🔍 **Data Validation** - Comprehensive input validation
- ⚡ **Fast Performance** - Optimized rendering and queries
- 🛡️ **Error Recovery** - Emergency backup protection
- 📱 **Responsive Design** - Works on all screen sizes
- 🌐 **Internationalization Ready** - EUR (€) currency support

---

## 📱 Screenshots

### Home Dashboard
- Account balance overview
- Recent transactions
- Quick expense entry
- Income/Expense summary

### Analytics Dashboard
- Spending by category pie chart
- Hourly/Daily/Monthly spending charts
- Top 5 expenses ranking
- Spending by source analysis
- Month-over-month comparison

### Settings & Security
- Biometric lock configuration
- Data backup and restore
- Authentication testing
- Database information

---

## 🚀 Quick Start

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- iOS 11+ or Android 5.0+

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/shakelz/daily_expense_tracker.git
cd daily_expense_tracker
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### Build for Release

**Android APK**
```bash
flutter build apk --release
```

**iOS App**
```bash
flutter build ios --release
```

**Web App**
```bash
flutter build web --release
```

---

## 📊 Project Structure

```
lib/
├── main.dart                      # App entry point
├── bubble_overlay.dart            # Floating bubble interface
├── models/
│   └── expense_entry.dart         # Data model for transactions
├── screens/
│   ├── home_page_redesign.dart    # Main dashboard
│   ├── settings_tab.dart          # Settings & security
│   ├── analysis_tab.dart          # Analytics & reports
│   ├── budgets_tab.dart           # Budget management
│   ├── account_management_screen.dart
│   ├── all_transactions_screen.dart
│   ├── recurring_transactions_tab.dart
│   └── insights_tab.dart
├── services/
│   ├── database_helper.dart       # SQLite operations
│   ├── backup_restore_service.dart # Data backup
│   ├── security_service.dart      # Biometric auth
│   ├── preferences_service.dart   # User preferences
│   └── notification_helper.dart
├── utils/
│   └── constants.dart             # App constants
└── widgets/
    ├── floating_transaction_form.dart
    └── [other custom widgets]
```

---

## 🔐 Security Features

### Authentication
- Biometric lock (fingerprint/face recognition)
- PIN/Pattern fallback
- Configurable retry limits
- Authentication logging

### Data Protection
- SQLite database encryption-ready
- Emergency backup system
- Data integrity verification
- Safe database restoration

### Privacy
- All data stored locally
- No cloud synchronization (optional)
- No third-party tracking
- User-controlled permissions

---

## 💾 Database Schema

### Transactions Table
```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  date TEXT NOT NULL,
  isIncome INTEGER NOT NULL
);
```

**Supported Fields**:
- Transaction ID (auto-generated)
- Title/Description
- Amount (double precision)
- Category (Income/Expense types)
- Date (ISO8601 format)
- Type (Income: 1, Expense: 0)

---

## 🎨 UI/UX Design

### Theme System
- **Light Theme**: Clean, professional Material 3 design
- **Dark Theme**: Easy on the eyes, premium feel
- **Colors**: Teal primary (#2B7A91), supporting grays
- **Typography**: Google Fonts (Poppins)

### Navigation
- Bottom tab navigation
- 4 main sections: Home, Budget, Reports, Settings
- Deep linking support
- Smooth transitions

---

## 🧪 Testing

### Manual Testing Guide
Comprehensive testing guide available in: `SETTINGS_TESTING_GUIDE.md`

**Test Scenarios**:
- ✅ Authentication (Biometric + Fallback)
- ✅ Backup & Restore functionality
- ✅ Data integrity checks
- ✅ UI consistency across devices
- ✅ Error handling and recovery
- ✅ Performance under load

### Unit Testing
```bash
flutter test
```

---

## 📚 Documentation

This project includes comprehensive documentation:

| Document | Purpose |
|----------|---------|
| `SETTINGS_FIXES_SUMMARY.md` | Recent fixes and improvements |
| `FINAL_IMPLEMENTATION_REPORT.md` | Complete technical report |
| `SETTINGS_TESTING_GUIDE.md` | Testing procedures & checklist |
| `SETTINGS_UI_VISUAL_GUIDE.md` | UI visual reference guide |
| `README_QUICK_REFERENCE.md` | Quick start reference |
| `ARCHITECTURE.md` | System architecture overview |

---

## 🔄 Recent Updates (January 2026)

### Settings Tab Complete Overhaul ✨
- Renamed "Profile" to "Settings"
- Fixed restore data functionality
- Enhanced biometric authentication
- Professional dark-themed dialogs
- Added emergency backup system
- Data integrity verification

### UI/UX Improvements
- Dark theme for all dialogs
- Better loading indicators
- Informative error messages
- User feedback hints
- Consistent styling throughout

### Technical Enhancements
- Robust error handling
- Emergency data recovery
- Device compatibility checks
- Comprehensive logging
- Production-ready code

---

## 🛠️ Technology Stack

### Core
- **Framework**: Flutter 3.0+
- **Language**: Dart 3.0+
- **Database**: SQLite (sqflite)
- **Authentication**: Local Auth (Biometric)

### UI/UX
- **Design System**: Material 3
- **Icons**: Material Icons + Cupertino Icons
- **Fonts**: Google Fonts (Poppins)
- **Charts**: FL Charts

### Services
- **File Management**: File Picker, Path Provider
- **Sharing**: Share Plus
- **Notifications**: Flutter Local Notifications
- **Background Tasks**: Workmanager

### Development
- **Linting**: Flutter Lints
- **Code Style**: Dart Format
- **Testing**: Flutter Test

---

## 📥 Dependencies

Key dependencies (see `pubspec.yaml` for full list):

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0
  path: ^1.8.3
  local_auth: ^2.1.0
  file_picker: ^5.3.0
  share_plus: ^7.0.0
  fl_chart: ^0.65.0
  google_fonts: ^5.1.0
  flutter_local_notifications: ^14.1.0
  workmanager: ^0.5.1
```

---

## 🚨 Known Limitations

- Web platform has limited biometric support
- Desktop (Windows/Linux) doesn't support biometric auth
- iOS requires biometric permission in Info.plist

---

## 🐛 Bug Reports & Features

Found a bug or have a feature request?
- **GitHub Issues**: https://github.com/shakelz/daily_expense_tracker/issues
- **Email**: shakelz@example.com

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Author

**Shakelz**
- GitHub: [@shakelz](https://github.com/shakelz)
- Repository: [daily_expense_tracker](https://github.com/shakelz/daily_expense_tracker)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Community for invaluable resources and support
- Material Design for design guidelines
- All contributors and testers

---

## 📞 Support

### Getting Help
1. Check the [documentation files](https://github.com/shakelz/daily_expense_tracker)
2. Review [testing guide](SETTINGS_TESTING_GUIDE.md) for common issues
3. Open an [issue](https://github.com/shakelz/daily_expense_tracker/issues)

### Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design](https://material.io/design)

---

**Happy Tracking! 💰**

> Track your expenses with confidence. Built with ❤️ using Flutter.

---

**Last Updated**: January 29, 2026  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
