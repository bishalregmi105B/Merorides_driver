import 'dart:convert';

import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/audio_utils.dart';
import 'package:ovoride_driver/data/controller/dashboard/dashboard_controller.dart';
import 'package:ovoride_driver/data/controller/dashboard/ride_queue_manager.dart';
import 'package:ovoride_driver/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovoride_driver/data/model/global/ride/ride_model.dart';
import 'package:ovoride_driver/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../core/helper/string_format_helper.dart';
import '../../services/api_client.dart';

class GlobalPusherController extends GetxController {
  ApiClient apiClient;
  DashBoardController dashBoardController;

  GlobalPusherController({
    required this.apiClient,
    required this.dashBoardController,
  });

  @override
  void onInit() {
    super.onInit();

    PusherManager().addListener(onEvent);
    ensureConnection();
  }

  List<String> activeEventList = [
    "bid_accept",
    "cash_payment_request",
    "online_payment_received",
    "new_reservation_ride",
    "new_package_ride",
  ];

  void onEvent(PusherEvent event) {
    try {
      printE("Global pusher event: ${event.eventName}");
      if (event.data == null || event.eventName == "") return;

      final eventName = event.eventName.toLowerCase();

      //Dashbaod New Ride Popup and Rides Management
      if (eventName == "new_ride") {
        printX("🚖 Processing NEW_RIDE event. isRideDetailsPage: ${isRideDetailsPage()}");
        AudioUtils.playAudio(apiClient.getNotificationAudio());
        PusherResponseModel model = PusherResponseModel.fromJson(
          jsonDecode(event.data),
        );
        final modifyData = PusherResponseModel(
          eventName: eventName,
          channelName: event.channelName,
          data: model.data,
        );

        dashBoardController.updateMainAmount(
          double.tryParse(modifyData.data?.ride?.amount.toString() ?? "0.00") ?? 0,
        );

        // Get or create RideQueueManager
        final queueManager = Get.isRegistered<RideQueueManager>() ? Get.find<RideQueueManager>() : Get.put(RideQueueManager());

        // Add ride to queue
        queueManager.addRideToQueue(
          RideQueueItem(
            ride: modifyData.data?.ride ?? RideModel(id: "-1"),
            currency: Get.find<ApiClient>().getCurrency(),
            currencySym: Get.find<ApiClient>().getCurrency(isSymbol: true),
            dashboardController: dashBoardController,
          ),
        );
        dashBoardController.initialData(shouldLoad: false);

        // 🔔 Show snackbar notification
        Get.snackbar(
          '🚖 New Ride Request',
          'A new ride request is available nearby!',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
        );
      }

      //Package Ride Notification - Direct to driver (no bidding)
      if (eventName == "new_package_ride" && !isRideDetailsPage()) {
        AudioUtils.playAudio(apiClient.getNotificationAudio());
        PusherResponseModel model = PusherResponseModel.fromJson(
          jsonDecode(event.data),
        );
        final modifyData = PusherResponseModel(
          eventName: eventName,
          channelName: event.channelName,
          data: model.data,
        );

        // Get or create RideQueueManager
        final queueManager = Get.isRegistered<RideQueueManager>() ? Get.find<RideQueueManager>() : Get.put(RideQueueManager());

        // Add package ride to queue
        queueManager.addRideToQueue(
          RideQueueItem(
            ride: modifyData.data?.ride ?? RideModel(id: "-1"),
            currency: Get.find<ApiClient>().getCurrency(),
            currencySym: Get.find<ApiClient>().getCurrency(isSymbol: true),
            dashboardController: dashBoardController,
            isPackageRide: true,
          ),
        );
        dashBoardController.initialData(shouldLoad: false);

        // 🔔 Show snackbar notification
        Get.snackbar(
          '📦 New Package Ride',
          'A package delivery request is available!',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
        );
      }

      //Reservation Ride Notification - Direct to driver (pre-assigned from reservation)
      if (eventName == "new_reservation_ride" && !isRideDetailsPage()) {
        printX('🎯 NEW_RESERVATION_RIDE event received');
        AudioUtils.playAudio(apiClient.getNotificationAudio());
        PusherResponseModel model = PusherResponseModel.fromJson(
          jsonDecode(event.data),
        );
        final modifyData = PusherResponseModel(
          eventName: eventName,
          channelName: event.channelName,
          data: model.data,
        );

        // Get or create RideQueueManager
        final queueManager = Get.isRegistered<RideQueueManager>() ? Get.find<RideQueueManager>() : Get.put(RideQueueManager());

        // Add reservation ride to queue (similar to package ride)
        queueManager.addRideToQueue(
          RideQueueItem(
            ride: modifyData.data?.ride ?? RideModel(id: "-1"),
            currency: Get.find<ApiClient>().getCurrency(),
            currencySym: Get.find<ApiClient>().getCurrency(isSymbol: true),
            dashboardController: dashBoardController,
            isReservationRide: true, // Flag to identify reservation rides
          ),
        );
        dashBoardController.initialData(shouldLoad: false);

        // 🔔 Show snackbar notification
        Get.snackbar(
          '📅 New Reservation Ride',
          'A reserved ride is ready to be picked up!',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
        );
      }
      //Check Customer reject my bid
      if (eventName == "bid_reject") {
        printX('🚫 BID_REJECT event received on channel: ${event.channelName}');
        printX('📱 Current route: ${Get.currentRoute}');
        printX('📄 Is on ride details page: ${isRideDetailsPage()}');

        PusherResponseModel model = PusherResponseModel.fromJson(
          jsonDecode(event.data),
        );
        final pusherData = PusherResponseModel(
          eventName: eventName,
          channelName: event.channelName,
          data: model.data,
        );

        // Handle bid rejection regardless of current page
        _handleBidRejection(pusherData);

        // Refresh dashboard if not on ride details page
        if (!isRideDetailsPage()) {
          dashBoardController.initialData(shouldLoad: false);
        }
      }
      //Go to Ride Details Page Payment Complete
      if (activeEventList.contains(eventName) && !isRideDetailsPage()) {
        PusherResponseModel model = PusherResponseModel.fromJson(
          jsonDecode(event.data),
        );
        final pusherData = PusherResponseModel(
          eventName: eventName,
          channelName: event.channelName,
          data: model.data,
        );

        Get.toNamed(
          RouteHelper.rideDetailsScreen,
          arguments: pusherData.data?.ride?.id,
        );
      }
    } catch (e) {
      printE("Error handling event ${event.eventName}: $e");
    }
  }

