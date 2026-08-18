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

  static Future<void> logMarketFilter(String marketName) async {
    await logSelectMarket(marketName);
  }

  // Track breed selection
  static Future<void> logSelectBreed(String breed) async {
    await logEvent(
      name: 'select_breed',
      parameters: {'breed': breed},
    );
  }

  static Future<void> logBreedFilter(String breed) async {
    await logSelectBreed(breed);
  }

  // Track WhatsApp shares
  static Future<void> logWhatsAppShare(String market, String breed) async {
    await logEvent(
      name: 'share_whatsapp',
      parameters: {
        'market_name': market,
        'breed': breed,
      },
    );
  }

  // Track guide views
  static Future<void> logViewGuide(String title, String type) async {
    await logEvent(
      name: 'view_guide',
      parameters: {
        'title': title,
        'type': type,
      },
    );
  }

  // Track language changes
  static Future<void> logLanguageChange(String languageCode) async {
    try {
      await _analytics.setUserProperty(name: 'preferred_language', value: languageCode);
    } catch (_) {}

    await logEvent(
      name: 'change_language',
      parameters: {'new_language': languageCode},
    );
  }
}
