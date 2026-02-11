import 'dart:convert';

import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/audio_utils.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/util.dart';
import 'package:ovoride_driver/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovoride_driver/data/controller/ride/ride_meassage/ride_meassage_controller.dart';
import 'package:ovoride_driver/data/model/global/pusher/pusher_event_response_model.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/data/services/pusher_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../presentation/components/snack_bar/show_custom_snackbar.dart';

class PusherRideController extends GetxController {
  ApiClient apiClient;
  RideMessageController rideMessageController;
  RideDetailsController rideDetailsController;
  String rideID;
  PusherRideController({
    required this.apiClient,
    required this.rideMessageController,
    required this.rideDetailsController,
    required this.rideID,
  });

  @override
  void onInit() {
    super.onInit();
    PusherManager().addListener(onEvent);
    ensureConnection();
  }

  void onEvent(PusherEvent event) {
    final eventName = event.eventName.toLowerCase().trim();
    printX('📡 Received Event: $eventName');

    // Decode safely
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(event.data);
    } catch (e) {
      printX('Invalid JSON from Pusher: $e');
      return;
    }
    final model = PusherResponseModel.fromJson(data);
    final enventResponse = PusherResponseModel(
      eventName: eventName,
      channelName: event.channelName,
      data: model.data,
    );

    switch (eventName) {
      case "message_received":
        _handleMessageEvent(enventResponse);
        return;

      case "cash_payment_request":
        _handleCashPayment(enventResponse);
        break;

      case "online_payment_received":
        _handleOnlinePayment(enventResponse);
        break;

      case "ride_canceled":
        _handleRideCanceled(enventResponse);
        break;

      case "bid_accept":
        _handleBidAccept(enventResponse);
        break;

      case "new_ride":
        _handleNewRide(enventResponse);
        break;

      case "new_bid":
        _handleNewBid(enventResponse);
        break;

      case "pick_up":
        _handlePickUp(enventResponse);
        break;

      case "ride_end":
        _handleRideEnd(enventResponse);
        break;

      default:
        updateEvent(enventResponse);
        break;
    }
  }

  void _handleMessageEvent(PusherResponseModel enventResponse) {
    if (enventResponse.data?.message != null) {
      if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
        printX(
          'Message for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID',
        );
        return;
      }

      // 🔔 Play notification sound + vibrate for new message
      AudioUtils.playAudio(apiClient.getNotificationAudio());
      if (apiClient.isNotificationAudioEnable()) {
        MyUtils.vibrate();
      }

      rideMessageController.addEventMessage(enventResponse.data!.message!);

      // Show snackbar if not on ride details page
      if (!isRideDetailsPage()) {
        Get.snackbar(
          '💬 New Message',
          enventResponse.data!.message!.message ?? 'You have a new message',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
        );
      }
    }
  }

  void _handleCashPayment(PusherResponseModel enventResponse) {
    // 🔔 Play notification sound + vibrate for payment request
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    MyUtils.vibrate();

    if (isRideDetailsPage()) {
      printX('Showing payment dialog...');
      rideDetailsController.onShowPaymentDialog(Get.context!);
    }

    Get.snackbar(
      '💵 Cash Payment',
      'Rider is paying with cash. Please confirm receipt.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void _handleOnlinePayment(PusherResponseModel enventResponse) {
    // 🔔 Play notification sound + vibrate for payment received
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    MyUtils.vibrate();

    if (isRideDetailsPage()) {
      if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
        printX(
          'Message for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID',
        );
        return;
      }
      rideDetailsController.updateRide(enventResponse.data!.ride!);
    }

    Get.snackbar(
      '✅ Payment Received',
      'Online payment has been received successfully!',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void _handleRideCanceled(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Ride canceled event for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    final ride = enventResponse.data?.ride;
    final canceledBy = enventResponse.data?.canceledBy ?? 'unknown';
    final cancelReason = enventResponse.data?.cancelReason ?? 'No reason provided';

    if (ride != null) {
      printX('🚫 Ride canceled by $canceledBy: $cancelReason');

      // 🔔 Play notification sound + vibrate
      AudioUtils.playAudio(apiClient.getNotificationAudio());
      MyUtils.vibrate();

      // Update ride status
      if (isRideDetailsPage()) {
        rideDetailsController.updateRide(ride);
      }

      // Show notification to driver
      if (canceledBy == 'rider') {
        Get.snackbar(
          '🚫 Ride Canceled',
          'Rider canceled the ride: $cancelReason',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
          duration: const Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          '🚫 Ride Canceled',
          'The ride has been canceled: $cancelReason',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
          duration: const Duration(seconds: 5),
        );
      }

      // Navigate back to dashboard after short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (Get.currentRoute == RouteHelper.rideDetailsScreen) {
          Get.offAllNamed(RouteHelper.dashboard);
        }
      });
    }
  }

  void _handleBidAccept(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Bid accept for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    // 🔔 Play notification sound + vibrate
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    MyUtils.vibrate();

    if (isRideDetailsPage()) {
      rideDetailsController.updateRide(enventResponse.data!.ride!);
    }

    Get.snackbar(
      '🎉 Bid Accepted!',
      'Your bid has been accepted by the rider!',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void _handleNewRide(PusherResponseModel enventResponse) {
    // 🔔 Play notification sound + vibrate for new ride while on ride details
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    MyUtils.vibrate();

    Get.snackbar(
      '🚖 New Ride Request',
      'A new ride request is available!',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void _handleNewBid(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('New bid for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    // 🔔 Play notification sound + vibrate for new bid
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    MyUtils.vibrate();

    Get.snackbar(
      '🎯 New Bid',
      'A rider has placed a new bid on your ride!',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void _handlePickUp(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Pick up for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    // 🔔 Vibrate for pick up confirmation
    MyUtils.vibrate();

    if (isRideDetailsPage()) {
      rideDetailsController.updateRide(enventResponse.data!.ride!);
    }

    Get.snackbar(
      '📍 Ride Updated',
      'Ride pick-up status updated.',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void _handleRideEnd(PusherResponseModel enventResponse) {
    if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
      printX('Ride end for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID');
      return;
    }

    // 🔔 Play notification sound + vibrate for ride completion
    AudioUtils.playAudio(apiClient.getNotificationAudio());
    MyUtils.vibrate();

    if (isRideDetailsPage()) {
      rideDetailsController.updateRide(enventResponse.data!.ride!);
    }

    Get.snackbar(
      '✅ Ride Completed',
      MyStrings.rideCompletedSuccessFully,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
    );
  }

  void updateEvent(PusherResponseModel enventResponse) {
    printX('event.eventName ${enventResponse.eventName}');
    if (enventResponse.eventName == "pick_up" || enventResponse.eventName == "ride_end" || enventResponse.eventName == "online-payment-received" || enventResponse.eventName == "bid_accept") {
      if (enventResponse.eventName == "online-payment-received") {
        CustomSnackBar.success(successList: [MyStrings.rideCompletedSuccessFully]);
      }
      if (enventResponse.data!.ride != null && enventResponse.data!.ride!.id != rideID) {
        printX(
          'Message for different ride: ${enventResponse.data!.ride!.id}, current ride: $rideID',
        );
        return;
      }
      rideDetailsController.updateRide(enventResponse.data!.ride!);
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
