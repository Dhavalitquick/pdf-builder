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
      // Replace with RevenueCat API key when configuring production builds
      PurchasesConfiguration configuration = PurchasesConfiguration("goog_api_key_placeholder");
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
      count = 0;
      await prefs.setString(_keyConversionDate, today);
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
      count = 0;
      await prefs.setString(_keyOcrDate, today);
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
