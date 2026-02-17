import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/audio_utils.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/dashboard/dashboard_controller.dart';
import 'package:ovoride_driver/data/model/global/ride/ride_model.dart';
import 'package:ovoride_driver/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:ovoride_driver/presentation/screens/rides/home_screen/widget/offer_bid_bottom_sheet.dart';
import 'package:vibration/vibration.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Full-screen incoming ride screen (like WhatsApp call)
/// Shows when app is in background and receives a new ride request
class IncomingRideScreen extends StatefulWidget {
  final bool isPackageRide;
  final bool isReservationRide;

  const IncomingRideScreen({
    super.key,
    this.isPackageRide = false,
    this.isReservationRide = false,
  });

  @override
  State<IncomingRideScreen> createState() => _IncomingRideScreenState();
}

class _IncomingRideScreenState extends State<IncomingRideScreen> with TickerProviderStateMixin {
  RideModel? ride;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _timeoutTimer;
  Timer? _vibrateTimer;
  int _remainingSeconds = 30;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Get ride data from arguments - handle different types
    final args = Get.arguments;
    if (args is Map) {
      // From background pusher service - contains ride and flags
      final rideData = args['ride'];
      if (rideData is RideModel) {
        ride = rideData;
      } else {
        // If it's a ride ID string, navigate to ride details instead
        Get.offNamed(RouteHelper.rideDetailsScreen, arguments: rideData.toString());
        return;
      }
    } else if (args is RideModel) {
      // Direct RideModel passed
      ride = args;
    } else if (args is String) {
      // If it's just a ride ID, navigate to ride details instead
      Get.offNamed(RouteHelper.rideDetailsScreen, arguments: args);
      return;
    } else {
      // Invalid arguments, go back or show error
      printE('Invalid arguments passed to IncomingRideScreen: ${args.runtimeType}');
      Get.back();
      return;
    }

    // Keep screen awake
    WakelockPlus.enable();

    // Initialize animations
    _initializeAnimations();

    // Start timeout timer
    _startTimeoutTimer();

