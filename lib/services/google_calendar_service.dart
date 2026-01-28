import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  // This email will be used to create calendar events and send invitations to users
  // For service account impersonation, this must be a Google Workspace user
  static const String appSupportEmail = 'jendralpochin02@gmail.com';

  // Set to true to use service account (automatic auth)
  // Set to false to use OAuth (user sign-in)
  static const bool useServiceAccount = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  GoogleSignInAccount? _supportAccount;
  calendar.CalendarApi? _calendarApi;
  auth.AutoRefreshingAuthClient? _serviceAccountClient;

  /// Initialize and sign in with app support account
  /// This should be called once when the app starts
  Future<bool> initializeSupportAccount() async {
    if (useServiceAccount) {
      return await _initializeWithServiceAccount();
    } else {
      return await _initializeWithOAuth();
    }
  }

  /// Initialize using Service Account (no user interaction required)
  Future<bool> _initializeWithServiceAccount() async {
    try {
      // Load service account credentials from assets
      // You need to add your service account JSON to assets/service_account.json
      final jsonString = await rootBundle.loadString(
        'assets/service_account.json',
      );
      final credentials = auth.ServiceAccountCredentials.fromJson(
        json.decode(jsonString),
      );

      // Create authenticated client with calendar scope
      // Note: For impersonation to work, you need Google Workspace with domain-wide delegation
      _serviceAccountClient = await auth.clientViaServiceAccount(credentials, [
        calendar.CalendarApi.calendarScope,
      ]);

      _calendarApi = calendar.CalendarApi(_serviceAccountClient!);

      print('✅ Service account initialized successfully');
      return true;
    } catch (error) {
      print('❌ Error initializing service account: $error');
      print('💡 Falling back to OAuth sign-in...');
      return await _initializeWithOAuth();
    }
  }

  /// Initialize using OAuth (requires user sign-in)
  Future<bool> _initializeWithOAuth() async {
    try {
      // Try to sign in silently first (if already authenticated)
      final account = await _googleSignIn.signInSilently();

      if (account != null) {
        _supportAccount = account;
        print('✅ Support account signed in silently: ${account.email}');

        // Get authentication headers
        final authHeaders = await account.authHeaders;
        final authenticateClient = GoogleAuthClient(authHeaders);
        _calendarApi = calendar.CalendarApi(authenticateClient);

        return true;
      }

      // If silent sign-in fails, prompt for sign-in
      return await _signInSupportAccount();
    } catch (error) {
      print('❌ Error initializing support account: $error');
      return await _signInSupportAccount();
    }
  }

  /// Sign in with app support account (with user interaction)
  Future<bool> _signInSupportAccount() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        print('❌ Google Sign In cancelled');
        return false;
      }

      _supportAccount = account;
      print('✅ Support account signed in: ${account.email}');

      // Get authentication headers
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      _calendarApi = calendar.CalendarApi(authenticateClient);

      return true;
    } catch (error) {
      print('❌ Error signing in support account: $error');
      return false;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    if (useServiceAccount && _serviceAccountClient != null) {
      _serviceAccountClient!.close();
      _serviceAccountClient = null;
    } else {
      await _googleSignIn.signOut();
      _supportAccount = null;
    }
    _calendarApi = null;
    print('✅ Signed out');
  }

  /// Check if support account is signed in
  bool get isSignedIn => _calendarApi != null;

  /// Get support account email
  String? get supportAccountEmail =>
      useServiceAccount ? appSupportEmail : _supportAccount?.email;

  /// Create a calendar event with app support as initiator and user as attendee
  ///
  /// Flow:
  /// 1. Service account creates the event
  /// 2. App support email is added as 1st attendee (call initiator)
  /// 3. User email is added as 2nd attendee
  /// 4. Both receive calendar invitations
  Future<bool> createCalendarEventForUser({
    required String userEmail,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    String? meetingLink,
    bool createMeetLink = false,
  }) async {
    try {
      if (_calendarApi == null) {
        print(
          '❌ Calendar API not initialized. Please initialize support account first.',
        );
        return false;
      }

      // Validate user email
      if (userEmail.isEmpty || !userEmail.contains('@')) {
        print('❌ Invalid user email: $userEmail');
        return false;
      }

      // Create event
      final event = calendar.Event()
        ..summary = title
        ..description = description
        ..location = location
        ..start = calendar.EventDateTime()
        ..start!.dateTime = startTime
        ..start!.timeZone = 'Asia/Jakarta'
        ..end = calendar.EventDateTime()
        ..end!.dateTime = endTime
        ..end!.timeZone = 'Asia/Jakarta';

      // Add conference data for Google Meet if needed
      if (createMeetLink) {
        event.conferenceData = calendar.ConferenceData()
          ..createRequest = (calendar.CreateConferenceRequest()
            ..requestId = DateTime.now().millisecondsSinceEpoch.toString());
      } else if (meetingLink != null) {
        event.hangoutLink = meetingLink;
      }

      // Add attendees:
      // 1st attendee: App support (call initiator) - auto-accepted
      // 2nd attendee: User (needs to respond)
      event.attendees = [
        // App support as call initiator (1st attendee)
        calendar.EventAttendee()
          ..email = appSupportEmail
          ..responseStatus =
              'accepted' // Auto-accept for support
          ..organizer = false
          ..comment = 'Call Initiator',
        // User as 2nd attendee
        calendar.EventAttendee()
          ..email = userEmail
          ..responseStatus =
              'needsAction' // User needs to respond
          ..organizer = false,
      ];

      // Insert event with sendUpdates='all' to send invitation to all attendees
      final createdEvent = await _calendarApi!.events.insert(
        event,
        'primary',
        conferenceDataVersion: createMeetLink ? 1 : 0,
        sendUpdates: 'all', // Send email invitation to all attendees
      );

      print('✅ Event created: ${createdEvent.htmlLink}');
      print('📧 Calendar invitation sent to:');
      print('   - Call Initiator: $appSupportEmail');
      print('   - User: $userEmail');

      if (createMeetLink && createdEvent.conferenceData?.entryPoints != null) {
        final meetLink = createdEvent.conferenceData!.entryPoints!
            .firstWhere(
              (e) => e.entryPointType == 'video',
              orElse: () => calendar.EntryPoint(),
            )
            .uri;
        print('🎥 Google Meet link: $meetLink');
      }

      return true;
    } catch (error) {
      print('❌ Error creating calendar event: $error');
      return false;
    }
  }

  /// Get the Google Meet link from a created event
  String? getMeetLinkFromEvent(calendar.Event event) {
    if (event.conferenceData?.entryPoints != null) {
      for (var entryPoint in event.conferenceData!.entryPoints!) {
        if (entryPoint.entryPointType == 'video') {
          return entryPoint.uri;
        }
      }
    }
    return event.hangoutLink;
  }
}

/// Custom HTTP client for Google API
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}
