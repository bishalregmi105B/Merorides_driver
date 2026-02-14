import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/util.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/data/model/authorization/authorization_response_model.dart';
import 'package:ovoride_driver/data/model/global/response_model/response_model.dart';
import 'package:ovoride_driver/data/model/general_setting/general_setting_response_model.dart';
import 'package:ovoride_driver/data/model/global/ride/ride_model.dart';
import 'package:ovoride_driver/data/model/dashboard/dashboard_response_model.dart';
import 'package:ovoride_driver/data/model/global/user/global_driver_model.dart';
import 'package:ovoride_driver/data/repo/dashboard/dashboard_repo.dart';
import 'package:ovoride_driver/environment.dart';
import 'package:ovoride_driver/presentation/components/dialog/global_popup_dialog.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovoride_driver/presentation/screens/dashboard/forground_task_widget.dart';

import '../../../core/utils/url_container.dart';

class DashBoardController extends GetxController {
  DashBoardRepo repo;
  DashBoardController({required this.repo});
  TextEditingController bidAmountController = TextEditingController();

  String? profileImageUrl;
  bool isLoading = true;
  Position? currentPosition;
  String currentAddress = "${MyStrings.loading.tr}...";
  bool userOnline = false;
  String? nextPageUrl;
  int page = 0;
  bool isDriverVerified = true;
  bool isVehicleVerified = true;

  bool isVehicleVerificationPending = false;
  bool isDriverVerificationPending = false;
  bool hasShownPopup = false;

  GeneralSettingResponseModel generalSettingResponseModel = GeneralSettingResponseModel();

  String currency = '';
  String currencySym = '';
  String userImagePath = '';
  String rideFilter = 'new'; // 'new' or 'scheduled'

  void setRideFilter(String filter) {
    rideFilter = filter;
    page = 0;
    rideList.clear();
    update();
  }

  Future<void> initialData({bool shouldLoad = true}) async {
    isLoading = shouldLoad;
    page = 0;
    nextPageUrl;
    bidAmountController.text = '';
    currency = repo.apiClient.getCurrency();
    currencySym = repo.apiClient.getCurrency(isSymbol: true);

    // Reset popup flag so it can show again on each load
    hasShownPopup = false;

    generalSettingResponseModel = repo.apiClient.getGeneralSettings();
    update();
    await Future.wait([fetchLocation(), loadData(shouldLoad: shouldLoad)]);
    _maybeShowGlobalPopup();
    isLoading = false;
    update();
  }

  GlobalDriverInfoModel driver = GlobalDriverInfoModel(id: '-1');

  // Start location permission check but don't await yet
  Future<void> fetchLocation() async {
    bool hasPermission = await MyUtils.checkAppLocationPermission(
      onsuccess: () {
        initialData();
      },
    );
    printX(hasPermission);
    if (hasPermission) {
      getCurrentLocationAddress();
      update(); // Ensure UI reflects added location
    }
  }

  Future<void> getCurrentLocationAddress() async {
    try {
      final GeolocatorPlatform geolocator = GeolocatorPlatform.instance;

      // Check if location services are enabled
      bool serviceEnabled = await geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        printX("⚠️ Location services are disabled");
        currentAddress = 'Location services disabled';
        update();
        return;
      }

      // Check permission status
      LocationPermission permission = await geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          printX("⚠️ Location permission denied");
          currentAddress = 'Location permission denied';
          update();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        printX("⚠️ Location permission permanently denied");
        currentAddress = 'Location permission denied';
        update();
        return;
      }

