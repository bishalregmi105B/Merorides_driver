import Flutter
import UIKit
import GoogleMaps
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  // Expose the Flutter engine so SceneDelegate can create a FlutterViewController
  lazy var flutterEngine = FlutterEngine(name: "io.flutter", project: nil)

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Start the Flutter engine early
    flutterEngine.run()

    GMSServices.provideAPIKey("AIzaSyDyh1Hq8VEAWMT9Y_KGDhNmYsDFwaU6pSo")
    GeneratedPluginRegistrant.register(with: flutterEngine)

    // Register for push notifications
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Scene configuration for iOS 26+ UISceneDelegate lifecycle
  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  override func application(
    _ application: UIApplication,
    didDiscardSceneSessions sceneSessions: Set<UISceneSession>
  ) {}

  // Explicitly forward APNs token to Firebase Messaging (iOS 26 compatibility)
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("APNs token received: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Log APNs registration failures for debugging
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

