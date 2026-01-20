import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  // This email will be used to create calendar events and send invitations to users
  static const String appSupportEmail = 'jendralpochin02@gmail.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  GoogleSignInAccount? _supportAccount;
  calendar.CalendarApi? _calendarApi;

  /// Initialize and sign in with app support account
  /// This should be called once when the app starts
  Future<bool> initializeSupportAccount() async {
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
    await _googleSignIn.signOut();
    _supportAccount = null;
    _calendarApi = null;
    print('✅ Signed out');
  }

  /// Check if support account is signed in
  bool get isSignedIn => _supportAccount != null;

  /// Get support account email
  String? get supportAccountEmail => _supportAccount?.email;

  /// Create a calendar event and send invitation to user
  /// The event is created in the support account's calendar and user receives invitation
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
        print('❌ Calendar API not initialized. Please initialize support account first.');
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

      // Add user as attendee (they will receive invitation email)
      event.attendees = [
        calendar.EventAttendee()
          ..email = userEmail
          ..responseStatus = 'needsAction', // User needs to respond
      ];

      // Insert event with sendUpdates='all' to send invitation to user
      final createdEvent = await _calendarApi!.events.insert(
        event,
        'primary',
        conferenceDataVersion: createMeetLink ? 1 : 0,
        sendUpdates: 'all', // Send email invitation to user
      );

      print('✅ Event created: ${createdEvent.htmlLink}');
      print('📧 Calendar invitation sent to: $userEmail');

      return true;
    } catch (error) {
      print('❌ Error creating calendar event: $error');
      return false;
    }
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