    // Play sound and vibrate
    _playAlertSound();
    _startVibration();

    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    // Pulse animation for accept button
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Slide animation for buttons
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start slide animation
    _slideController.forward();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _handleTimeout();
      }
    });
  }

  void _playAlertSound() async {
    try {
      // Play alert sound (you can use different sound for incoming rides)
      AudioUtils.playAudio('ride_alert');
    } catch (e) {
      printE('Error playing sound: $e');
    }
  }

  void _startVibration() async {
    // Check if device can vibrate
    bool? canVibrate = await Vibration.hasVibrator();
    if (canVibrate == true) {
      // Vibrate pattern: vibrate for 500ms, pause for 500ms, repeat
      _vibrateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        Vibration.vibrate(duration: 500);
      });
    }
  }

  void _stopVibration() {
    _vibrateTimer?.cancel();
    Vibration.cancel();
  }

  void _handleTimeout() {
    _cleanup();
    Get.back();
    Get.snackbar(
      'Ride Expired',
      'The ride request has expired',
      backgroundColor: MyColor.colorRed,
      colorText: MyColor.colorWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleAccept() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _cleanup();

    // Get dashboard controller
    final dashboardController = Get.find<DashBoardController>();

    // Set bid amount
    dashboardController.updateMainAmount(
      double.tryParse(ride!.amount.toString()) ?? 0,
    );

    // Navigate to ride details or show bid dialog
    Get.back(); // Close this screen

    // Check if it's a package or reservation ride
    bool isDirectAcceptance = widget.isPackageRide || widget.isReservationRide || ride!.isReservation == '1' || ride!.isReservation == 'true';

    if (isDirectAcceptance) {
      // Direct acceptance for package/reservation rides
      Get.toNamed(RouteHelper.rideDetailsScreen, arguments: ride!.id);
    } else {
      // Show bid dialog for regular rides
      CustomBottomSheet(
        child: OfferBidBottomSheet(ride: ride!),
      ).customBottomSheet(Get.context!);
    }
  }

  void _handleReject() {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    _cleanup();
    Get.back();

    Get.snackbar(
      'Ride Rejected',
      'You have rejected the ride request',
      backgroundColor: MyColor.colorGrey,
      colorText: MyColor.colorWhite,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _cleanup() {
    _timeoutTimer?.cancel();
    _stopVibration();
    // AudioUtils.stopAudio(); // Stop audio if playing
    WakelockPlus.disable();
  }

  @override
  void dispose() {
    _cleanup();
    _pulseController.dispose();
    _slideController.dispose();

    // Restore status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: MyColor.primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If ride is null, show loading or return empty container
    // This can happen during navigation transitions
    if (ride == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MyColor.primaryColor,
              MyColor.primaryColor.withValues(alpha: 0.8),
              MyColor.screenBgColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with timer
              Padding(
                padding: const EdgeInsets.all(Dimensions.space20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Ride Request',
                      style: boldExtraLarge.copyWith(
                        color: MyColor.colorWhite,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.space12,
                        vertical: Dimensions.space5,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingSeconds <= 10 ? MyColor.colorRed : MyColor.colorWhite.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                      ),
                      child: Text(
                        '${_remainingSeconds}s',
                        style: semiBoldDefault.copyWith(
                          color: MyColor.colorWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Ride type indicator
              if (widget.isPackageRide)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.space20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space15,
                    vertical: Dimensions.space8,
                  ),
                  decoration: BoxDecoration(
                    color: MyColor.colorOrange,
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2,
                        color: MyColor.colorWhite,
                        size: 20,
                      ),
                      const SizedBox(width: Dimensions.space5),
                      Text(
                        'PACKAGE DELIVERY',
                        style: boldDefault.copyWith(
                          color: MyColor.colorWhite,
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.isReservationRide || ride!.isReservation == '1' || ride!.isReservation == 'true')
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.space20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.space15,
                    vertical: Dimensions.space8,
                  ),
                  decoration: BoxDecoration(
                    color: MyColor.pendingColor,
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: MyColor.colorWhite,
                        size: 20,
                      ),
                      const SizedBox(width: Dimensions.space5),
                      Text(
                        'RESERVATION RIDE',
                        style: boldDefault.copyWith(
                          color: MyColor.colorWhite,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: Dimensions.space20),

              // Main content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: Dimensions.space20),
                  padding: const EdgeInsets.all(Dimensions.space20),
                  decoration: BoxDecoration(
                    color: MyColor.colorWhite,
                    borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
                    boxShadow: [
                      BoxShadow(
                        color: MyColor.colorBlack.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Amount
                      Text(
                        '${Get.find<DashBoardController>().currencySym}${StringConverter.formatNumber(ride!.amount.toString())}',
                        style: boldOverLarge.copyWith(
                          color: MyColor.primaryColor,
                          fontSize: 48,
                        ),
                      ),

                      const SizedBox(height: Dimensions.space10),

                      // Distance & Duration
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoChip(
                            Icons.route,
                            '${ride!.distance ?? '0'} km',
                          ),
                          const SizedBox(width: Dimensions.space15),
                          _buildInfoChip(
                            Icons.timer,
                            '${ride!.duration ?? '0'} min',
                          ),
                        ],
                      ),

                      const SizedBox(height: Dimensions.space30),

                      // Pickup location
                      _buildLocationRow(
                        icon: Icons.trip_origin,
                        iconColor: MyColor.greenSuccessColor,
                        title: 'PICKUP',
                        address: ride!.pickupLocation ?? 'Unknown location',
                      ),

                      // Dotted line
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        child: Column(
                          children: List.generate(
                              3,
                              (index) => Container(
                                    width: 2,
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(vertical: 2),
                                    color: MyColor.borderColor,
                                  )),
                        ),
                      ),

                      // Destination
                      _buildLocationRow(
                        icon: Icons.location_on,
                        iconColor: MyColor.colorRed,
                        title: 'DESTINATION',
                        address: ride!.destination ?? 'Unknown location',
                      ),

                      const SizedBox(height: Dimensions.space20),

                      // User info
                      if (ride!.user != null) ...[
                        const Divider(),
                        const SizedBox(height: Dimensions.space10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: MyColor.borderColor,
                              child: Text(
                                ride!.user?.firstname?.substring(0, 1).toUpperCase() ?? 'U',
                                style: boldLarge.copyWith(
                                  color: MyColor.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: Dimensions.space10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ride!.user?.firstname ?? ''} ${ride!.user?.lastname ?? ''}',
                                    style: semiBoldDefault.copyWith(
                                      color: MyColor.primaryTextColor,
                                    ),
                                  ),
                                  Text(
                                    'Rider',
                                    style: regularSmall.copyWith(
                                      color: MyColor.bodyTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Action buttons
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.space20),
                  child: Row(
                    children: [
                      // Reject button
                      Expanded(
                        child: GestureDetector(
                          onTap: _isProcessing ? null : _handleReject,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: MyColor.colorRed,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: MyColor.colorRed.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.close,
                                    color: MyColor.colorWhite,
                                    size: 28,
                                  ),
                                  const SizedBox(width: Dimensions.space10),
                                  Text(
                                    'Reject',
                                    style: boldLarge.copyWith(
                                      color: MyColor.colorWhite,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: Dimensions.space15),

                      // Accept button
                      Expanded(
                        child: ScaleTransition(
                          scale: _pulseAnimation,
                          child: GestureDetector(
                            onTap: _isProcessing ? null : _handleAccept,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: MyColor.greenSuccessColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: MyColor.greenSuccessColor.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isProcessing
                                    ? const CircularProgressIndicator(
                                        color: MyColor.colorWhite,
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.check,
                                            color: MyColor.colorWhite,
                                            size: 28,
                                          ),
                                          const SizedBox(width: Dimensions.space10),
                                          Text(
                                            'Accept',
                                            style: boldLarge.copyWith(
                                              color: MyColor.colorWhite,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space10,
        vertical: Dimensions.space5,
      ),
      decoration: BoxDecoration(
        color: MyColor.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: MyColor.bodyTextColor,
          ),
          const SizedBox(width: Dimensions.space5),
          Text(
            text,
            style: regularDefault.copyWith(
              color: MyColor.bodyTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(width: Dimensions.space10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: regularSmall.copyWith(
                  color: MyColor.bodyTextColor,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: regularDefault.copyWith(
                  color: MyColor.primaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
