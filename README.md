# FCM Notifications - Flutter App

A Flutter application that receives Firebase Cloud Messaging (FCM) push notifications when new posts are published or updated, with Google Calendar integration for scheduling appointments.

## 🚀 Features

- **Real-time Notifications**: Receive push notifications for new and updated posts
- **Category Filtering**: Admin can select which post categories trigger notifications
- **Deep Linking**: Tap notifications to navigate directly to post details
- **Local Notifications**: Display notifications when app is in foreground
- **Google Calendar Integration**: Schedule appointments with automatic calendar event creation
- **Attendee Invitations**: Automatically invite support/developer to scheduled meetings
- **Secure API**: App key authentication for WordPress REST API
- **Development Mode**: Easy testing without authentication

## 📋 Prerequisites

- Flutter SDK (latest stable)
- Firebase project with FCM enabled
- Backend API with FCM support
- Android Studio / Xcode for building
- Google Cloud project for Calendar API (for schedule feature)

## 🔧 Setup

### 1. Firebase Configuration

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android/iOS apps to your Firebase project
3. Download `google-services.json` (Android) and place in `android/app/`
4. Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`

### 2. Backend Configuration

1. Configure Firebase credentials in WordPress Admin → Settings → FCM Notifications
2. Set up category filters (optional) to control which posts trigger notifications

### 3. Google Calendar API Setup (for Schedule Feature)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Google Calendar API**
4. Configure OAuth consent screen:
   - User Type: External
   - Add test users (your Gmail addresses)
   - Add scope: `https://www.googleapis.com/auth/calendar`
5. Create OAuth 2.0 Client IDs:
   - **Android**: Use package name `com.example.wp_fcm_test` and your SHA-1 fingerprint
   - Get SHA-1: `cd android && ./gradlew signingReport`
6. Add your test Gmail to OAuth consent screen → Test users

### 4. Flutter App Configuration

1. Create `.env` file in project root (optional for production):

```env
WORDPRESS_URL=https://your-backend-api.com
FCM_APP_KEY=your_app_key_from_backend
```

2. Update schedule screen support email in `lib/screens/schedule_screen.dart`:

```dart
const String appSupportEmail = 'your-support@email.com';
```

3. Install dependencies:

```bash
flutter clean
flutter pub get
flutter run
```

## 📱 Development Mode

For testing without app key authentication, set `isDevelopmentMode = true` in `lib/services/wordpress_service.dart` (or your backend service file):

```dart
static const bool isDevelopmentMode = true; // Toggle for dev/production
```

**⚠️ Set to `false` for production!**

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point with bottom navigation
├── screens/
│   ├── posts_screen.dart         # Posts list & detail screens
│   └── schedule_screen.dart      # Appointment scheduling with Google Calendar
└── services/
    ├── fcm_service.dart          # FCM & local notifications
    ├── navigation_service.dart   # Deep linking navigation
    ├── wordpress_service.dart    # WordPress REST API
    └── google_calendar_service.dart  # Google Calendar integration
```

## 🎯 Key Features Explained

### Schedule Feature (App Support Calendar Integration)
**New Approach**: The app uses a pre-authenticated support account to send calendar invitations to users.

**How it works:**
1. **Support Account Setup**: The app is connected to a support email (e.g., `jendralpochin02@gmail.com`)
2. **User Input**: Users only need to enter their email address
3. **Calendar Invitation**: The support account creates the event and sends an invitation to the user's email
4. **No User Login Required**: Users don't need to sign in with Google - they just receive the invitation

**Features:**
- Date selection (Today, Tomorrow, Next Monday, or custom date)
- Time slot selection (9:00 AM - 6:00 PM, 30-min intervals)
- Auto-disable past time slots
- Verification method (WhatsApp or Google Meet)
- Automatic Google Meet link generation (for Google Meet option)
- Calendar invitation sent to user's email
- Support team receives the event in their calendar

### Category Filter
Admins can:
- Select specific post categories that trigger notifications
- "Select All" / "Deselect All" functionality
- View currently configured categories
- If no categories selected, all posts trigger notifications

### Notification System
- Foreground: Local notifications via flutter_local_notifications
- Background: FCM handles notifications automatically
- Tap notification → Navigate to post detail
- Subscribe to "all_posts" topic on app start

## 🔐 Security

- **Environment Variables**: Store credentials in `.env` (never commit!)
- **App Key Authentication**: Secure REST API endpoints
- **SSL Verification**: All API requests use HTTPS
- **Rate Limiting**: Backend includes rate limiting (60s cooldown)
- **OAuth 2.0**: Secure Google Sign-In for Calendar API

## 🐛 Troubleshooting

### Notifications not received
1. Check FCM token is registered in backend admin panel
2. Verify Firebase credentials are correct
3. Check if post category is included in notification filter
4. Test with "Send Test Notification" in admin panel

### Google Calendar Setup for Support Account
**Important**: The support account needs to be authenticated once:

1. **First Time Setup**:
   - When the app first runs, it will prompt for Google Sign-In
   - Sign in with the support email (`jendralpochin02@gmail.com`)
   - Grant Calendar permissions
   - After this, the app stays authenticated

2. **OAuth Consent Screen**:
   - Add the support email as a Test User in Google Cloud Console
   - Enable Google Calendar API
   - Configure OAuth Client ID with correct package name and SHA-1

3. **Troubleshooting 403: access_denied**:
   - Make sure support email is added as Test User
   - Verify Calendar API is enabled
   - Check OAuth Client ID configuration
   - Clear app data and sign in again with support account

### App crashes after calendar event creation
Fixed with:
- MultiDex enabled (for large dependencies)
- Updated desugaring library to 2.1.2
- Calendar URL opening disabled (event created, but doesn't auto-open calendar app)

### Build errors
```bash
cd android && ./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

## 📚 Additional Information

See [CHANGELOG.md](CHANGELOG.md) for version history and updates.

## 🔄 Changelog

### Latest Changes
- ✅ **NEW**: Reversed Google Calendar flow - Support account sends invitations to users
- ✅ **NEW**: Users only need to input their email (no Google login required)
- ✅ **NEW**: Automatic Google Meet link generation
- ✅ Added Google Calendar integration for scheduling
- ✅ Implemented attendee invitation system
- ✅ Added category filter for notifications
- ✅ Removed environment variable dependency (Admin UI only)
- ✅ Enhanced error handling and logging
- ✅ Fixed app crashes (MultiDex, desugaring updates)

## 📄 License

This project is open source and available for personal and commercial use.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

**Made with ❤️ using Flutter**
