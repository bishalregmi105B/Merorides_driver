import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/dashboard/dashboard_controller.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';
import 'package:ovoride_driver/presentation/components/bottom-sheet/custom_bottom_sheet.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_spacer.dart';
import 'package:ovoride_driver/presentation/components/no_data.dart';
import 'package:ovoride_driver/presentation/components/shimmer/ride_shimmer.dart';
import 'package:ovoride_driver/presentation/screens/dashboard/dashboard_background.dart';
import 'package:ovoride_driver/presentation/screens/dashboard/widgets/driver_kyc_warning_section.dart';
import 'package:ovoride_driver/presentation/screens/dashboard/widgets/vahicle_kyc_warning_section.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ovoride_driver/presentation/screens/rides/home_screen/widget/home_app_bar.dart';
import 'package:ovoride_driver/presentation/screens/rides/home_screen/widget/offer_bid_bottom_sheet.dart';
import '../../../../core/helper/string_format_helper.dart';
import 'widget/new_ride_card.dart';
import 'widget/package_ride_card.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState>? dashBoardScaffoldKey;
  const HomeScreen({super.key, this.dashBoardScaffoldKey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  double appBarSize = 120.0;
  late TabController tabController;
  int selectedTab = 0;
  late bool isPackageEnabled;

  ScrollController scrollController = ScrollController();
  void scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      if (Get.find<DashBoardController>().hasNext()) {
        Get.find<DashBoardController>().loadData();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Check if package system is enabled from admin settings
    isPackageEnabled = Get.find<LocalStorageService>().isPackageEnabled();

    // Create tab controller with dynamic length (2 or 3 tabs)
    tabController = TabController(length: isPackageEnabled ? 3 : 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      Get.find<DashBoardController>().isLoading = true;
      Get.find<DashBoardController>().setRideFilter('new');
      Get.find<DashBoardController>().initialData(shouldLoad: true);

      scrollController.addListener(scrollListener);
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DashBoardController>(
      builder: (controller) {
        return DashboardBackground(
          child: Scaffold(
            extendBody: true,
            backgroundColor: MyColor.transparentColor,
            extendBodyBehindAppBar: false,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(appBarSize),
              child: HomeScreenAppBar(controller: controller),
            ),
            body: RefreshIndicator(
              edgeOffset: 80,
              backgroundColor: MyColor.colorWhite,
              color: MyColor.primaryColor,
              triggerMode: RefreshIndicatorTriggerMode.onEdge,
              onRefresh: () async {
                controller.initialData(shouldLoad: true);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                controller: scrollController,
                slivers: <Widget>[
                  // Filter Tabs
                  SliverToBoxAdapter(
                    child: Container(
                      color: MyColor.colorWhite,
                      margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                      child: TabBar(
                        controller: tabController,
                        isScrollable: isPackageEnabled, // Scrollable only when 3 tabs
                        tabAlignment: isPackageEnabled ? TabAlignment.start : TabAlignment.fill, // Fill width when 2 tabs
                        labelColor: MyColor.primaryColor,
                        unselectedLabelColor: MyColor.colorGrey2,
                        indicatorColor: MyColor.primaryColor,
                        indicatorWeight: 3,
                        labelStyle: semiBoldDefault.copyWith(fontSize: 14),
                        unselectedLabelStyle: regularDefault.copyWith(fontSize: 14),
                        labelPadding: isPackageEnabled ? EdgeInsets.symmetric(horizontal: 12) : EdgeInsets.zero, // No padding when filling width
                        onTap: (index) {
                          setState(() {
                            selectedTab = index;
                          });
                          // Dynamic filter: 0=new, 1=scheduled, 2=package (only if package enabled)
                          String filter = 'new';
                          if (index == 0) {
                            filter = 'new';
                          } else if (index == 1) {
                            filter = 'scheduled';
                          } else if (index == 2 && isPackageEnabled) {
                            filter = 'package';
                          }
                          controller.setRideFilter(filter);
                          controller.initialData(shouldLoad: true);
                        },
                        tabs: [
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_new, size: 18),
                                SizedBox(width: 5),
                                Text('New Ride'),
                              ],
                            ),
                          ),
                          Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 18),
                                SizedBox(width: 5),
                                Text('Scheduled'),
                              ],
                            ),
                          ),
                          // Conditionally show Packages tab only if package system is enabled
                          if (isPackageEnabled)
                            Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.card_travel, size: 18),
                                  SizedBox(width: 5),
                                  Text('Packages'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        DriverKYCWarningSection(),
                        SizedBox(height: 2),
                        VehicleKYCWarningSection(),
                      ],
                    ),
                  ),
                  //Running Rides
                  if (controller.isLoading == false) ...[
                    if (controller.runningRide != null) ...[
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: Dimensions.space10,
                          ),
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                MyStrings.runningRide.tr,
                                style: semiBoldLarge.copyWith(
                                  color: MyColor.primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 10),
                              NewRideCardWidget(
                                isActive: true,
                                ride: controller.runningRide!,
                                currency: controller.currencySym,
                                driverImagePath: '${controller.userImagePath}/${controller.runningRide?.user?.avatar}',
                                press: () {
                                  final ride = controller.runningRide!;
                                  Get.toNamed(
                                    RouteHelper.rideDetailsScreen,
                                    arguments: ride.id,
                                  );
                                },
                              )
                                  .animate(
                                    onPlay: (controller) => controller.repeat(),
                                  )
                                  .shakeX(
                                    duration: 1000.ms,
                                    delay: 4000.ms,
                                    curve: Curves.easeInOut,
                                    hz: 4,
                                  ),
                              spaceDown(Dimensions.space10),
                              if (controller.rideList.isNotEmpty) ...[
                                Text(
                                  MyStrings.newRide.tr,
                                  style: regularDefault.copyWith(
                                    color: MyColor.colorBlack,
                                    fontSize: 18,
                                  ),
                                ),
                                spaceDown(Dimensions.space10),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],

                  //All Requested Rides List
                  if (controller.isLoading) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.space16,
                        ),
                        child: Column(
                          children: List.generate(
                            10,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: Dimensions.space10,
                              ),
                              child: const RideShimmer(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ] else if (controller.isLoading == false && ((selectedTab == 2 && isPackageEnabled) ? controller.packageRidesList.isEmpty : controller.rideList.isEmpty)) ...[
                    SliverToBoxAdapter(
                      child: NoDataWidget(
                        text: (selectedTab == 2 && isPackageEnabled) ? 'No package rides scheduled for today' : MyStrings.noRideFoundInYourArea.tr,
                        isRide: true,
                        margin: controller.runningRide?.id != "-1" ? 4 : 8,
                      ),
                    ),
                  ] else ...[
                    // Package Rides List (only if package enabled and tab selected)
                    if (selectedTab == 2 && isPackageEnabled) ...[
                      SliverList.separated(
                        itemCount: controller.packageRidesList.length,
                        itemBuilder: (context, index) {
                          final packageRide = controller.packageRidesList[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.space16,
                            ),
                            child: PackageRideCard(
                              packageRide: packageRide,
                              userImagePath: controller.userImagePath,
                              onTap: () {
                                // If ride is active, navigate to ride details screen
                                if (packageRide['has_active_ride'] == true && packageRide['ride_id'] != null) {
                                  // Navigate to ride details screen with ride ID
                                  Get.toNamed(
                                    RouteHelper.rideDetailsScreen,
                                    arguments: packageRide['ride_id'],
                                  );
                                }
                                // If not started yet, just show package details (future enhancement)
                              },
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return spaceDown(Dimensions.space10);
                        },
                      ),
                    ] else ...[
                      // Regular Rides List
                      SliverList.separated(
                        itemCount: controller.rideList.length + 1,
                        itemBuilder: (context, index) {
                          if (controller.rideList.length == index) {
                            return controller.hasNext()
                                ? SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Dimensions.space16,
                                      ),
                                      child: const RideShimmer(),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.space16,
                            ),
                            child: NewRideCardWidget(
                              isActive: true,
                              ride: controller.rideList[index],
                              currency: controller.currencySym,
                              driverImagePath: '${controller.userImagePath}/${controller.rideList[index].user?.avatar}',
                              press: () {
                                final ride = controller.rideList[index];

                                // Allow bidding on all rides (pre-bid and regular)
                                // The difference will be in navigation after successful bid
                                printE(ride.amount);
                                controller.updateMainAmount(
                                  StringConverter.formatDouble(
                                    ride.amount.toString(),
                                  ),
                                );
                                CustomBottomSheet(
                                  child: OfferBidBottomSheet(ride: ride),
                                ).customBottomSheet(context);
                              },
                            ),
                          );
                        },
                        separatorBuilder: (BuildContext context, int index) {
                          return spaceDown(Dimensions.space10);
                        },
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.space16,
                          vertical: Dimensions.space20,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimensions.space20,
                            vertical: Dimensions.space15,
                          ),
                          decoration: BoxDecoration(
                            color: MyColor.colorWhite.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(Dimensions.space8),
                          ),
                          child: Text(
                            '© ${DateTime.now().year} Sparshalama Foundation',
                            style: TextStyle(
                              color: MyColor.colorBlack,
                              fontSize: Dimensions.fontDefault,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: spaceDown(Dimensions.space100)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
