import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/google_calendar_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedTime = '15:00 WIB';
  String verificationMethod = 'whatsapp';
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Date selection options
  final List<Map<String, dynamic>> dateOptions = [
    {'label': 'Hari Ini', 'days': 0},
    {'label': 'Besok', 'days': 1},
    {'label': 'Senin', 'weekday': DateTime.monday},
    {'label': 'Hari DD MMM', 'custom': true},
    {'label': 'Hari DD', 'custom': true},
  ];

  // Time slots
  final List<String> timeSlots = [
    '09:00 WIB',
    '09:30 WIB',
    '10:00 WIB',
    '10:30 WIB',
    '11:00 WIB',
    '11:30 WIB',
    '13:00 WIB',
    '13:30 WIB',
    '14:00 WIB',
    '14:30 WIB',
    '15:00 WIB',
    '15:30 WIB',
    '16:00 WIB',
    '16:30 WIB',
    '17:00 WIB',
    '17:30 WIB',
    '18:00 WIB',
  ];

  String getDateLabel(Map<String, dynamic> option) {
    if (option['days'] != null) {
      final date = DateTime.now().add(Duration(days: option['days']));
      return '${option['label']}\n${date.day} ${_getMonthName(date.month).substring(0, 3)}';
    } else if (option['weekday'] != null) {
      final nextWeekday = _getNextWeekday(option['weekday']);
      return '${option['label']}\n${nextWeekday.day} ${_getMonthName(nextWeekday.month).substring(0, 3)}';
    }
    return option['label'];
  }

  DateTime _getNextWeekday(int weekday) {
    final now = DateTime.now();
    int daysToAdd = (weekday - now.weekday + 7) % 7;
    if (daysToAdd == 0) daysToAdd = 7;
    return now.add(Duration(days: daysToAdd));
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return months[month - 1];
  }

  Future<void> _selectCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  /// Check if time slot is in the past
  bool _isTimeSlotPast(String timeSlot) {
    // Check if selected date is today
    final now = DateTime.now();
    final isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (!isToday) {
      return false; // Future dates are always available
    }

    // Parse time from slot (e.g., "09:00 WIB" -> 09:00)
    final timeParts = timeSlot.split(' ')[0].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final slotDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    return slotDateTime.isBefore(now);
  }

  /// Parse time slot to DateTime
  DateTime _parseTimeSlot(String timeSlot) {
    final timeParts = timeSlot.split(' ')[0].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );
  }

  Future<void> _handleSubmit() async {
    // Validate email
    final userEmail = _emailController.text.trim();
    if (userEmail.isEmpty || !userEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Mohon masukkan email yang valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize Indonesian locale data
      await initializeDateFormatting('id_ID', null);

      // Check if support account is signed in
      if (!_calendarService.isSignedIn) {
        final initialized = await _calendarService.initializeSupportAccount();
        if (!initialized) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '❌ Gagal menghubungkan ke akun support. Silakan coba lagi.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Parse the selected time
      final startTime = _parseTimeSlot(selectedTime);
      final endTime = startTime.add(
        const Duration(hours: 1),
      ); // 1 hour duration

      // Prepare event details
      final String title = verificationMethod == 'whatsapp'
          ? 'Video Call via WhatsApp'
          : 'Video Call via Google Meet';

      final String description =
          'Scheduled ${verificationMethod == 'whatsapp' ? 'WhatsApp' : 'Google Meet'} video call.\n\n'
          'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(selectedDate)}\n'
          'Waktu: $selectedTime\n'
          'Email Peserta: $userEmail\n\n'
          'Anda akan menerima undangan kalender di email Anda.';

      // Create calendar event and send invitation to user
      final success = await _calendarService.createCalendarEventForUser(
        userEmail: userEmail,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        location: verificationMethod == 'whatsapp' ? 'WhatsApp' : 'Google Meet',
        createMeetLink:
            verificationMethod == 'googlemeet', // Auto-generate Meet link
      );

      if (mounted) {
        if (success) {
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('✅ Jadwal Berhasil Dibuat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy').format(selectedDate)}',
                  ),
                  const SizedBox(height: 8),
                  Text('Waktu: $selectedTime'),
                  const SizedBox(height: 8),
                  Text(
                    'Metode: ${verificationMethod == 'whatsapp' ? 'WhatsApp' : 'Google Meet'}',
                  ),
                  const SizedBox(height: 8),
                  Text('Email: $userEmail'),
                  const SizedBox(height: 16),
                  const Text(
                    '📧 Undangan kalender telah dikirim ke email Anda. Silakan cek inbox atau spam folder.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Clear form
                    _emailController.clear();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Gagal membuat jadwal. Silakan coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _handleSubmit: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Jadwal'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selection
              const Text(
                'Pilih Tanggal',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Today
                    _buildDateButton(
                      'Hari Ini\n${DateTime.now().day} ${_getMonthName(DateTime.now().month).substring(0, 3)}',
                      DateTime.now(),
                    ),
                    const SizedBox(width: 8),
                    // Tomorrow
                    _buildDateButton(
                      'Besok\n${DateTime.now().add(const Duration(days: 1)).day} ${_getMonthName(DateTime.now().add(const Duration(days: 1)).month).substring(0, 3)}',
                      DateTime.now().add(const Duration(days: 1)),
                    ),
                    const SizedBox(width: 8),
                    // Next Monday
                    _buildDateButton(
                      'Senin\n${_getNextWeekday(DateTime.monday).day} ${_getMonthName(_getNextWeekday(DateTime.monday).month).substring(0, 3)}',
                      _getNextWeekday(DateTime.monday),
                    ),
                    const SizedBox(width: 8),
                    // Calendar icon
                    _buildCalendarButton(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time Selection
              const Text(
                'Pilih Waktu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: timeSlots.map((time) {
                    final isSelected = time == selectedTime;
                    final isPast = _isTimeSlotPast(time);

                    return InkWell(
                      onTap: isPast
                          ? null
                          : () {
                              setState(() {
                                selectedTime = time;
                              });
                            },
                      child: Opacity(
                        opacity: isPast ? 0.4 : 1.0,
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPast
                                ? Colors.grey[300]
                                : (isSelected ? Colors.blue : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isPast
                                  ? Colors.grey[400]!
                                  : (isSelected
                                        ? Colors.blue
                                        : Colors.grey[300]!),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            time,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isPast
                                  ? Colors.grey[600]
                                  : (isSelected
                                        ? Colors.white
                                        : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              decoration: isPast
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Email Input
              const Text(
                'Email Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'contoh@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  helperText: 'Undangan kalender akan dikirim ke email ini',
                  helperStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 24),

              // Verification Method
              const Text(
                'Metode Verifikasi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildVerificationMethod(
                      'whatsapp',
                      Icons.chat,
                      'Video Call via\nWhatsApp',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildVerificationMethod(
                      'googlemeet',
                      Icons.video_call,
                      'Video Call via\nGoogle Meet',
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Pilih',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date) {
    final isSelected =
        selectedDate.year == date.year &&
        selectedDate.month == date.month &&
        selectedDate.day == date.day;

    return InkWell(
      onTap: () {
        setState(() {
          selectedDate = date;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarButton() {
    return InkWell(
      onTap: _selectCustomDate,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildVerificationMethod(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    final isSelected = verificationMethod == value;
    return InkWell(
      onTap: () {
        setState(() {
          verificationMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: verificationMethod,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    verificationMethod = val;
                  });
                }
              },
              activeColor: color,
            ),
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