  void _handleBidRejection(PusherResponseModel pusherData) {
    try {
      printX('📥 Processing bid rejection...');
      final ride = pusherData.data?.ride;
      final bidAmount = pusherData.data?.bidAmount ?? '0';
      final reason = pusherData.data?.reason ?? 'No reason provided';

      printX('💰 Bid amount: $bidAmount');
      printX('📝 Reason: $reason');
      printX('🚗 Ride: ${ride?.uid ?? "Unknown"}');

      if (ride != null) {
        printX('🚫 Your bid was rejected for ride ${ride.uid}');

        // Play notification sound
        try {
          AudioUtils.playAudio(apiClient.getNotificationAudio());
          printX('🔊 Audio notification played');
        } catch (audioError) {
          printX('⚠️ Failed to play audio: $audioError');
        }

        // Show notification to driver
        Get.snackbar(
          '🚫 Bid Rejected',
          'Your bid of ${apiClient.getCurrency(isSymbol: true)}${StringConverter.formatNumber(bidAmount)} was rejected by the rider.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
          duration: const Duration(seconds: 4),
        );
        printX('✅ Snackbar notification shown');
      } else {
        printX('⚠️ Ride data is null, cannot show notification');
      }
    } catch (e) {
      printE('❌ Error handling bid rejection: $e');
    }
  }

  bool isRideDetailsPage() {
    return Get.currentRoute == RouteHelper.rideDetailsScreen;
  }

  @override
  void onClose() {
    PusherManager().removeListener(onEvent);
    super.onClose();
  }

  Future<void> ensureConnection({String? channelName}) async {
    try {
      var userId = apiClient.sharedPreferences.getString(
            SharedPreferenceHelper.userIdKey,
          ) ??
          '';
      await PusherManager().checkAndInitIfNeeded(
        channelName ?? "private-rider-driver-$userId",
      );
    } catch (e) {
      printX("Error ensuring connection: $e");
    }
  }
}
