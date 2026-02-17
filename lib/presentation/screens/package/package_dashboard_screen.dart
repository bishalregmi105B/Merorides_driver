import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';
import 'package:ovoride_driver/presentation/screens/package/widgets/package_statistics_card.dart';
import 'package:ovoride_driver/presentation/screens/package/widgets/assigned_package_card.dart';

class PackageDashboardScreen extends StatefulWidget {
  const PackageDashboardScreen({Key? key}) : super(key: key);

  @override
  State<PackageDashboardScreen> createState() => _PackageDashboardScreenState();
}

class _PackageDashboardScreenState extends State<PackageDashboardScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Check if package system is enabled
    if (!Get.find<LocalStorageService>().isPackageEnabled()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        CustomSnackBar.error(errorList: ['Package system is currently disabled']);
      });
      return;
    }

    printX('🎯 PackageDashboardScreen initState called');
    _tabController = TabController(length: 2, vsync: this);
    // Data loading is now handled by DashBoardScreen.changeScreen()
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'My Packages',
        bgColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverPackageController>(
        builder: (controller) {
          // Show single loading indicator when initially loading
          if (controller.isLoading && controller.assignedPackages.isEmpty) {
            return const Center(child: CustomLoader());
          }

          return Column(
            children: [
              // Statistics Section
              _buildStatisticsSection(controller),

              // Quick Actions for Schedule (NEW)
              _buildQuickActions(),

              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: MyColor.primaryColor,
                  unselectedLabelColor: MyColor.colorGrey,
                  indicatorColor: MyColor.primaryColor,
                  tabs: const [
                    Tab(text: 'Active Packages'),
                    Tab(text: 'All Packages'),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActivePackagesTab(controller),
                    _buildAllPackagesTab(controller),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection(DriverPackageController controller) {
    // If statistics not loaded yet, show placeholder instead of loader
    if (controller.statistics == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Package Statistics',
            style: regularLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: PackageStatisticsCard(
                  title: 'Total Assigned',
                  value: '${controller.statistics!.totalAssigned ?? 0}',
                  color: MyColor.primaryColor,
                  icon: Icons.assignment,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: PackageStatisticsCard(
                  title: 'Active',
                  value: '${controller.statistics!.activePackages ?? 0}',
                  color: MyColor.greenSuccessColor,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Row(
            children: [
              Expanded(
                child: PackageStatisticsCard(
                  title: 'Completed',
                  value: '${controller.statistics!.completedPackages ?? 0}',
                  color: MyColor.colorGrey,
                  icon: Icons.done_all,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: PackageStatisticsCard(
                  title: 'Rides Available',
                  value: '${controller.statistics!.totalRidesAvailable ?? 0}',
                  color: MyColor.colorOrange,
                  icon: Icons.directions_car,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(RouteHelper.todayScheduleScreen);
              },
              icon: const Icon(Icons.today, size: 20),
              label: const Text("Today's Schedule"),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.colorOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.space10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Get.toNamed(RouteHelper.weeklyScheduleScreen);
              },
              icon: const Icon(Icons.calendar_view_week, size: 20),
              label: const Text('Weekly View'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColor.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.space12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePackagesTab(DriverPackageController controller) {
    final activePackages = controller.assignedPackages.where((p) => p.status == 1).toList();

    if (activePackages.isEmpty) {
      return _buildEmptyState('No active packages assigned');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadAssignedPackages();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(Dimensions.space15),
        itemCount: activePackages.length,
        itemBuilder: (context, index) {
          final package = activePackages[index];
          return AssignedPackageCard(
            package: package,
            onTap: () {
              if (package.id != null) {
                Get.toNamed(RouteHelper.packageDetailsScreen, arguments: package.id);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildAllPackagesTab(DriverPackageController controller) {
    if (controller.assignedPackages.isEmpty) {
      return _buildEmptyState('No packages assigned yet');
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.loadAssignedPackages();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(Dimensions.space15),
        itemCount: controller.assignedPackages.length,
        itemBuilder: (context, index) {
          final package = controller.assignedPackages[index];
          return AssignedPackageCard(
            package: package,
            onTap: () {
              if (package.id != null) {
                Get.toNamed(RouteHelper.packageDetailsScreen, arguments: package.id);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: MyColor.colorGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Dimensions.space15),
          Text(
            message,
            style: regularDefault.copyWith(color: MyColor.colorGrey),
          ),
        ],
      ),
    );
  }
}
