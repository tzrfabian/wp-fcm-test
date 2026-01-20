# Google Calendar Integration - Setup Guide

## 📋 Overview

The app now uses a **reversed calendar invitation flow**:
- **Before**: Users signed in with their Google account to create events
- **After**: App support account creates events and sends invitations to users

## ✨ Benefits

1. **Simpler for Users**: Users only need to provide their email address
2. **No Google Login Required**: Users don't need a Google account to receive invitations
3. **Centralized Management**: All appointments are in the support account's calendar
4. **Better Control**: Support team can manage all scheduled appointments in one place

## 🔧 How It Works

### User Flow
1. User opens the Schedule screen
2. User selects date and time
3. User enters their email address
4. User selects verification method (WhatsApp or Google Meet)
5. User clicks "Pilih" (Submit)
6. **Calendar invitation is sent to user's email**
7. User receives email with calendar invitation
8. User can accept/decline the invitation

### Technical Flow
1. App is pre-authenticated with support account (`jendralpochin03@gmail.com`)
2. When user submits, app creates event in support account's calendar
3. User is added as attendee
4. Google Calendar automatically sends invitation email to user
5. If Google Meet is selected, a Meet link is automatically generated

## 🚀 Setup Instructions

### 1. Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select your project
3. Enable **Google Calendar API**
4. Configure **OAuth Consent Screen**:
   - Add your support email as a Test User
   - Add required scopes: `https://www.googleapis.com/auth/calendar`

### 2. OAuth Client ID Configuration

1. Create OAuth 2.0 Client ID (Android)
2. Add your package name: `com.example.wp_fcm_test`
3. Add SHA-1 certificate fingerprint:
   ```bash
   # Debug certificate
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release certificate (for production)
   keytool -list -v -keystore your-release-key.jks -alias your-key-alias
   ```

### 3. Update Support Email (Optional)

If you want to use a different support email:

1. Open `lib/services/google_calendar_service.dart`
2. Change line 11:
   ```dart
   static const String appSupportEmail = 'your-support-email@gmail.com';
   ```

### 4. First Time Authentication

**Important**: The support account needs to authenticate once:

1. Run the app for the first time
2. Navigate to Schedule screen
3. Fill in the form and submit
4. **Google Sign-In popup will appear**
5. Sign in with the support email
6. Grant Calendar permissions
7. After this, the app stays authenticated (no need to sign in again)

## 📧 Email Invitation Details

When a user schedules an appointment, they receive an email with:

- **Event Title**: "Video Call via WhatsApp" or "Video Call via Google Meet"
- **Date & Time**: Selected by user
- **Description**: Full details including user's email
- **Location**: WhatsApp or Google Meet
- **Meet Link**: Automatically generated (if Google Meet is selected)
- **Action Buttons**: Accept, Maybe, Decline

## 🔒 Security Considerations

1. **OAuth 2.0**: Secure authentication with Google
2. **Token Storage**: Tokens are stored securely by Google Sign-In SDK
3. **Silent Sign-In**: After first authentication, app signs in silently
4. **Revoke Access**: Users can revoke app access from Google Account settings

## 🐛 Troubleshooting

### Error: 403 access_denied
**Solution**: 
- Make sure support email is added as Test User in OAuth consent screen
- Verify Calendar API is enabled
- Check OAuth Client ID configuration

### Calendar invitation not received
**Solution**:
- Check user's spam folder
- Verify user entered correct email address
- Check support account's calendar for the event
- Ensure internet connection is stable

### Sign-in popup doesn't appear
**Solution**:
- Clear app data and try again
- Verify OAuth Client ID is configured correctly
- Check SHA-1 certificate matches

### Error: Calendar API not initialized
**Solution**:
- App will automatically prompt for sign-in
- Make sure to complete the sign-in process
- Check internet connection

## 📱 Testing

1. **Test with your own email**:
   ```
   Date: Today
   Time: Any future time slot
   Email: your-email@example.com
   Method: Google Meet
   ```

2. **Check support calendar**:
   - Open Google Calendar with support account
   - Verify event is created
   - Check attendee list includes user email

3. **Check user email**:
   - Open user's email inbox
   - Look for calendar invitation from support account
   - Verify Meet link works (if Google Meet selected)

## 🎯 Best Practices

1. **Support Email**: Use a dedicated support email (not personal)
2. **Calendar Management**: Regularly check support calendar for appointments
3. **Email Validation**: App validates email format before submission
4. **Time Slots**: Past time slots are automatically disabled
5. **User Communication**: Inform users to check spam folder

## 📊 Monitoring

Check the following regularly:
- Support account's Google Calendar for all appointments
- Email delivery status
- User feedback on invitation receipt
- OAuth token validity

## 🔄 Future Improvements

Potential enhancements:
- SMS notifications in addition to email
- Appointment reminders
- Rescheduling functionality
- Cancellation by user
- Integration with CRM systems

---

**Need Help?** Check the main [README.md](README.md) or contact the development team.
