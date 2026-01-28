import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Simple scheduling service that adds events directly to user's device calendar
/// Requires calendar permission - auto-saves without opening calendar app
class ScheduleService {
  static final ScheduleService _instance = ScheduleService._internal();
  factory ScheduleService() => _instance;
  ScheduleService._internal();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  String? _selectedCalendarId;
  bool _timezoneInitialized = false;

  /// Initialize timezone data
  void _initializeTimezone() {
    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      _timezoneInitialized = true;
    }
  }

  /// Request calendar permission and get available calendars
  Future<bool> requestPermission() async {
    var permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
    if (permissionsGranted.isSuccess && (permissionsGranted.data == null || permissionsGranted.data == false)) {
      permissionsGranted = await _deviceCalendarPlugin.requestPermissions();
      if (!permissionsGranted.isSuccess || permissionsGranted.data == null || permissionsGranted.data == false) {
        print('❌ Calendar permission denied');
        return false;
      }
    }
    print('✅ Calendar permission granted');
    return true;
  }

  /// Get available calendars and select the default one
  Future<bool> _selectDefaultCalendar() async {
    if (_selectedCalendarId != null) return true;

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null || calendarsResult.data!.isEmpty) {
      print('❌ No calendars found');
      return false;
    }

    // Find a writable calendar (prefer the default/primary one)
    final calendars = calendarsResult.data!;
    
    // Try to find a writable calendar
    Calendar? selectedCalendar;
    for (var calendar in calendars) {
      if (!calendar.isReadOnly!) {
        selectedCalendar = calendar;
        // Prefer calendars with "primary" or "default" in name, or the first Google calendar
        if (calendar.name?.toLowerCase().contains('primary') == true ||
            calendar.name?.toLowerCase().contains('default') == true ||
            calendar.accountName?.contains('google') == true) {
          break;
        }
      }
    }

    if (selectedCalendar == null) {
      print('❌ No writable calendar found');
      return false;
    }

    _selectedCalendarId = selectedCalendar.id;
    print('✅ Selected calendar: ${selectedCalendar.name} (${selectedCalendar.accountName})');
    return true;
  }

  /// Create a schedule and auto-save to user's device calendar
  /// Returns true if event was saved successfully
  Future<bool> createSchedule({
    required String userName,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    try {
      // Initialize timezone
      _initializeTimezone();

      // Request permission if needed
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        return false;
      }

      // Select default calendar
      final hasCalendar = await _selectDefaultCalendar();
      if (!hasCalendar) {
        return false;
      }

      // Get local timezone
      final localTimezone = tz.local;

      // Create the event
      final event = Event(
        _selectedCalendarId,
        title: title,
        description: '$description\n\nNama: $userName',
        location: location,
        start: tz.TZDateTime.from(startTime, localTimezone),
        end: tz.TZDateTime.from(endTime, localTimezone),
        reminders: [Reminder(minutes: 30)], // Reminder 30 min before
      );

      // Save event directly to calendar (no UI needed)
      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);

      if (result?.isSuccess == true && result?.data != null) {
        print('✅ Calendar event auto-saved successfully! Event ID: ${result!.data}');
        return true;
      } else {
        print('❌ Failed to save calendar event: ${result?.errors}');
        return false;
      }
    } catch (e) {
      print('❌ Error adding to calendar: $e');
      return false;
    }
  }
}