      currentPosition = await geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (currentPosition != null) {
        if (Environment.addressPickerFromGoogleMapApi) {
          currentAddress = await repo.getActualAddress(currentPosition!.latitude, currentPosition!.longitude) ?? 'Unknown location..';
        } else {
          // Use local reverse geocoding
          final placemarks = await placemarkFromCoordinates(currentPosition!.latitude, currentPosition!.longitude);
          if (placemarks.isNotEmpty) {
            currentAddress = _formatAddress(placemarks.first);
          } else {
            currentAddress = 'Unknown location..';
          }
        }
      }
      update();
    } on TimeoutException catch (_) {
      printX("⚠️ Location request timed out, retrying with lower accuracy...");
      try {
        final GeolocatorPlatform geolocator = GeolocatorPlatform.instance;
        currentPosition = await geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
        if (currentPosition != null) {
          currentAddress = 'Approximate location';
        }
        update();
      } catch (e2) {
        printX("Error on fallback location: $e2");
      }
    } catch (e) {
      printX("Error getting location: $e");
      // Don't show error snackbar for location — it's non-critical
      // The driver can still use the app without reverse-geocoded address
    }
  }

  /// Format address from placemark components
  String _formatAddress(Placemark placemark) {
    // Safely format address components, checking for nulls
    final street = placemark.street ?? '';
    final subLocality = placemark.subLocality ?? '';
    final locality = placemark.locality ?? '';
    // final subAdministrativeArea = placemark.subAdministrativeArea ?? '';
    // final administrativeArea = placemark.administrativeArea ?? '';
    final country = placemark.country ?? '';

    // return [street, subLocality, locality, subAdministrativeArea, administrativeArea, country].where((part) => part.isNotEmpty).join(', ');
    return [
      street,
      subLocality,
      locality,
      country,
    ].where((part) => part.isNotEmpty).join(', ');
  }

  List<RideModel> rideList = [];
  List<RideModel> pendingRidesList = [];
  RideModel? runningRide;

  Future<void> loadData({bool shouldLoad = true}) async {
    try {
      page = page + 1;
      if (page == 1) {
        isLoading = shouldLoad;
        update();
      }

      // For package rides, call different API
      if (rideFilter == 'package') {
        await loadPackageRides();
        return;
      }

      ResponseModel responseModel = await repo.getDashboardData(
        page: page.toString(),
        status: rideFilter,
      );

      if (responseModel.statusCode == 200) {
        DashBoardRideResponseModel model = DashBoardRideResponseModel.fromJson(
          (responseModel.responseJson),
        );
        if (model.status == MyStrings.success) {
          nextPageUrl = model.data?.ride?.nextPageUrl;
          userImagePath = '${UrlContainer.domainUrl}/${model.data?.userImagePath}';
          if (page == 1) {
            rideList.clear();
          }
          rideList.addAll(model.data?.ride?.data ?? []);

          pendingRidesList = model.data?.pendingRides ?? [];

          isDriverVerified = model.data?.driverInfo?.dv == "1" ? true : false;
          isVehicleVerified = model.data?.driverInfo?.vv == "1" ? true : false;

          isVehicleVerificationPending = model.data?.driverInfo?.vv == "2" ? true : false;
          isDriverVerificationPending = model.data?.driverInfo?.dv == "2" ? true : false;

          userOnline = model.data?.driverInfo?.onlineStatus == "1" ? true : false;
          startForegroundTask();
          repo.apiClient.setOnlineStatus(userOnline);
          driver = model.data?.driverInfo ?? GlobalDriverInfoModel(id: '-1');
          runningRide = model.data?.runningRide;
          repo.apiClient.sharedPreferences.setString(
            SharedPreferenceHelper.userProfileKey,
            model.data?.driverInfo?.imageWithPath ?? '',
          );

          profileImageUrl = "${UrlContainer.domainUrl}/${model.data?.driverImagePath}/${model.data?.driverInfo?.image}";

          update();
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e);
    } finally {
      isLoading = false;
      update();
    }
  }

  List<dynamic> packageRidesList = [];

  Future<void> loadPackageRides() async {
    try {
      ResponseModel responseModel = await repo.getPackageRides();

      if (responseModel.statusCode == 200) {
        var responseData = responseModel.responseJson;

        if (responseData['status'] == 'success') {
          if (page == 1) {
            packageRidesList.clear();
          }
          packageRidesList = responseData['data']?['package_rides'] ?? [];
          userImagePath = '${UrlContainer.domainUrl}/${responseData['data']?['user_image_path'] ?? ''}';

          // No pagination for package rides
          nextPageUrl = null;

          update();
        } else {
          CustomSnackBar.error(
            errorList: responseData['message'] ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e);
    } finally {
      isLoading = false;
      update();
    }
  }

  bool hasNext() {
    return nextPageUrl != null && nextPageUrl!.isNotEmpty && nextPageUrl != 'null' ? true : false;
  }

  bool isSendBidLoading = false;
  Future<void> sendBid(
    String rideId, {
    String? amount,
    VoidCallback? onActon,
    RideModel? ride,
  }) async {
    isSendBidLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.createBid(
        amount: amount?.toString() ?? "",
        id: rideId,
      );
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );

        if (model.status == "success") {
          if (onActon != null) {
            onActon();
          }
          initialData(shouldLoad: false);

          // Check if it's a scheduled pre-bid ride
          if (ride != null && ride.isScheduled == 'true' && ride.notificationSent == 'false') {
            // For pre-bid: show toast instead of navigating
            CustomSnackBar.success(
              successList: [
                'Pre-bid submitted successfully!',
                'Your bid will be reviewed when the ride becomes active',
                'Check Activity screen for updates',
              ],
              dismissAll: false,
            );
          } else {
            // For immediate/notified rides: navigate to ride details
            Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideId)?.then((
              v,
            ) {
              initialData(shouldLoad: false);
            });
          }
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    isSendBidLoading = false;
    update();
  }

  void updateMainAmount(double amount) {
    bidAmountController.text = StringConverter.formatNumber(amount.toString());
    update();
  }

  // Accept Package Ride
  Future<void> acceptPackageRide(
    String rideId, {
    VoidCallback? onAction,
  }) async {
    isSendBidLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.acceptPackageRide(rideId: rideId);
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );

        if (model.status == "success") {
          if (onAction != null) {
            onAction();
          }
          initialData(shouldLoad: false);
          CustomSnackBar.success(
            successList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );

          // Extract ride data from response
          if (responseModel.responseJson['data'] != null && responseModel.responseJson['data']['ride'] != null) {
            var rideData = responseModel.responseJson['data']['ride'];

            // Navigate to ride details screen with ride object
            Get.toNamed(RouteHelper.rideDetailsScreen, arguments: rideData)?.then((v) {
              initialData(shouldLoad: false);
            });
          } else {
            // Fallback: Just refresh data if ride object not available
            initialData(shouldLoad: false);
          }
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    isSendBidLoading = false;
    update();
  }

  // Reject Package Ride
  Future<void> rejectPackageRide(
    String rideId, {
    VoidCallback? onAction,
  }) async {
    isSendBidLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.rejectPackageRide(rideId: rideId);
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );

        if (model.status == "success") {
          if (onAction != null) {
            onAction();
          }
          initialData(shouldLoad: false);
          CustomSnackBar.success(
            successList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    isSendBidLoading = false;
    update();
  }

  // Accept Reservation Ride
  Future<void> acceptReservationRide(
    String rideId, {
    VoidCallback? onAction,
  }) async {
    isSendBidLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.acceptReservationRide(rideId: rideId);
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );

        if (model.status == "success") {
          if (onAction != null) {
            onAction();
          }
          initialData(shouldLoad: false);
          CustomSnackBar.success(
            successList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );

          // Don't navigate - driver is already on ride screen from NEW_RESERVATION_RIDE Pusher event
          // Just refresh data to update ride status from PENDING to ACTIVE
          initialData(shouldLoad: false);
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    isSendBidLoading = false;
    update();
  }

  // Reject Reservation Ride
  Future<void> rejectReservationRide(
    String rideId, {
    VoidCallback? onAction,
  }) async {
    isSendBidLoading = true;
    update();

    try {
      ResponseModel responseModel = await repo.rejectReservationRide(rideId: rideId);
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );

        if (model.status == "success") {
          if (onAction != null) {
            onAction();
          }
          initialData(shouldLoad: false);
          CustomSnackBar.success(
            successList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
    isSendBidLoading = false;
    update();
  }

  // Reject Regular Ride (Sequential Notification)
  Future<void> rejectRide(
    String rideId, {
    VoidCallback? onAction,
  }) async {
    try {
      ResponseModel responseModel = await repo.rejectRide(rideId: rideId);
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );

        if (model.status == "success") {
          if (onAction != null) {
            onAction();
          }
          initialData(shouldLoad: false);
          // Don't show success message as driver is just declining
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
            dismissAll: false,
          );
        }
      } else {
        CustomSnackBar.error(
          errorList: [responseModel.message],
          dismissAll: false,
        );
      }
    } catch (e) {
      printX(e);
    }
  }

  //Driver Online Status Change
  bool isChangingOnlineStatusLoading = false;
  Future<void> onlineStatusSubmit({bool isFromRideDetails = false}) async {
    try {
      ResponseModel responseModel = await repo.onlineStatus(
        lat: currentPosition?.latitude.toString() ?? "",
        long: currentPosition?.longitude.toString() ?? "",
      );
      if (responseModel.statusCode == 200) {
        AuthorizationResponseModel model = AuthorizationResponseModel.fromJson(
          (responseModel.responseJson),
        );
        if (model.status == MyStrings.success) {
          repo.apiClient.setOnlineStatus(
            model.data?.online.toString() == 'true',
          );
          if (model.data?.online.toString() == 'true') {
            userOnline = true;
          } else {
            userOnline = false;
          }
          startForegroundTask();
          isChangingOnlineStatusLoading = false;
          await loadData(shouldLoad: true);
          update();
        } else {
          CustomSnackBar.error(
            errorList: model.message ?? [MyStrings.somethingWentWrong],
          );
        }
      } else {
        CustomSnackBar.error(errorList: [responseModel.message]);
      }
    } catch (e) {
      printE(e);
    } finally {
      isChangingOnlineStatusLoading = false;
      update();
    }
  }

  Future<void> startForegroundTask() async {
    try {
      if (userOnline) {
        await foregroundTaskKey.currentState?.startForegroundTask();
      } else {
        await foregroundTaskKey.currentState?.stopForegroundTask();
      }
    } catch (e) {
      printE(e);
    }
  }

  Future<void> changeOnlineStatus(bool value) async {
    bool hasPermission = await MyUtils.checkAppLocationPermission(
      onsuccess: () async {
        await onlineStatusSubmit();
      },
    );
    printX(hasPermission);
    if (hasPermission) {
      userOnline = value;
      update();
      await onlineStatusSubmit();
      update(); // Ensure UI reflects added location
    }
  }

  void _maybeShowGlobalPopup() {
    if (hasShownPopup) {
      return;
    }

    final popupModalValue = generalSettingResponseModel.data?.generalSetting?.popupModal;
    final popupEnabled = popupModalValue == '1' || popupModalValue == 'true' || popupModalValue == 1 || popupModalValue == true || popupModalValue == 'True';
    final popup = generalSettingResponseModel.data?.generalSetting?.popupSettings;

    if (!popupEnabled || popup == null) {
      return;
    }

    final hasContent = (popup.title ?? '').isNotEmpty || (popup.message ?? '').isNotEmpty;
    if (!hasContent) {
      return;
    }

    if (Get.context == null) {
      // Retry after a short delay if context is not ready
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!hasShownPopup && Get.context != null) {
          _maybeShowGlobalPopup();
        }
      });
      return;
    }

    hasShownPopup = true;

    // Use a delay to ensure the UI is fully rendered
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (Get.context != null) {
        try {
          Get.dialog(
            GlobalPopupDialog(popup: popup),
            barrierDismissible: true,
            barrierColor: Colors.black54,
          );
        } catch (e) {
          printX('Error showing popup: $e');
          hasShownPopup = false;
        }
      } else {
        hasShownPopup = false;
      }
    });
  }
}
