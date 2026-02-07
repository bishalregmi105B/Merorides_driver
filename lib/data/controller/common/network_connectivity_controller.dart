import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:ovoride_driver/data/services/pusher_service.dart';

class NetworkConnectivityController extends GetxController with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // Added
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // Added
    _connectivitySubscription.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Added
    if (state == AppLifecycleState.resumed) {
      print("📱 [DRIVER][Network] App resumed. Checking connection...");
      _checkConnectionAndReconnect();
    }
  }

  Future<void> _checkConnectionAndReconnect() async {
    // Added
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result.any((r) => r != ConnectivityResult.none);

      if (_isConnected) {
        print("🌐 [DRIVER][Network] Online after resume. Ensuring Pusher connection...");
        PusherManager().ensureConnection();
      }
    } catch (e) {
      print("⚠️ [DRIVER][Network] Error checking connection on resume: $e"); // Changed printE to print
    }
  }

  Future<void> _initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      return;
    }
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    bool previouslyConnected = _isConnected;

    // Check if any of the results indicate a connection
    _isConnected = result.any((r) => r != ConnectivityResult.none);

    if (_isConnected && !previouslyConnected) {
      // Connection restored
      print("🌐 [DRIVER][Network] Connection restored. Triggering Pusher reconnect...");
      PusherManager().ensureConnection();
    } else if (!_isConnected) {
      print("❌ [DRIVER][Network] Connection lost.");
    }
  }
}
