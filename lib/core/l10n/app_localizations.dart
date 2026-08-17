import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'app_title': 'Reshme Info',
      'home': 'Home',
      'market': 'Market Prices',
      'stats': 'Statistics',
      'info': 'Knowledge Hub',
      'about': 'About',
      'notifications': 'Alerts',
      'filter_market': 'Select Market',
      'all_markets': 'All Markets',
      'breed_cb': 'Cross Breed (CB)',
      'breed_bv': 'Bivoltine (BV)',
      'breed_cb_gold': 'CB Gold',
      'min_price': 'Min Price',
      'max_price': 'Max Price',
      'avg_price': 'Avg Price',
      'quality': 'Quality',
      'lots': 'Lots',
      'date': 'Date',
      'today_rates': 'Today\'s Market Rates',
      'featured_guide': 'Featured Farming Guides',
      'no_data': 'No market rates available for today yet.',
      'change_language': 'Change Language',
    },
    'kn': {
      'app_title': 'ರೇಷ್ಮೆ ಮಾಹಿತಿ',
      'home': 'ಮುಖಪುಟ',
      'market': 'ಮಾರುಕಟ್ಟೆ ಧಾರಣೆ',
      'stats': 'ಅಂಕಿ ಅಂಶಗಳು',
      'info': 'ಮಾಹಿತಿ ಕೋಶ',
      'about': 'ನಮ್ಮ ಬಗ್ಗೆ',
      'notifications': 'ಸೂಚನೆಗಳು',
      'filter_market': 'ಮಾರುಕಟ್ಟೆ ಆಯ್ಕೆ',
      'all_markets': 'ಎಲ್ಲಾ ಮಾರುಕಟ್ಟೆಗಳು',
      'breed_cb': 'ಮಿಶ್ರತಳಿ (ಸಿ.ಬಿ)',
      'breed_bv': 'ಬೈವೋಲ್ಟಿನ್ (ಬಿ.ವಿ)',
      'breed_cb_gold': 'ಸಿ.ಬಿ ಗೋಲ್ಡ್',
      'min_price': 'ಕನಿಷ್ಠ ಧಾರಣೆ',
      'max_price': 'ಗರಿಷ್ಠ ಧಾರಣೆ',
      'avg_price': 'ಸರಾಸರಿ ಧಾರಣೆ',
      'quality': 'ಗುಣಮಟ್ಟ',
      'lots': 'ಲಾಟ್‌ಗಳು',
      'date': 'ದಿನಾಂಕ',
      'today_rates': 'ಇಂದಿನ ರೇಷ್ಮೆ ಗೂಡಿನ ಧಾರಣೆ',
      'featured_guide': 'ಪ್ರಮುಖ ಕೃಷಿ ಮಾಹಿತಿ ಮತ್ತು ವಿಡಿಯೋಗಳು',
      'no_data': 'ಇಂದಿನ ಮಾರುಕಟ್ಟೆ ಧಾರಣೆಗಳು ಇನ್ನೂ ಲಭ್ಯವಿಲ್ಲ.',
      'change_language': 'ಭಾಷೆ ಬದಲಾಯಿಸಿ',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'kn'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
