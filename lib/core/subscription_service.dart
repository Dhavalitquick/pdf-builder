import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._init();
  SubscriptionService._init();

  bool _isPremium = false;
  bool get isPremium => _isPremium;

  Future<void> init() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      
      PurchasesConfiguration configuration;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Replace with your RevenueCat iOS App Store API Key (starts with appl_)
        configuration = PurchasesConfiguration("appl_PHvMDpCpoCLeUjQPxOxgWMrXEaD");
      } else {
        // Replace with your RevenueCat Android Google Play API Key (starts with goog_)
        configuration = PurchasesConfiguration("goog_ZBHBdfBRUcGFWkiLpAGMIdwcQcb");
      }

      await Purchases.configure(configuration);
      await checkSubscriptionStatus();
    } catch (e) {
      debugPrint("RevenueCat init error: $e");
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all["premium"]?.isActive == true) {
        _isPremium = true;
      } else {
        _isPremium = false;
      }
    } catch (e) {
      debugPrint("Check subscription error: $e");
    }
    return _isPremium;
  }

  // --- Daily Quota Management ---
  // 3 free PDF conversions per day, 1 free OCR per day

  static const String _keyConversionDate = 'quota_conversion_date';
  static const String _keyConversionCount = 'quota_conversion_count';
  static const String _keyOcrDate = 'quota_ocr_date';
  static const String _keyOcrCount = 'quota_ocr_count';

  Future<bool> checkAndConsumeConversionQuota() async {
    if (_isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyConversionDate) ?? '';
    int count = prefs.getInt(_keyConversionCount) ?? 0;

    if (savedDate != today) {
      count = 1; // first try of the day
      await prefs.setString(_keyConversionDate, today);
      await prefs.setInt(_keyConversionCount, count);
      return true;
    }

    if (count >= 3) {
      return false; // Limit reached (3 per day)
    }

    await prefs.setInt(_keyConversionCount, count + 1);
    return true;
  }

  Future<int> getRemainingConversions() async {
    if (_isPremium) return 999;
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyConversionDate) ?? '';
    int count = prefs.getInt(_keyConversionCount) ?? 0;
    if (savedDate != today) return 3;
    return (3 - count).clamp(0, 3);
  }

  Future<bool> checkAndConsumeOcrQuota() async {
    if (_isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyOcrDate) ?? '';
    int count = prefs.getInt(_keyOcrCount) ?? 0;

    if (savedDate != today) {
      count = 1;
      await prefs.setString(_keyOcrDate, today);
      await prefs.setInt(_keyOcrCount, count);
      return true;
    }

    if (count >= 1) {
      return false; // Limit reached (1 per day)
    }

    await prefs.setInt(_keyOcrCount, count + 1);
    return true;
  }

  String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }
}
