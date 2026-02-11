import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovoride_driver/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';

/// Service to handle Pusher events in background with notifications
class BackgroundPusherService {
  static final BackgroundPusherService _instance = BackgroundPusherService._internal();
  factory BackgroundPusherService() => _instance;
  BackgroundPusherService._internal();

  /// Get singleton instance
  static BackgroundPusherService get instance => _instance;

  // Removed unused field _isolateName
  static const String _portName = 'pusher_background_port';

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  ReceivePort? _receivePort;
  bool _isInitialized = false;

  // Notification channel IDs
  static const String _newRideChannelId = 'new_ride_channel';
  static const String _bidAcceptChannelId = 'bid_accept_channel';
  static const String _paymentChannelId = 'payment_channel';
  static const String _criticalChannelId = 'critical_channel';
  static const String _generalChannelId = 'general_channel';

  /// Initialize background service
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    printX('🚀 Initializing BackgroundPusherService');

    // Initialize notifications
    await _initializeNotifications();

    // Initialize background isolate for Pusher (handles connection in background)
    await _initializeBackgroundIsolate();

    // Listen to Pusher events from PusherManager
    PusherManager().addListener(_handlePusherEvent);

    _isInitialized = true;
    printX('✅ BackgroundPusherService initialized');
  }

  /// Initialize notification channels and settings
  Future<void> _initializeNotifications() async {
    // Android notification channels
    const androidChannels = [
      AndroidNotificationChannel(
        _newRideChannelId,
        'New Ride Requests',
        description: 'Notifications for new ride requests',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
      AndroidNotificationChannel(
        _bidAcceptChannelId,
        'Bid Accepted',
        description: 'Notifications when your bid is accepted',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        _paymentChannelId,
        'Payment Notifications',
        description: 'Payment related notifications',
        importance: Importance.high,
        playSound: true,
      ),
      AndroidNotificationChannel(
        _criticalChannelId,
        'Critical Alerts',
        description: 'Important ride alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      ),
      AndroidNotificationChannel(
        _generalChannelId,
        'General Notifications',
        description: 'General ride notifications',
        importance: Importance.defaultImportance,
      ),
    ];

    // Create channels
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      for (final channel in androidChannels) {
        await androidPlugin.createNotificationChannel(channel);
      }

      // Request notification permissions for Android 13+
      await androidPlugin.requestNotificationsPermission();
    }

    // Initialize settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize background isolate for persistent Pusher connection
  Future<void> _initializeBackgroundIsolate() async {
    _receivePort = ReceivePort();

    // Register port for inter-isolate communication
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(
      _receivePort!.sendPort,
      _portName,
    );

    // Listen to messages from background isolate
    _receivePort!.listen((dynamic data) {
      if (data is Map<String, dynamic>) {
        _processBackgroundEvent(data);
      }
    });
  }

  /// Handle Pusher events (called from main isolate)
  void _handlePusherEvent(PusherEvent event) {
    try {
      final eventName = event.eventName.toLowerCase();

      // Ignore internal Pusher events (subscription_count, connection events, etc.)
      if (eventName.startsWith('pusher:') || eventName.startsWith('pusher_internal:')) {
        return;
      }

      printX('📩 BackgroundPusher: $eventName');

      // Parse event data
      if (event.data == null || event.data.isEmpty) {
        printX('⚠️ Event has no data, skipping');
        return;
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(event.data);
      } catch (e) {
        printE('Failed to parse event data: $e');
        return;
      }

      // Validate data structure
      if (data.isEmpty) {
        printX('⚠️ Event data is empty, skipping');
        return;
      }

      final model = PusherResponseModel.fromJson(data);

      // Determine app lifecycle state
      final appState = WidgetsBinding.instance.lifecycleState;
      final isBackground = appState == null || appState != AppLifecycleState.resumed;

      // Always show system notification for all events
      // This ensures the driver sees notifications whether app is foreground or background
      printX('📱 App state: $appState (isBackground: $isBackground) — showing notification');
      _showNotificationForEvent(eventName, model);

      // Handle critical events that need immediate attention (bring app to foreground)
      if (isBackground && _isCriticalEvent(eventName)) {
        _handleCriticalEvent(eventName, model);
      }
    } catch (e) {
      printE('Error handling Pusher event: $e');
    }
  }

  /// Process events from background isolate
  void _processBackgroundEvent(Map<String, dynamic> data) {
    final eventName = data['event'] as String?;
    final eventData = data['data'] as Map<String, dynamic>?;

    if (eventName != null && eventData != null) {
      final model = PusherResponseModel.fromJson(eventData);
      _showNotificationForEvent(eventName, model);
    }
  }

  /// Show notification based on event type
  Future<void> _showNotificationForEvent(
    String eventName,
    PusherResponseModel model,
  ) async {
    String title = '';
    String body = '';
    String channelId = _generalChannelId;
    NotificationDetails? details;
    String? payload;

    switch (eventName) {
      case 'new_ride':
        final ride = model.data?.ride;
        title = '🚗 New Ride Request!';
        if (ride != null) {
          body = 'From: ${ride.pickupLocation ?? "Pickup"}\n'
              'To: ${ride.destination ?? "Destination"}\n'
              'Amount: ${ride.amount ?? "0"}';
          payload = jsonEncode({
            'event': 'new_ride',
            'ride_id': ride.id,
          });
        } else {
          body = 'A new ride request is available. Tap to view details.';
        }
        channelId = _newRideChannelId;

        // High priority notification with actions
        details = NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'New Ride Requests',
            channelDescription: 'New ride request notifications',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.call,
            autoCancel: false,
            ongoing: true,
            timeoutAfter: 30000, // 30 seconds
            actions: [
              AndroidNotificationAction(
                'accept',
                'Accept',
                titleColor: Colors.green,
                showsUserInterface: true,
              ),
              AndroidNotificationAction(
                'reject',
                'Reject',
                titleColor: Colors.red,
                cancelNotification: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical,
          ),
        );
        break;

      case 'new_package_ride':
        final ride = model.data?.ride;
        title = '📦 New Package Ride!';
        if (ride != null) {
          body = 'Package delivery request\n'
              'From: ${ride.pickupLocation ?? "Pickup"}\n'
              'Amount: ${ride.amount ?? "0"}';
          payload = jsonEncode({
            'event': 'new_package_ride',
            'ride_id': ride.id,
          });
        } else {
          body = 'A new package delivery request is available.';
        }
        channelId = _newRideChannelId;
        break;

      case 'new_reservation_ride':
        final ride = model.data?.ride;
        title = '📅 Reservation Ride Ready!';
        if (ride != null) {
          body = 'Your scheduled reservation ride is ready\n'
              'From: ${ride.pickupLocation ?? "Pickup"}\n'
              'To: ${ride.destination ?? "Destination"}';
          payload = jsonEncode({
            'event': 'new_reservation_ride',
            'ride_id': ride.id,
          });
        } else {
          body = 'A reservation ride is ready for you.';
        }
        channelId = _newRideChannelId;
        break;

      case 'bid_accept':
        final ride = model.data?.ride;
        title = '✅ Bid Accepted!';
        if (ride != null) {
          body = 'Your bid has been accepted\n'
              'Ride: ${ride.uid ?? "Unknown"}\n'
              'Tap to view details';
          payload = jsonEncode({
            'event': 'bid_accept',
            'ride_id': ride.id,
          });
        } else {
          body = 'Your bid has been accepted! Tap to view ride details.';
        }
        channelId = _bidAcceptChannelId;
        break;

      case 'bid_reject':
        final ride = model.data?.ride;
        final bidAmount = model.data?.bidAmount ?? '0';
        title = '❌ Bid Rejected';
        if (ride != null) {
          body = 'Your bid of ${StringConverter.formatNumber(bidAmount)} was rejected\n'
              'Ride: ${ride.uid ?? "Unknown"}';
        } else {
          body = 'Your bid was rejected by the rider.';
        }
        channelId = _generalChannelId;
        break;

      case 'cash_payment_request':
        title = '💰 Payment Request';
        body = 'Rider is requesting cash payment confirmation';
        channelId = _paymentChannelId;
        payload = jsonEncode({
          'event': 'cash_payment_request',
          'ride_id': model.data?.ride?.id,
        });
        break;

      case 'online_payment_received':
        title = '✅ Payment Received';
        body = 'Online payment has been received successfully';
        channelId = _paymentChannelId;
        break;

      case 'ride_canceled':
        final canceledBy = model.data?.canceledBy ?? 'unknown';
        final reason = model.data?.cancelReason ?? 'No reason provided';
        title = '🚫 Ride Canceled';
        body = 'Ride canceled by $canceledBy\nReason: $reason';
        channelId = _criticalChannelId;
        break;

      case 'message_received':
        final message = model.data?.message;
        title = '💬 New Message';
        if (message != null) {
          body = message.message ?? 'You have a new message';
        } else {
          body = 'You have a new message from the rider.';
        }
        channelId = _generalChannelId;
        break;

      default:
        return; // Don't show notification for unknown events
    }

    // Show the notification
    if (title.isNotEmpty && body.isNotEmpty) {
      await _showNotification(
        title: title,
        body: body,
        channelId: channelId,
        details: details,
        payload: payload,
      );
    }
  }

  /// Show a notification
  Future<void> _showNotification({
    required String title,
    required String body,
    required String channelId,
    NotificationDetails? details,
    String? payload,
  }) async {
    details ??= NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Ride Notifications',
        channelDescription: 'Notifications for ride events',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Check if event is critical and needs immediate attention
  bool _isCriticalEvent(String eventName) {
    return [
      'new_ride',
      'new_package_ride',
      'new_reservation_ride',
      'bid_accept',
    ].contains(eventName);
  }

  /// Handle critical events with call-like UI
  Future<void> _handleCriticalEvent(
    String eventName,
    PusherResponseModel model,
  ) async {
    final appState = WidgetsBinding.instance.lifecycleState;

    // Only show call screen if app is in background/inactive
    if (appState != AppLifecycleState.resumed) {
      if (eventName == 'new_ride') {
        await _showIncomingRideScreen(model.data?.ride, isPackageRide: false, isReservationRide: false);
      } else if (eventName == 'new_package_ride') {
        await _showIncomingRideScreen(model.data?.ride, isPackageRide: true, isReservationRide: false);
      } else if (eventName == 'new_reservation_ride') {
        await _showIncomingRideScreen(model.data?.ride, isPackageRide: false, isReservationRide: true);
      } else if (eventName == 'bid_accept') {
        await _navigateToRideDetails(model.data?.ride?.id);
      }
    }
  }

  /// Show incoming ride screen (like WhatsApp call)
  Future<void> _showIncomingRideScreen(dynamic ride, {bool isPackageRide = false, bool isReservationRide = false}) async {
    if (ride == null) return;

    // Pass ride data with type flags
    Get.toNamed(
      RouteHelper.incomingRideScreen,
      arguments: {
        'ride': ride,
        'isPackageRide': isPackageRide,
        'isReservationRide': isReservationRide,
      },
    );
  }

  /// Navigate to ride details
  Future<void> _navigateToRideDetails(String? rideId) async {
    if (rideId == null) return;

    Get.toNamed(
      RouteHelper.rideDetailsScreen,
      arguments: rideId,
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final event = data['event'] as String?;
        final rideId = data['ride_id'] as String?;

        if (rideId != null) {
          // For new ride notifications, we need to fetch the ride data first
          // Since we only have the ride ID, navigate to ride details screen
          // which will fetch the complete ride data
          Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId);
        }
      } catch (e) {
        printE('Error handling notification tap: $e');
      }
    }
  }

  // iOS notification callback removed - deprecated in newer versions

  /// Dispose resources
  void dispose() {
    PusherManager().removeListener(_handlePusherEvent);
    _receivePort?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    _isInitialized = false;
  }
}

