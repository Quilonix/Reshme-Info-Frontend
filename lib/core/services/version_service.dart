import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class VersionService {
  // Current App Date-Based Version (YYYY.M.D)
  static const String currentAppVersion = '2026.8.17';

  /// Compare two date-based version strings like '2026.8.17' and '2026.8.10'
  /// Returns:
  ///   -1 if v1 < v2 (v1 is older)
  ///    0 if v1 == v2 (equal)
  ///    1 if v1 > v2 (v1 is newer)
  static int compareVersions(String v1, String v2) {
    try {
      final p1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final p2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final val1 = i < p1.length ? p1[i] : 0;
        final val2 = i < p2.length ? p2[i] : 0;
        if (val1 < val2) return -1;
        if (val1 > val2) return 1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Checks Supabase for the latest published app version and triggers update dialog if needed
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final response = await SupabaseConfig.client
          .from('app_settings')
          .select('value')
          .eq('key', 'app_version_config')
          .maybeSingle();

      if (response == null || response['value'] == null) return;

      final config = response['value'] as Map<String, dynamic>;
      final latestVersion = config['latest_version'] as String? ?? currentAppVersion;
      final minSupported = config['min_supported_version'] as String? ?? currentAppVersion;
      final isForceUpdate = config['force_update'] as bool? ?? false;
      final updateUrl = config['update_url'] as String? ?? 'https://play.google.com/store/apps/details?id=com.master.reshmeinfo';
      final notes = config['release_notes'] as String? ?? 'A new version of Reshme Info is available with latest market improvements.';
      final notesKn = config['release_notes_kn'] as String? ?? 'ಹೊಸ ವೈಶಿಷ್ಟ್ಯಗಳು ಮತ್ತು ಮಾರುಕಟ್ಟೆ ಮಾಹಿತಿಯೊಂದಿಗೆ ರೇಷ್ಮೆ ಮಾಹಿತಿಯ ಹೊಸ ಆವೃತ್ತಿ ಲಭ್ಯವಿದೆ.';

      // Check if current version is older than latest
      final isOlderThanLatest = compareVersions(currentAppVersion, latestVersion) < 0;
      final isOlderThanMin = compareVersions(currentAppVersion, minSupported) < 0;
      final mustForceUpdate = isForceUpdate || isOlderThanMin;

      if (isOlderThanLatest && context.mounted) {
        _showUpdateDialog(
          context: context,
          latestVersion: latestVersion,
          isForced: mustForceUpdate,
          updateUrl: updateUrl,
          releaseNotes: notes,
          releaseNotesKn: notesKn,
        );
      }
    } catch (e) {
      debugPrint('Version check notice: $e');
    }
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required String latestVersion,
    required bool isForced,
    required String updateUrl,
    required String releaseNotes,
    required String releaseNotesKn,
  }) {
    final isKn = Localizations.localeOf(context).languageCode == 'kn';

    showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (BuildContext ctx) {
        return PopScope(
          canPop: !isForced,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.system_update, color: Color(0xFF1E40AF)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isKn ? 'ಹೊಸ ಆವೃತ್ತಿ ಲಭ್ಯವಿದೆ!' : 'Update Available!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKn
                      ? 'ಆವೃತ್ತಿ $latestVersion ಈಗ ಲಭ್ಯವಿದೆ (ನಿಮ್ಮ ಆವೃತ್ತಿ: $currentAppVersion).'
                      : 'Version $latestVersion is now available (Current: $currentAppVersion).',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  isKn ? releaseNotesKn : releaseNotes,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                ),
                if (isForced) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isKn
                                ? 'ಅಪ್ಲಿಕೇಶನ್ ಮುಂದುವರಿಸಲು ಅಪ್ಡೇಟ್ ಮಾಡುವುದು ಕಡ್ಡಾಯವಾಗಿದೆ.'
                                : 'This update is required to continue using the application.',
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isForced)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    isKn ? 'ನಂತರ' : 'Later',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E40AF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final uri = Uri.parse(updateUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  isKn ? 'ಈಗಲೇ ಅಪ್ಡೇಟ್ ಮಾಡಿ' : 'Update Now',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
