import 'package:flutter/material.dart';

/// Global navigation service for handling deep links from notifications
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a specific route
  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate and remove all previous routes
  Future<dynamic>? navigateToAndRemoveUntil(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Go back
  void goBack() {
    return navigatorKey.currentState?.pop();
  }

  /// Get current context
  BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to post detail screen
  Future<dynamic>? navigateToPost(String postId) {
    return navigateTo('/post', arguments: {'post_id': postId});
  }

  /// Navigate to specific URL (for web links)
  Future<dynamic>? navigateToUrl(String url) {
    return navigateTo('/webview', arguments: {'url': url});
  }
}

