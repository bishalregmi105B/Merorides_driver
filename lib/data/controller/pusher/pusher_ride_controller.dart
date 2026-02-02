import 'dart:convert';

import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
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
  }

  void onEvent(PusherEvent event) {
    final eventName = event.eventName.toLowerCase().trim();
    printX('Received Event: $eventName ${event.data}');

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
      if (isRideDetailsPage()) {
        if (rideDetailsController.repo.apiClient.isNotificationAudioEnable()) {
          MyUtils.vibrate();
        }
      }

      rideMessageController.addEventMessage(enventResponse.data!.message!);
    }
  }

  void _handleCashPayment(PusherResponseModel enventResponse) {
    if (isRideDetailsPage()) {
      printX('Showing payment dialog...');
      rideDetailsController.onShowPaymentDialog(Get.context!);
    }
  }

  void _handleOnlinePayment(PusherResponseModel enventResponse) {
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
    CustomSnackBar.success(successList: [MyStrings.rideCompletedSuccessFully]);
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
      
      // Update ride status
      if (isRideDetailsPage()) {
        rideDetailsController.updateRide(ride);
      }
      
      // Show notification to driver
      if (canceledBy == 'rider') {
        MyUtils.vibrate();
        CustomSnackBar.error(
          errorList: ['🚫 Ride Canceled', 'Rider canceled the ride: $cancelReason'],
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

  void updateEvent(PusherResponseModel enventResponse) {
    printX('event.eventName ${enventResponse.eventName}');
    if (enventResponse.eventName == "pick_up" || enventResponse.eventName == "ride_end" || enventResponse.eventName == "online-payment-received" || enventResponse.eventName == "bid_accept") {
      if (enventResponse.eventName == "online-payment-received") {
        CustomSnackBar.success(successList: ["Payment Received"]);
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
