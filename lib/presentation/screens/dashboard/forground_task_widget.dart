import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/environment.dart';

final GlobalKey<ForGroundTaskWidgetState> foregroundTaskKey = GlobalKey();

class ForGroundTaskWidget extends StatefulWidget {
  final AsyncValueGetter<bool> onWillStart;
  final Widget child;
  final VoidCallback? callback;

  const ForGroundTaskWidget({
    super.key,
    required this.onWillStart,
    required this.child,
    this.callback,
  });

  @override
  State<ForGroundTaskWidget> createState() => ForGroundTaskWidgetState();
}

class ForGroundTaskWidgetState extends State<ForGroundTaskWidget> with WidgetsBindingObserver {
  late ApiClient apiClient;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    apiClient = Get.put(ApiClient(sharedPreferences: Get.find()));
    WidgetsBinding.instance.addObserver(this);
    _initForegroundSystem();
  }

  /// Initialize only notification channel and system setup
  Future<void> _initForegroundSystem() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription: 'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.DEFAULT,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(300000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    _isInitialized = true;

    // Auto start only if logged in AND online
    if (apiClient.isLoggedIn() && await widget.onWillStart()) {
      await startForegroundTask();
    }
  }

  /// Start foreground task manually or automatically
  Future<void> startForegroundTask() async {
    if (widget.callback == null) {
      printE("callback is null, cannot start service");
      return;
    }
    bool isServiceRunning = await FlutterForegroundTask.isRunningService;

    if (isServiceRunning) {
      printX("Service already running, skipping start");
      FlutterForegroundTask.restartService();
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      printE("Location permission denied");
      return;
    }
    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
    try {
      await FlutterForegroundTask.startService(
        serviceTypes: [ForegroundServiceTypes.dataSync],
        serviceId: 256,
        notificationTitle: "${Environment.appName} is running",
        notificationText: "Do not close the app",
        callback: widget.callback!,
        notificationIcon: const NotificationIcon(
          metaDataName: 'service.NOTIFICATION_ICON',
          backgroundColor: Colors.white,
        ),
      );
      printX("Foreground service started");
    } catch (e) {
      printE("Failed to start service: $e");
    }
  }

  /// Stop foreground service
  Future<void> stopForegroundTask() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
      printX("Foreground service stopped");
    }
  }

  /// Handle lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    printX("APP STATE -> $state");

    if (!await widget.onWillStart()) {
      await stopForegroundTask(); // user offline
      return;
    }

    if (state == AppLifecycleState.resumed || state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      await startForegroundTask(); // keep running when app in background
    }
  }

  Future<bool> _canPop() async {
    final bool canPop = mounted ? Navigator.canPop(context) : false;

    if (!canPop && await widget.onWillStart()) {
      FlutterForegroundTask.minimizeApp();
      printE("MINIMIZE");
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopForegroundTask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final bool canPop = await _canPop();
          if (canPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: widget.child,
    );
  }
}
