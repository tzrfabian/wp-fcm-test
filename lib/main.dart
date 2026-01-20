import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/fcm_service.dart';
import 'services/wordpress_service.dart';
import 'services/navigation_service.dart';
import 'services/google_calendar_service.dart';
import 'screens/posts_screen.dart';
import 'screens/schedule_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (only needed in production mode)
  if (!WordPressService.isDevelopmentMode) {
    await dotenv.load(fileName: ".env");
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize FCM
  final fcmService = FCMService();
  await fcmService.initialize();

  // Subscribe to 'all_posts' topic for broadcast notifications
  await fcmService.subscribeToTopic('all_posts');

  // Register FCM token with WordPress backend
  if (fcmService.fcmToken != null && WordPressService.isConfigured) {
    final wpService = WordPressService();
    await wpService.registerFCMToken(fcmService.fcmToken!);
  } else if (!WordPressService.isConfigured) {
    debugPrint(
      '⚠️ WordPress URL not configured. Update baseUrl in wordpress_service.dart',
    );
  }

  // Initialize Google Calendar support account (silent sign-in)
  final calendarService = GoogleCalendarService();
  final calendarInitialized = await calendarService.initializeSupportAccount();
  if (calendarInitialized) {
    debugPrint('✅ Google Calendar support account initialized');
  } else {
    debugPrint('⚠️ Google Calendar support account not initialized - will prompt on first use');
  }

  // Show development mode status
  if (WordPressService.isDevelopmentMode) {
    debugPrint('🔧 Running in DEVELOPMENT mode - No app key required');
  } else {
    debugPrint('🔒 Running in PRODUCTION mode - App key required');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordPress FCM App',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService().navigatorKey, // Enable deep linking
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WordPress Posts'),
      // Define routes for navigation
      routes: {
        '/post': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final postId = args?['post_id'] ?? '0';
          return PostDetailScreen(postId: postId);
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PostsScreen(),
    const ScheduleScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fcmService = FCMService();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive notifications for new posts'),
            trailing: Switch(
              value: true,
              onChanged: (value) {
                // Toggle notifications
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('FCM Token'),
            subtitle: Text(
              fcmService.fcmToken ?? 'Not available',
              style: const TextStyle(fontSize: 10),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                // Copy token to clipboard
                if (fcmService.fcmToken != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Token copied to clipboard')),
                  );
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Token'),
            subtitle: const Text('Get a new FCM token'),
            onTap: () async {
              // Refresh token logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Token refresh requested')),
              );
            },
          ),
        ],
      ),
    );
  }
}
