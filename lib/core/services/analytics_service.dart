import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs events directly to Google Analytics 4 (Firebase Analytics)
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Firebase Analytics parameters must be String, num, or null
      final Map<String, Object>? sanitized = parameters?.map(
        (key, value) => MapEntry(key, value is Object ? value : value.toString()),
      );
      await _analytics.logEvent(
        name: name,
        parameters: sanitized,
      );
    } catch (e) {
      debugPrint('Google Analytics event notice ($name): $e');
    }
  }

  // Track screen transitions in Google Analytics
  static Future<void> logScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (_) {}

    await logEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName},
    );
  }

  // Track market price filters
  static Future<void> logSelectMarket(String marketName) async {
    await logEvent(
      name: 'select_market',
      parameters: {'market_name': marketName},
    );
  }

  // Track breed selection
  static Future<void> logSelectBreed(String breed) async {
    await logEvent(
      name: 'select_breed',
      parameters: {'breed': breed},
    );
  }

  // Track language changes
  static Future<void> logLanguageChange(String languageCode) async {
    try {
      await _analytics.setUserProperty(name: 'preferred_language', value: languageCode);
    } catch (_) {}

    await logEvent(
      name: 'change_language',
      parameters: {'language': languageCode},
    );
  }

  // Track knowledge guide engagement
  static Future<void> logViewGuide(String guideTitle, String guideType) async {
    await logEvent(
      name: 'view_guide',
      parameters: {
        'item_name': guideTitle,
        'content_type': guideType,
      },
    );
  }
}
