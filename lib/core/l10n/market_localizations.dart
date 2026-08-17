class MarketLocalization {
  static const Map<String, String> _kannadaMarkets = {
    'all': 'ಎಲ್ಲಾ ಮಾರುಕಟ್ಟೆಗಳು',
    'all markets': 'ಎಲ್ಲಾ ಮಾರುಕಟ್ಟೆಗಳು',
    'ramanagara': 'ರಾಮನಗರ',
    'sidlaghatta': 'ಶಿಡ್ಲಘಟ್ಟ',
    'shidlaghatta': 'ಶಿಡ್ಲಘಟ್ಟ',
    'kolar': 'ಕೋಲಾರ',
    'vijayapura': 'ವಿಜಯಪುರ',
    'chintamani': 'ಚಿಂತಾಮಣಿ',
    'kanakapura': 'ಕನಕಪುರ',
    'kollegala': 'ಕೊಳ್ಳೇಗಾಲ',
    'haveri': 'ಹಾವೇರಿ',
    'gubbi': 'ಗುಬ್ಬಿ',
    'santhemarahalli': 'ಸಂತೆಮರಹಳ್ಳಿ',
    'doddaballapura': 'ದೊಡ್ಡಬಳ್ಳಾಪುರ',
    'kunigal': 'ಕುಣಿಗಲ್',
    'madhugiri': 'ಮಧುಗಿರಿ',
    'mysuru': 'ಮೈಸೂರು',
    'mysore': 'ಮೈಸೂರು',
    'mandya': 'ಮಂಡ್ಯ',
    'chikkaballapura': 'ಚಿಕ್ಕಬಳ್ಳಾಪುರ',
    'tumakuru': 'ತುಮಕೂರು',
    'tumkur': 'ತುಮಕೂರು',
  };

  /// Returns Kannada translation if isKn is true, otherwise English
  static String getLocalizedMarket(String marketName, bool isKn) {
    if (!isKn) {
      if (marketName.toLowerCase() == 'all') return 'All Markets';
      return marketName;
    }
    final key = marketName.trim().toLowerCase();
    return _kannadaMarkets[key] ?? marketName;
  }

  /// Returns localized breed name
  static String getLocalizedBreed(String breedCode, bool isKn) {
    if (!isKn) {
      if (breedCode == 'CB') return 'Cross Breed (CB)';
      if (breedCode == 'BV') return 'Bivoltine (BV)';
      if (breedCode == 'CB_GOLD') return 'CB Gold';
      if (breedCode == 'All') return 'All Breeds';
      return breedCode;
    }
    if (breedCode == 'CB') return 'ಮಿಶ್ರತಳಿ (ಸಿ.ಬಿ)';
    if (breedCode == 'BV') return 'ಬೈವೋಲ್ಟಿನ್ (ಬಿ.ವಿ)';
    if (breedCode == 'CB_GOLD') return 'ಸಿ.ಬಿ ಗೋಲ್ಡ್';
    if (breedCode == 'All') return 'ಎಲ್ಲ ತಳಿಗಳು';
    return breedCode;
  }
}
