import 'dart:convert';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/utils/app_status.dart';
import 'package:ovoride_driver/data/model/country_model/country_model.dart';
import 'package:ovoride_driver/data/model/general_setting/general_setting_response_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences sharedPreferences;

  LocalStorageService({required this.sharedPreferences});

  // Token Management
  String getToken() {
    return sharedPreferences.getString(SharedPreferenceHelper.accessTokenKey) ?? '';
  }

  String getTokenType() {
    return sharedPreferences.getString(
          SharedPreferenceHelper.accessTokenType,
        ) ??
        'Bearer';
  }

  void saveToken(String token, String type) {
    sharedPreferences.setString(SharedPreferenceHelper.accessTokenKey, token);
    sharedPreferences.setString(SharedPreferenceHelper.accessTokenType, type);
  }

  void removeToken() {
    sharedPreferences.remove(SharedPreferenceHelper.accessTokenKey);
  }

  // Remember Me Functionality
  void setRememberMe(bool value) {
    sharedPreferences.setBool(SharedPreferenceHelper.rememberMeKey, value);
  }

  bool getRememberMe() {
    return sharedPreferences.getBool(SharedPreferenceHelper.rememberMeKey) ?? false;
  }

  // General Settings
  void storeGeneralSetting(GeneralSettingResponseModel model) {
    String json = jsonEncode(model.toJson());
    sharedPreferences.setString(SharedPreferenceHelper.generalSettingKey, json);
  }

  GeneralSettingResponseModel getGeneralSettings() {
    String pre = sharedPreferences.getString(SharedPreferenceHelper.generalSettingKey) ?? '{}';
    try {
      return GeneralSettingResponseModel.fromJson(jsonDecode(pre));
    } catch (e) {
      return GeneralSettingResponseModel();
    }
  }

  // Pusher Configuration
  void storePushSetting(PusherConfig pusherConfig) {
    String json = jsonEncode(pusherConfig.toJson());
    sharedPreferences.setString(
      SharedPreferenceHelper.pusherConfigSettingKey,
      json,
    );
  }

  PusherConfig getPushConfig() {
    String pre = sharedPreferences.getString(
          SharedPreferenceHelper.pusherConfigSettingKey,
        ) ??
        '{}';
    try {
      return PusherConfig.fromJson(jsonDecode(pre));
    } catch (e) {
      return PusherConfig();
    }
  }

  // Notification Audio
  void storeNotificationAudio(String notificationAudioPath) {
    sharedPreferences.setString(
      SharedPreferenceHelper.notificationAudioKey,
      notificationAudioPath,
    );
  }

  String getNotificationAudio() {
    return sharedPreferences.getString(
          SharedPreferenceHelper.notificationAudioKey,
        ) ??
        '';
  }

  void storeNotificationAudioEnable(bool isEnable) {
    sharedPreferences.setString(
      SharedPreferenceHelper.notificationAudioEnableKey,
      isEnable ? '1' : '0',
    );
  }

  bool isNotificationAudioEnable() {
    String pre = sharedPreferences.getString(
          SharedPreferenceHelper.notificationAudioEnableKey,
        ) ??
        '1';
    return pre == '1';
  }

  // User Information
  String getUserEmail() {
    return sharedPreferences.getString(SharedPreferenceHelper.userEmailKey) ?? '';
  }

  String getUserName() {
    return sharedPreferences.getString(SharedPreferenceHelper.userNameKey) ?? '';
  }

  String getUserID() {
    return sharedPreferences.getString(SharedPreferenceHelper.userIdKey) ?? '';
  }

  String getUserPhone() {
    String phone = sharedPreferences.getString(
          SharedPreferenceHelper.userPhoneNumberKey,
        ) ??
        '';
    return phone;
  }

  // Utility Methods

  bool isGoogleLoginEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.googleLogin == '1';
  }

  bool isAppleLoginEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.appleLogin == '1';
  }

  String getSocialCredentialsRedirectUrl() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.socialLoginRedirect ?? "";
  }

  String getCurrency({bool isSymbol = false}) {
    GeneralSettingResponseModel model = getGeneralSettings();
    return isSymbol ? model.data?.generalSetting?.curSym ?? '' : model.data?.generalSetting?.curText ?? '';
  }

  List<Countries> getOperatingCountries() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.operatingCountry ?? [];
  }

  bool getPasswordStrengthStatus() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.securePassword == '1';
  }

  bool isMultiLanguageEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.multiLanguage == '1';
  }

  String getTemplateName() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.activeTemplate ?? '';
  }

  bool isAgreePolicyEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.agree == '1';
  }

  void storePopupHash(String hash) {
    sharedPreferences.setString(SharedPreferenceHelper.popupCacheKey, hash);
  }

  String getPopupHash() {
    return sharedPreferences.getString(SharedPreferenceHelper.popupCacheKey) ?? '';
  }

  String getDistanceUnit() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.distanceUnit ?? AppStatus.DISTANCE_UNIT_KM;
  }

  bool isDonationEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    return model.data?.generalSetting?.donation == '1';
  }

  bool isDepositEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    String? depositValue = model.data?.generalSetting?.deposit;
    
    // DEBUG: Log the deposit value
    printX('🔍 DEPOSIT CHECK: depositValue = "$depositValue"');
    printX('🔍 DEPOSIT CHECK: donation = "${model.data?.generalSetting?.donation}"');
    
    // Explicitly check for '1' to enable deposit feature
    // If null or any other value, default to disabled for safety
    return depositValue == '1';
  }

  bool isPaymentSystemEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    String? paymentSystemValue = model.data?.generalSetting?.paymentSystem;
    
    // DEBUG: Log the payment system value
    printX('🔍 PAYMENT SYSTEM CHECK: paymentSystemValue = "$paymentSystemValue"');
    
    // Explicitly check for '1' to enable payment system
    // If null or any other value, default to enabled for backward compatibility
    // This ensures existing apps work even before the update
    return paymentSystemValue != '0';
  }

  /// Check if prices/fares should be displayed
  /// Controlled by admin setting - can hide prices completely if needed
  /// Different from payment system which controls actual transactions
  bool canShowPrices() {
    GeneralSettingResponseModel model = getGeneralSettings();
    String? showPricesValue = model.data?.generalSetting?.showPrices;
    
    // If null or any other value except '0', default to enabled
    // This ensures existing apps work even before the update
    return showPricesValue != '0';
  }

  bool getUserOnlineStatus() {
    return sharedPreferences.getBool(
          SharedPreferenceHelper.userOnlineStatusKey,
        ) ??
        false;
  }

  void setOnlineStatus(bool status) {
    sharedPreferences.setBool(
      SharedPreferenceHelper.userOnlineStatusKey,
      status,
    );
  }

  bool isLoggedIn() {
    printD(getToken());
    return getToken() != "";
  }

  bool isPackageEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    String? packageValue = model.data?.generalSetting?.package;
    
    // If null or any other value except '0', default to enabled for backward compatibility
    // This ensures existing apps work even before the update
    return packageValue != '0';
  }
  
  bool isReservationEnabled() {
    GeneralSettingResponseModel model = getGeneralSettings();
    String? reservationValue = model.data?.generalSetting?.reservation;
    
    // If null or any other value except '0', default to enabled for backward compatibility
    // This ensures existing apps work even before the update
    return reservationValue != '0';
  }
}
