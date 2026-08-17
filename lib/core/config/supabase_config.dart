import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://slabfaumgcktgeuzvkfj.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNsYWJmYXVtZ2NrdGdldXp2a2ZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY5NTQ3MTksImV4cCI6MjEwMjUzMDcxOX0.74KP4zZ8tZQ_XSUYdcr5N9xRMSnV3mjejULAC9J5B80',
  );

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint('Supabase init error: $e');
    }
  }
}
