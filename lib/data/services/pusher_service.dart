import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/utils/method.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';
import 'package:ovoride_driver/data/model/global/response_model/response_model.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherManager with WidgetsBindingObserver {
  static final PusherManager _instance = PusherManager._internal();
  factory PusherManager() => _instance;
  PusherManager._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  final ApiClient apiClient = ApiClient(sharedPreferences: Get.find());
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  final List<void Function(PusherEvent)> _listeners = [];

  bool _isConnecting = false;
  String _channelName = "";

  /// Track when app went to background to detect stale connections
  DateTime? _backgroundedAt;
  Timer? _keepAliveTimer;
  static const int _backgroundThresholdSeconds = 30;

  Future<void> init(String channelName) async {
    if (_isConnecting) return;
    _isConnecting = true;
    _channelName = channelName;

    final apiKey = apiClient.getPushConfig().appKey ?? "";
    final cluster = apiClient.getPushConfig().cluster ?? "";

    // iOS-specific debug logging
    final platform = Platform.isIOS ? "iOS" : (Platform.isAndroid ? "Android" : "Unknown");
    printX("📱 [DRIVER] Platform: $platform");
    printX("🔑 [DRIVER] Pusher Init: apiKey=${apiKey.isNotEmpty ? '${apiKey.substring(0, 4)}...' : 'EMPTY'}, cluster=$cluster, channel=$channelName");

    if (apiKey.isEmpty || cluster.isEmpty) {
      printE("❌ [DRIVER] PUSHER CONFIG MISSING! apiKey: ${apiKey.isEmpty ? 'EMPTY' : 'OK'}, cluster: ${cluster.isEmpty ? 'EMPTY' : 'OK'}");
      _isConnecting = false;
      return;
    }

    await _disconnect();

    await pusher.init(
      apiKey: apiKey,
      cluster: cluster,
      onConnectionStateChange: _onConnectionStateChange,
      onEvent: _dispatchEvent,
      onError: (msg, code, e) {
        printE("❌ [DRIVER] Pusher Error [$platform]: $msg (code: $code)");
        if (Platform.isIOS) {
          printE("🍎 iOS Error Details: $e");
        }
      },
      onSubscriptionError: (msg, e) {
        printE("⚠️ [DRIVER] Sub Error [$platform]: $msg");
        if (Platform.isIOS) {
          printE("🍎 iOS Subscription Error: $e");
        }
      },
      onSubscriptionSucceeded: (channel, data) => printX("✅ [DRIVER] Subscribed [$platform]: $channel"),
      onAuthorizer: onAuthorizer,
      onDecryptionFailure: (_, __) {},
      onMemberAdded: (_, __) {},
      onMemberRemoved: (_, __) {},
    );

    await _connect(channelName);
    _isConnecting = false;
    _startKeepAlive();
  }

  // ─── App lifecycle handling ────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final platform = Platform.isIOS ? "iOS" : "Android";
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _backgroundedAt = DateTime.now();
      _stopKeepAlive();
      printX("⏸️ [DRIVER][$platform] App backgrounded at $_backgroundedAt");
    } else if (state == AppLifecycleState.resumed) {
      final wasBackgroundedFor = _backgroundedAt != null ? DateTime.now().difference(_backgroundedAt!).inSeconds : 0;
      printX("▶️ [DRIVER][$platform] App resumed after ${wasBackgroundedFor}s");
      _backgroundedAt = null;

      // If backgrounded longer than threshold, force full reconnect
      // because the WebSocket is likely dead even if Pusher reports 'connected'
      if (wasBackgroundedFor > _backgroundThresholdSeconds) {
        printX("🔄 [DRIVER][$platform] Stale connection likely — forcing full reconnect");
        forceReconnect();
      } else {
        ensureConnection();
      }
      _startKeepAlive();
    }
  }

  /// Periodic keep-alive: checks connection every 45s and reconnects if dead
  void _startKeepAlive() {
    _stopKeepAlive();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!isConnected() && !_isConnecting && _channelName.isNotEmpty) {
        printX("💓 [DRIVER] Keep-alive detected dead connection — reconnecting");
        forceReconnect();
      }
    });
  }

  void _stopKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  /// Force disconnect + full reconnect. Call when connection is suspected stale.
  Future<void> forceReconnect() async {
    if (_isConnecting || _channelName.isEmpty) return;
    printX("🔌 [DRIVER] Force reconnect: disconnecting then re-initializing");
    await _disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    await init(_channelName);
  }

  // Continuous connection management
  Future<void> ensureConnection() async {
    if (_isConnecting) return;
    if (_channelName.isEmpty) return;

    if (isConnected()) {
      await _subscribe(_channelName);
      return;
    }

    _connect(_channelName);
  }

  Future<void> _connect(String channelName) async {
    final platform = Platform.isIOS ? "iOS" : "Android";

    if (isConnected()) {
      await _subscribe(channelName);
      return;
    }

    _isConnecting = true;
    int retryCount = 0;
    const int maxBackoffSeconds = 64; // Max wait time between retries

    while (!isConnected() && _channelName.isNotEmpty) {
      try {
        printX("🔌 [DRIVER][$platform] Connecting... (Attempt ${retryCount + 1})");
        await pusher.connect();
        await Future.delayed(const Duration(seconds: 3));

        if (isConnected()) {
          printX("✅ [DRIVER][$platform] Connected!");
          await _subscribe(channelName);
          _isConnecting = false;
          return;
        }
      } catch (e) {
        printE("⚠️ [DRIVER][$platform] Connect failed: $e");
        if (Platform.isIOS) {
          printE("🍎 iOS Connection Error - Check: Network, SSL, WebSocket support");
        }
      }

      // Exponential backoff logic
      int delaySeconds = (1 << retryCount).clamp(1, maxBackoffSeconds);
      printX("⏳ [DRIVER][$platform] Retrying in $delaySeconds seconds...");
      await Future.delayed(Duration(seconds: delaySeconds));

      if (retryCount < 10) {
        // Limit exponential growth but retry indefinitely
        retryCount++;
      }
    }
    _isConnecting = false;
  }

  Future<void> _subscribe(String channelName) async {
    final platform = Platform.isIOS ? "iOS" : "Android";

    // Always try to subscribe — if channel already exists, unsubscribe first
    // to ensure a fresh subscription (fixes stale subscriptions after reconnect)
    try {
      if (pusher.getChannel(channelName) != null) {
        try {
          await pusher.unsubscribe(channelName: channelName);
        } catch (_) {}
      }
      printX("📡 [DRIVER][$platform] Subscribing to: $channelName");
      await pusher.subscribe(channelName: channelName);
    } catch (e) {
      printE("⚠️ [DRIVER][$platform] Subscribe error: $e");
    }
  }

  Future<void> _disconnect() async {
    try {
      if (pusher.connectionState.toLowerCase() != 'disconnected') {
        await pusher.disconnect();
      }
    } catch (_) {}
  }

  void _onConnectionStateChange(String current, String previous) {
    final platform = Platform.isIOS ? "iOS" : "Android";
    printX("🔁 [DRIVER][$platform] State: $previous → $current");

    // iOS-specific: Log additional connection states for debugging
    if (Platform.isIOS && current.toLowerCase() == 'disconnected') {
      printE("🍎 iOS Disconnected - Common causes: App backgrounded, Network change, Server timeout");
    }

    if (current.toLowerCase() == 'disconnected' && previous.toLowerCase() == 'connected' && !_isConnecting) {
      printX("⏳ [DRIVER][$platform] Disconnected unexpectedly — will force reconnect in 3s...");
      Future.delayed(const Duration(seconds: 3), () {
        if (!isConnected() && !_isConnecting) {
          printX("🔄 [DRIVER][$platform] Force reconnecting after unexpected disconnect...");
          forceReconnect();
        }
      });
    }
  }

  void _dispatchEvent(PusherEvent event) {
    final platform = Platform.isIOS ? "iOS" : "Android";
    printX("📨 [DRIVER][$platform] Event received: ${event.eventName}");

    for (var listener in _listeners) {
      listener(event);
    }
  }

  void addListener(void Function(PusherEvent) listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  void removeListener(void Function(PusherEvent) listener) {
    _listeners.remove(listener);
  }

  bool isConnected() => pusher.connectionState.toLowerCase() == 'connected';

  Future<void> checkAndInitIfNeeded(String channelName) async {
    if (_isConnecting) return;

    if (!isConnected()) {
      await init(channelName);
    } else if (pusher.getChannel(channelName) == null) {
      await _subscribe(channelName);
    }
  }

  Future<Map<String, dynamic>?> onAuthorizer(
    String channelName,
    String socketId,
    options,
  ) async {
    final platform = Platform.isIOS ? "iOS" : "Android";
    printX("🔐 [DRIVER][$platform] Authorizing: channel=$channelName, socketId=$socketId");

    try {
      String authUrl = "${UrlContainer.baseUrl}${UrlContainer.pusherAuthenticate}$socketId/$channelName";
      printX("🔗 [DRIVER][$platform] Auth URL: $authUrl");

      ResponseModel response = await apiClient.request(
        authUrl,
        Method.postMethod,
        null,
        passHeader: true,
      );

      printX("📨 [DRIVER][$platform] Auth Response: statusCode=${response.statusCode}");

      if (response.statusCode == 200) {
        printX("✅ [DRIVER][$platform] Auth Success!");
        return response.responseJson;
      } else {
        printE("❌ [DRIVER][$platform] Auth Failed: ${response.statusCode} - ${response.responseJson}");
      }
    } catch (e) {
      printE("❌ [DRIVER][$platform] Auth Exception: $e");
      if (Platform.isIOS) {
        printE("🍎 iOS Auth Error - Check: 1) SSL/TLS settings, 2) ATS config in Info.plist, 3) Network permissions");
      }
    }
    return null;
  }
}
