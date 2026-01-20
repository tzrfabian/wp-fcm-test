# Changelog

All notable changes to this project will be documented in this file.

## [2026-01-12] - Latest

### ✨ Added
- **Google Calendar Integration**
  - Schedule appointments with date and time selection
  - Automatic calendar event creation with Google Calendar API
  - Attendee invitation system (automatically invite support/developer)
  - Smart time slot disabling for past times
  - WhatsApp and Google Meet verification methods

- **Category Filter for Notifications**
  - Multiple selection category filter in WordPress admin UI
  - Choose which post categories trigger notifications
  - "Select All / Deselect All" functionality
  - Status display showing selected categories
  - Backward compatible (no categories = all posts)

### 🔧 Changed
- **Removed environment variable support** - All settings now managed through WordPress Admin UI only
- **Disabled automatic calendar app opening** - Prevents crashes; events still created successfully
- **Updated Android build configuration** - MultiDex enabled, desugaring library updated to 2.1.2

### 🐛 Fixed
- **App crash after calendar event creation** - Added MultiDex support and updated desugaring library
- **Hidden API access errors** - Updated Android build configuration
- **Locale initialization error** - Added Indonesian locale initialization before DateFormat usage
- **Date selection buttons not working** - Made date buttons interactive with proper state management
- **500 Internal Server Error** - Added automatic table creation and improved error handling

### 📚 Documentation
- Consolidated documentation into main README.md
- Updated WordPress plugin guides
- Added Google Calendar setup instructions
- Improved troubleshooting section

### 🔐 Security
- OAuth 2.0 for Google Sign-In
- App key authentication for WordPress API
- Rate limiting on WordPress endpoints
- All credentials stored securely in WordPress database

---

For detailed documentation, see [README.md](README.md)
