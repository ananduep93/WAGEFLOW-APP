# WageFlow 🚀

A simple and powerful Flutter application for entrepreneurs to manage labour attendance and wage payments efficiently.

## Features 🎯
- **Authentication**: Phone OTP login flow.
- **Worker Management**: CRUD operations for workers with wage rates.
- **Attendance**: Daily marking (Present/Absent/Half-day) with a calendar view.
- **Payments**: Track paid vs pending amounts and payment history.
- **Dashboard**: Real-time stats for total workers, today's expense, and pending wages.
- **Reports**: Generate and export PDF reports.
- **Offline First**: Full support for offline usage with Hive local storage.
- **Modern UI**: Material Design 3 with premium aesthetics.

## Tech Stack 🧱
- **Flutter**: UI Framework
- **Riverpod**: State Management
- **Hive**: Local NoSQL Database (Offline support)
- **Firebase**: Firestore & Auth (Ready for integration)
- **PDF & Printing**: Document generation


## Project Structure 📁
- `lib/core`: Theming, constants, and global widgets.
- `lib/features`: Module-based screens and logic (Auth, Dashboard, Workers, etc.).
- `lib/models`: Data models with Hive adapters.
- `lib/providers`: Riverpod providers for state management.

## Premium Features 💎
- Advanced reporting.
- Multi-business support.
- WhatsApp payment reminders.