/// Background isolate entry point for persistent Pusher connection
@pragma('vm:entry-point')
void backgroundPusherIsolate() async {
  printX('🎯 Background Pusher Isolate started');

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Get shared preferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString(SharedPreferenceHelper.userIdKey) ?? '';

  if (userId.isEmpty) {
    printX('⚠️ No user ID, exiting background isolate');
    return;
  }

  // Initialize Pusher in background
  final pusher = PusherChannelsFlutter.getInstance();

  try {
    // Get Pusher config from storage
    final pusherConfigJson = prefs.getString(
      SharedPreferenceHelper.pusherConfigSettingKey,
    );

    if (pusherConfigJson != null) {
      final config = jsonDecode(pusherConfigJson);
      final apiKey = config['app_key'];
      final cluster = config['cluster'];

      if (apiKey != null && cluster != null) {
        // Initialize Pusher
        await pusher.init(
          apiKey: apiKey,
          cluster: cluster,
          onEvent: (event) {
            // Send event to main isolate
            final sendPort = IsolateNameServer.lookupPortByName(
              BackgroundPusherService._portName,
            );

            if (sendPort != null) {
              sendPort.send({
                'event': event.eventName,
                'data': jsonDecode(event.data),
              });
            }
          },
        );

        // Connect and subscribe
        await pusher.connect();
        await pusher.subscribe(
          channelName: 'private-rider-driver-$userId',
        );

        printX('✅ Background Pusher connected and subscribed');

        // Keep isolate alive
        while (true) {
          await Future.delayed(const Duration(seconds: 30));

          // Check if still connected
          if (pusher.connectionState.toLowerCase() != 'connected') {
            printX('⚠️ Pusher disconnected, reconnecting...');
            await pusher.connect();
          }
        }
      }
    }
  } catch (e) {
    printE('Error in background Pusher isolate: $e');
  }
}
