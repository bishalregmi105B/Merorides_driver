import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_icons.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/data/controller/dashboard/dashboard_controller.dart';
import 'package:ovoride_driver/data/controller/pusher/global_pusher_controller.dart';
import 'package:ovoride_driver/data/controller/reservation/driver_reservation_controller.dart';
import 'package:ovoride_driver/data/controller/ride/ride_action/ride_action_controller.dart';
import 'package:ovoride_driver/data/controller/ride/all_ride/all_ride_controller.dart';
import 'package:ovoride_driver/data/repo/dashboard/dashboard_repo.dart';
import 'package:ovoride_driver/data/repo/reservation/driver_reservation_repo.dart';
import 'package:ovoride_driver/data/repo/ride/ride_repo.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/data/services/background_pusher_service.dart';
import 'package:ovoride_driver/presentation/components/annotated_region/annotated_region_widget.dart';
import 'package:ovoride_driver/presentation/components/image/custom_svg_picture.dart';
import 'package:ovoride_driver/presentation/components/will_pop_widget.dart';
import 'package:ovoride_driver/presentation/screens/ride_history/ride_activity_screen.dart';
import 'package:ovoride_driver/presentation/screens/package/package_dashboard_screen.dart';
import 'package:ovoride_driver/presentation/screens/reservation/reservation_dashboard_screen.dart';
import 'package:ovoride_driver/presentation/screens/profile_and_settings/profile_and_settings_screen.dart';
import 'package:ovoride_driver/presentation/screens/rides/home_screen/home_screen.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/data/repo/package/driver_package_repo.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';
import '../../packages/flutter_floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';

class DashBoardScreen extends StatefulWidget {
  const DashBoardScreen({super.key});

  @override
  State<DashBoardScreen> createState() => _DashBoardScreenState();
}

class _DashBoardScreenState extends State<DashBoardScreen> {
  int selectedIndex = 0;
  late List<Widget> _widgets;
  bool isPackageEnabled = true;
  bool isReservationEnabled = true;

