class Environment {
  // ATTENTION Please update your desired data.
  static const String appName = 'MeroRides Driver';
  static const String version = '1.0.0';

  // Ride and Bids
  static const int bidAcceptSecond = 30; //Bid ACCEPT second
  static const int driverLocationUpdateAfterNmetersOrMovements = 50; //Driver location update after n meters or movements

  //Language
  // Default display name for the app's language (used in UI language selectors)
  static String defaultLanguageName = "English";

  // Default language code (ISO 639-1) used by the app at startup
  static String defaultLanguageCode = "en";

  // Default country code (ISO 3166-1 alpha-2) used for locale-specific formatting
  static const String defaultCountryCode = 'US';

  //MAP CONFIG
  static const bool addressPickerFromGoogleMapApi = false; //If true, use Google Map API for formate address picker from lat , long, else use free service reverse geocode
  static String mapKey = "AIzaSyDyh1Hq8VEAWMT9Y_KGDhNmYsDFwaU6pSo"; // Default fallback, updated from API
  static const double mapDefaultZoom = 20;
  static const String devToken = "\$2y\$12\$mEVBW3QASB5HMBv8igls3ejh6zw2A0Xb480HWAmYq6BY9xEifyBjG"; //Do not change this token
}
