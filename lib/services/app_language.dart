import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  amharic,
  tigrinya,
  oromo,
}

class LanguageService {
  static const String _languageKey = 'app_language';

  static final ValueNotifier<AppLanguage> current =
      ValueNotifier(AppLanguage.english);

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_languageKey);

    if (saved == null) return;

    switch (saved) {
      case 'amharic':
        current.value = AppLanguage.amharic;
        break;
      case 'tigrinya':
        current.value = AppLanguage.tigrinya;
        break;
      case 'oromo':
        current.value = AppLanguage.oromo;
        break;
      case 'english':
      default:
        current.value = AppLanguage.english;
        break;
    }
  }

  static Future<void> setLanguage(AppLanguage language) async {
    current.value = language;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _languageKey,
      language.name,
    );
  }

  static String get languageName {
    return name(current.value);
  }

  static String name(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.amharic:
        return 'አማርኛ';
      case AppLanguage.tigrinya:
        return 'ትግርኛ';
      case AppLanguage.oromo:
        return 'Afaan Oromoo';
    }
  }

  static String text(String key) {
    final language = current.value;

    final translations = <String, Map<AppLanguage, String>>{
      'appTitle': {
        AppLanguage.english: 'Item Shop',
        AppLanguage.amharic: 'የItem መደብር',
        AppLanguage.tigrinya: 'መደብር Item',
        AppLanguage.oromo: 'Mana Item',
      },
      'offlineCustomers': {
        AppLanguage.english: 'Offline Customers',
        AppLanguage.amharic: 'ኦፍላይን ደንበኞች',
        AppLanguage.tigrinya: 'ኦፍላይን ዓማዊል',
        AppLanguage.oromo: 'Maamiltoota Offline',
      },
      'waitingOrders': {
        AppLanguage.english: 'Waiting Orders',
        AppLanguage.amharic: 'የሚጠባበቁ ትዕዛዞች',
        AppLanguage.tigrinya: 'ዝጽበዩ ትእዛዛት',
        AppLanguage.oromo: 'Ajajoota Eegamaa Jiran',
      },
      'searchPdfs': {
        AppLanguage.english: 'Search Items...',
        AppLanguage.amharic: 'Item ይፈልጉ...',
        AppLanguage.tigrinya: 'Item ድለዩ...',
        AppLanguage.oromo: 'Item barbaadi...',
      },
      'noPdfs': {
        AppLanguage.english: 'No Items Found',
        AppLanguage.amharic: 'ምንም Item አልተገኘም',
        AppLanguage.tigrinya: 'ምንም Item ኣይተረኽበን',
        AppLanguage.oromo: 'Item hin argamne',
      },
      'noMatchingPdfs': {
        AppLanguage.english: 'No Matching Items',
        AppLanguage.amharic: 'የሚመሳሰል Item አልተገኘም',
        AppLanguage.tigrinya: 'ዝመሳሰል Item ኣይተረኽበን',
        AppLanguage.oromo: 'Item walsimu hin argamne',
      },
    };

    return translations[key]?[language] ??
        translations[key]?[AppLanguage.english] ??
        key;
  }
}