  @override
  void initState() {
    Get.put(RideRepo(apiClient: Get.find()));
    Get.put(DashBoardRepo(apiClient: Get.find()));
    Get.put(DashBoardController(repo: Get.find()));
    var globalPusherController = Get.put(
      GlobalPusherController(
        apiClient: Get.find(),
        dashBoardController: Get.find(),
      ),
    );
    Get.put(RideActionController(repo: Get.find()));
    Get.put(AllRideController(repo: Get.find()));
    
    // Check if package and reservation systems are enabled
    final LocalStorageService localStorage = Get.find();
    isPackageEnabled = localStorage.isPackageEnabled();
    isReservationEnabled = localStorage.isReservationEnabled();
    
    // Initialize package controller only if package is enabled
    if (isPackageEnabled && Get.find<ApiClient>().getToken() != null) {
      Get.lazyPut(() => DriverPackageRepo(apiClient: Get.find()));
      Get.lazyPut(() => DriverPackageController(driverPackageRepo: Get.find()));
    }

    // Initialize reservation controller only if reservation is enabled
    if (isReservationEnabled && Get.find<ApiClient>().getToken() != null) {
      Get.lazyPut(() => DriverReservationRepo(apiClient: Get.find()));
      Get.lazyPut(() => DriverReservationController(driverReservationRepo: Get.find()));
    }
    
    // Build widget list based on enabled features
    _widgets = <Widget>[
      HomeScreen(),
      RideActivityScreen(
        onBackPress: () {
          changeScreen(0);
        },
      ),
    ];
    
    // Add package or reservation screen based on what's enabled
    if (isPackageEnabled && isReservationEnabled) {
      // If both are enabled, add both screens
      _widgets.add(const PackageDashboardScreen());
      _widgets.add(const ReservationDashboardScreen());
    } else if (isPackageEnabled) {
      _widgets.add(const PackageDashboardScreen());
    } else if (isReservationEnabled) {
      _widgets.add(const ReservationDashboardScreen());
    }
    
    // Always add settings screen at the end
    _widgets.add(const ProfileAndSettingsScreen());
    
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      globalPusherController.ensureConnection();
    });
  }

  void changeScreen(int val) {
    setState(() {
      selectedIndex = val;
    });
    
    // Notify PackageDashboardScreen when Packages tab is selected
    // Adjust index based on enabled features
    int packageIndex = isPackageEnabled ? 2 : -1;
    if (val == packageIndex && Get.isRegistered<DriverPackageController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final controller = Get.find<DriverPackageController>();
          if (!controller.hasLoadedInitialData) {
            controller.loadInitialData();
          }
        } catch (e) {
          printX('Error loading package data: $e');
        }
      });
    }
  }

  List<FloatingNavbarItem> _buildNavItems() {
    List<FloatingNavbarItem> items = [
      FloatingNavbarItem(
        icon: Icons.home,
        title: MyStrings.home.tr,
        customWidget: CustomSvgPicture(
          image: selectedIndex == 0 ? MyIcons.homeActive : MyIcons.home,
          color: selectedIndex == 0 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
        ),
      ),
      FloatingNavbarItem(
        icon: Icons.location_city,
        title: MyStrings.activity.tr,
        customWidget: CustomSvgPicture(
          image: selectedIndex == 1 ? MyIcons.activityActive : MyIcons.activity,
          color: selectedIndex == 1 ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
        ),
      ),
    ];

    // Add package tab if enabled
    int nextIndex = 2;
    if (isPackageEnabled) {
      items.add(
        FloatingNavbarItem(
          icon: Icons.card_giftcard,
          title: MyStrings.packages.tr,
          customWidget: Icon(
            Icons.card_giftcard,
            color: selectedIndex == nextIndex ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
          ),
        ),
      );
      nextIndex++;
    }

    // Add reservation tab if enabled
    if (isReservationEnabled) {
      items.add(
        FloatingNavbarItem(
          icon: Icons.event_note,
          title: MyStrings.reservations.tr,
          customWidget: Icon(
            Icons.event_note,
            color: selectedIndex == nextIndex ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
          ),
        ),
      );
      nextIndex++;
    }

    // Always add menu tab at the end
    items.add(
      FloatingNavbarItem(
        icon: Icons.list,
        title: MyStrings.menu.tr,
        customWidget: CustomSvgPicture(
          image: selectedIndex == nextIndex ? MyIcons.menuActive : MyIcons.menu,
          color: selectedIndex == nextIndex ? MyColor.primaryColor : MyColor.bodyMutedTextColor,
        ),
      ),
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopWidget(
      child: AnnotatedRegionWidget(
        systemNavigationBarColor: MyColor.colorWhite,
        statusBarColor: MyColor.transparentColor,
        child: GetBuilder<DashBoardController>(
          builder: (controller) => Scaffold(
            extendBody: true,
            body: IndexedStack(index: selectedIndex, children: _widgets),
            bottomNavigationBar: FloatingNavbar(
              inLine: true,
              fontSize: 11,
              backgroundColor: MyColor.colorWhite,
              unselectedItemColor: MyColor.bodyMutedTextColor,
              selectedItemColor: MyColor.primaryColor,
              borderRadius: Dimensions.space50,
              itemBorderRadius: Dimensions.space50,
              selectedBackgroundColor: MyColor.primaryColor.withValues(
                alpha: 0.09,
              ),
              onTap: (int val) {
                changeScreen(val);
                if (Get.isRegistered<AllRideController>()) {
                  Get.find<AllRideController>().changeTab(0);
                }
              },
              margin: const EdgeInsetsDirectional.only(
                start: Dimensions.space20,
                end: Dimensions.space20,
                bottom: Dimensions.space15,
              ),
              currentIndex: selectedIndex,
              items: _buildNavItems(),
            ),
          ),
        ),
      ),
    );
  }
}
