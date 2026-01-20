import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'navigation_service.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background notification here if needed
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM and local notifications
  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
      return;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Save token to SharedPreferences
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken!);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
      _saveTokenToPreferences(newToken);
      // TODO: Send new token to your WordPress backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Initialize local notifications for Android/iOS
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'wordpress_posts_channel', // id
        'WordPress Posts', // name
        description: 'Notifications for new WordPress posts',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received: ${message.messageId}');
    print('📦 Message data: ${message.data}');

    RemoteNotification? notification = message.notification;

    // Show local notification when app is in foreground
    if (notification != null) {
      // Encode message data as JSON for payload
      String payload = json.encode(message.data);
      
      // Get notification type for logging
      String notificationType = message.data['notification_type'] ?? 'unknown';
      print('🔔 Notification type: $notificationType');
      
      _showLocalNotification(
        title: notification.title ?? 'New Post',
        body: notification.body ?? '',
        payload: payload,
      );
    }
  }

  /// Handle notification tap when app is opened from background/terminated
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 Notification opened: ${message.messageId}');
    print('📦 Data: ${message.data}');

    // Get notification type
    String notificationType = message.data['notification_type'] ?? 'unknown';
    print('🔔 Notification type: $notificationType');
    
    // Log different types
    if (notificationType == 'new') {
      print('✨ Opening NEW post');
    } else if (notificationType == 'update') {
      print('🔄 Opening UPDATED post');
    } else if (notificationType == 'test') {
      print('🧪 Test notification tapped');
    }

    // Navigate to specific post or screen based on message data
    if (message.data.containsKey('post_id')) {
      String postId = message.data['post_id'];
      
      // Don't navigate for test notifications (post_id = '0')
      if (postId != '0') {
        print('🔗 Navigating to post: $postId');
        NavigationService().navigateToPost(postId);
      } else {
        print('ℹ️ Test notification - no navigation needed');
      }
    } else if (message.data.containsKey('post_url')) {
      String postUrl = message.data['post_url'];
      print('🔗 Opening URL: $postUrl');
      NavigationService().navigateToUrl(postUrl);
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'wordpress_posts_channel',
          'WordPress Posts',
          channelDescription: 'Notifications for new WordPress posts',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Handle notification tap (when app is in foreground)
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped');
    
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        // Decode the payload JSON
        final Map<String, dynamic> data = json.decode(response.payload!);
        print('📦 Payload data: $data');
        
        // Get notification type
        String notificationType = data['notification_type'] ?? 'unknown';
        print('🔔 Notification type: $notificationType');
        
        // Log different types
        if (notificationType == 'new') {
          print('✨ Opening NEW post');
        } else if (notificationType == 'update') {
          print('🔄 Opening UPDATED post');
        } else if (notificationType == 'test') {
          print('🧪 Test notification tapped');
        }
        
        // Navigate based on payload data
        if (data.containsKey('post_id')) {
          String postId = data['post_id'].toString();
          
          // Don't navigate for test notifications (post_id = '0')
          if (postId != '0') {
            print('🔗 Navigating to post: $postId');
            NavigationService().navigateToPost(postId);
          } else {
            print('ℹ️ Test notification - no navigation needed');
          }
        } else if (data.containsKey('post_url')) {
          String postUrl = data['post_url'];
          print('🔗 Opening URL: $postUrl');
          NavigationService().navigateToUrl(postUrl);
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Save token to SharedPreferences
  Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  /// Subscribe to topic (useful for broadcasting to all users)
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }
}
