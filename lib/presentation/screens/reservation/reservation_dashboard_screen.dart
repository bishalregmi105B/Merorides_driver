import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/reservation/driver_reservation_controller.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovoride_driver/presentation/screens/reservation/widgets/reservation_statistics_card.dart';
import 'package:ovoride_driver/presentation/screens/reservation/widgets/driver_reservation_card.dart';

class ReservationDashboardScreen extends StatefulWidget {
  const ReservationDashboardScreen({super.key});

  @override
  State<ReservationDashboardScreen> createState() => _ReservationDashboardScreenState();
}

class _ReservationDashboardScreenState extends State<ReservationDashboardScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Check if reservation system is enabled
    if (!Get.find<LocalStorageService>().isReservationEnabled()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        CustomSnackBar.error(errorList: ['Reservation system is currently disabled']);
      });
      return;
    }

    _tabController = TabController(length: 3, vsync: this);

    // Add listener for tab changes
    _tabController.addListener(_onTabChanged);

    // Load data when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<DriverReservationController>();
      if (!controller.hasLoadedInitialData) {
        controller.loadInitialData();
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    final controller = Get.find<DriverReservationController>();

    switch (_tabController.index) {
      case 0: // Today tab
        controller.loadTodayReservations();
        break;
      case 1: // Upcoming tab
        controller.loadUpcomingReservations();
        break;
      case 2: // History tab
        controller.loadAssignedReservations();
        break;
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return GetBuilder<DriverReservationController>(
      builder: (controller) {
        // Check if there are recurring reservations
        final hasRecurring = controller.assignedReservations.any((r) => r.isRecurring);

        return Scaffold(
          backgroundColor: MyColor.screenBgColor,
          appBar: CustomAppBar(
            title: MyStrings.reservations.tr,
            bgColor: MyColor.primaryColor,
            actionsWidget: [
              // View Schedules button (only show if there are recurring reservations)
              if (hasRecurring)
                IconButton(
                  onPressed: () {
                    _showRecurringReservationsDialog(controller);
                  },
                  icon: Icon(Icons.calendar_view_week, color: MyColor.colorWhite),
                  tooltip: 'View Schedules',
                ),
              // Map View button
              IconButton(
                onPressed: () {
                  Get.toNamed(RouteHelper.reservationMapScreen);
                },
                icon: Icon(Icons.map, color: MyColor.colorWhite),
                tooltip: 'View on Map',
              ),
              // Refresh button
              IconButton(
                onPressed: () {
                  controller.refreshAllData();
                },
                icon: Icon(Icons.refresh, color: MyColor.colorWhite),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: GetBuilder<DriverReservationController>(
            builder: (controller) {
              if (controller.isLoading && controller.assignedReservations.isEmpty) {
                return const CustomLoader();
              }

              return Column(
                children: [
                  // Statistics Cards
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space15,
                      vertical: Dimensions.space12,
                    ),
                    child: ReservationStatisticsCard(
                      totalReservations: controller.totalReservations,
                      activeReservations: controller.activeReservations,
                      todayReservations: controller.todayCount,
                      upcomingReservations: controller.upcomingCount,
                    ),
                  ),

                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: MyColor.colorWhite,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: MyColor.primaryColor,
                      unselectedLabelColor: MyColor.colorGrey,
                      indicatorColor: MyColor.primaryColor,
                      indicatorWeight: 3,
                      labelStyle: semiBoldDefault.copyWith(
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: regularDefault,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.today, size: 20),
                          text: MyStrings.today.tr,
                        ),
                        Tab(
                          icon: Icon(Icons.upcoming, size: 20),
                          text: MyStrings.upcoming.tr,
                        ),
                        Tab(
                          icon: Icon(Icons.history, size: 20),
                          text: MyStrings.history.tr,
                        ),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Today's Reservations
                        _buildReservationList(
                          controller.todayReservations,
                          emptyMessage: MyStrings.noReservationsToday.tr,
                          emptyIcon: Icons.event_available,
                          controller: controller,
                          onRefresh: () => controller.refreshAllData(),
                        ),

                        // Upcoming Reservations
                        _buildReservationList(
                          controller.upcomingReservations,
                          emptyMessage: MyStrings.noUpcomingReservations.tr,
                          emptyIcon: Icons.calendar_today,
                          controller: controller,
                          onRefresh: () => controller.loadUpcomingReservations(),
                        ),

                        // History
                        _buildReservationList(
                          controller.completedReservations,
                          emptyMessage: MyStrings.noReservationHistory.tr,
                          emptyIcon: Icons.history,
                          controller: controller,
                          onRefresh: () => controller.refreshAllData(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReservationList(
    List reservations, {
    required String emptyMessage,
    required IconData emptyIcon,
    required DriverReservationController controller,
    Future<void> Function()? onRefresh,
  }) {
    Widget content;

    if (reservations.isEmpty) {
      content = CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space20),
                    decoration: BoxDecoration(
                      color: MyColor.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      emptyIcon,
                      size: 64,
                      color: MyColor.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: Dimensions.space20),
                  Text(
                    emptyMessage,
                    style: regularDefault.copyWith(
                      color: MyColor.bodyTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.space10),
                  Text(
                    'Pull down to refresh',
                    style: regularSmall.copyWith(
                      color: MyColor.bodyTextColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      content = ListView.separated(
        padding: const EdgeInsets.only(
          left: Dimensions.space15,
          right: Dimensions.space15,
          top: Dimensions.space15,
          bottom: Dimensions.space8, // Padding for bottom navigation
        ),
        itemCount: reservations.length,
        separatorBuilder: (context, index) => const SizedBox(height: Dimensions.space12),
        itemBuilder: (context, index) {
          return DriverReservationCard(
            reservation: reservations[index],
            serviceImagePath: controller.serviceImagePath,
            userImagePath: controller.userImagePath,
          );
        },
      );
    }

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: MyColor.primaryColor,
        backgroundColor: MyColor.colorWhite,
        child: content,
      );
    }

    return content;
  }

  void _showRecurringReservationsDialog(DriverReservationController controller) {
    final recurringReservations = controller.assignedReservations.where((r) => r.isRecurring).toList();

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: MyColor.colorWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.defaultRadius),
            topRight: Radius.circular(Dimensions.defaultRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: Dimensions.space12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MyColor.colorGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
              child: Row(
                children: [
                  Icon(Icons.calendar_view_week, color: MyColor.primaryColor),
                  const SizedBox(width: Dimensions.space10),
                  Text(
                    'Recurring Reservations',
                    style: semiBoldLarge.copyWith(
                      color: MyColor.primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Dimensions.space15),
            // List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space15,
                  vertical: Dimensions.space10,
                ),
                itemCount: recurringReservations.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final reservation = recurringReservations[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(Dimensions.space10),
                      decoration: BoxDecoration(
                        color: MyColor.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.repeat,
                        color: MyColor.primaryColor,
                      ),
                    ),
                    title: Text(
                      '#${reservation.reservationCode ?? ''}',
                      style: semiBoldDefault,
                    ),
                    subtitle: Text(
                      '${reservation.pickupLocation ?? ''} → ${reservation.destination ?? ''}',
                      style: regularSmall.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: MyColor.primaryColor,
                    ),
                    onTap: () {
                      Get.back();
                      if (reservation.id != null) {
                        Get.toNamed('/reservation_weekly_schedule_screen', arguments: reservation.id);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: Dimensions.space15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
