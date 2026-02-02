import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/reservation/reservation_map_controller.dart';
import 'package:ovoride_driver/data/model/reservation/driver_reservation_model.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_divider.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';
import 'package:ovoride_driver/environment.dart';

class ReservationMapScreen extends StatefulWidget {
  const ReservationMapScreen({Key? key}) : super(key: key);

  @override
  State<ReservationMapScreen> createState() => _ReservationMapScreenState();
}

class _ReservationMapScreenState extends State<ReservationMapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(ReservationMapController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadReservations();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    controller.currentTabIndex = _tabController.index;
    controller.updateMapMarkers();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: '${MyStrings.reservations.tr} ${MyStrings.map.tr}',
        bgColor: MyColor.primaryColor,
        actionsWidget: [
          // Filter button
          IconButton(
            onPressed: () {
              _showFilterDialog();
            },
            icon: Icon(Icons.filter_list, color: MyColor.colorWhite),
            tooltip: MyStrings.filter.tr,
          ),
        ],
      ),
      body: GetBuilder<ReservationMapController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }

          return Column(
            children: [
              // Tab Bar
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
                  labelStyle: semiBoldDefault.copyWith(fontSize: 14),
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
                      text: MyStrings.completed.tr,
                    ),
                  ],
                ),
              ),
              
              // Map View
              Expanded(
                child: Stack(
                  children: [
                    // Google Map
                    GoogleMap(
                      trafficEnabled: false,
                      indoorViewEnabled: false,
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: true,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      initialCameraPosition: CameraPosition(
                        target: controller.centerPosition,
                        zoom: Environment.mapDefaultZoom,
                      ),
                      onMapCreated: (GoogleMapController mapController) {
                        controller.setMapController(mapController);
                        // Fit map to show all markers after a short delay
                        Future.delayed(const Duration(milliseconds: 500), () {
                          controller.centerMapOnReservations();
                        });
                      },
                      onCameraMove: (position) {
                        // Track camera movement if needed
                      },
                      markers: controller.markers,
                      polylines: Set<Polyline>.of(controller.polylines.values),
                    ),
                    
                    // Schedule Count Badge - Clickable
                    Positioned(
                      top: 16,
                      left: 16,
                      child: InkWell(
                        onTap: () {
                          if (controller.getScheduleCount() > 0) {
                            _showSchedulesBottomSheet(controller);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: MyColor.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event,
                                color: MyColor.colorWhite,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${controller.getScheduleCount()} ${MyStrings.schedules.tr}',
                                style: regularDefault.copyWith(
                                  color: MyColor.colorWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                color: MyColor.colorWhite,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Legend
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MyColor.colorWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              MyStrings.legend.tr,
                              style: semiBoldDefault.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Markers',
                              style: semiBoldDefault.copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            _legendItem(
                              color: Colors.green,
                              label: MyStrings.pickup.tr,
                              icon: Icons.location_on,
                            ),
                            const SizedBox(height: 4),
                            _legendItem(
                              color: Colors.red,
                              label: MyStrings.dropOff.tr,
                              icon: Icons.flag,
                            ),
                            if (_tabController.index == 0) ...[
                              const SizedBox(height: 4),
                              _legendItem(
                                color: Colors.orange,
                                label: '${MyStrings.upcoming.tr} ${MyStrings.today.tr}',
                                icon: Icons.timer,
                              ),
                            ],
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Text(
                              'Routes',
                              style: semiBoldDefault.copyWith(fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            _routeLegendItem(
                              color: const Color(0xFF2196F3),
                              label: MyStrings.inProgress.tr,
                            ),
                            const SizedBox(height: 4),
                            _routeLegendItem(
                              color: const Color(0xFF4CAF50),
                              label: MyStrings.completed.tr,
                            ),
                            const SizedBox(height: 4),
                            _routeLegendItem(
                              color: const Color(0xFF9C27B0),
                              label: MyStrings.assigned.tr,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: regularSmall.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _routeLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: regularSmall.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBottomSheet(DriverReservationModel reservation) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 320,
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: MyColor.colorGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          // Close Button
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () {
                controller.clearSelectedReservation();
              },
              icon: Icon(Icons.close, color: MyColor.colorGrey),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with User Info
                  Row(
                    children: [
                      // User Image
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: MyColor.primaryColor.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: reservation.user?.image != null
                              ? Image.network(
                                  '${UrlContainer.domainUrl}/assets/images/user/${reservation.user!.image}',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      size: 30,
                                      color: MyColor.primaryColor,
                                    );
                                  },
                                )
                              : Icon(
                                  Icons.person,
                                  size: 30,
                                  color: MyColor.primaryColor,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // User Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.user?.fullname ?? MyStrings.unknownUser.tr,
                              style: semiBoldDefault.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${MyStrings.reservationCode.tr}: ${reservation.reservationCode}',
                              style: regularSmall.copyWith(
                                color: MyColor.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(reservation.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(reservation.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(reservation.status),
                          style: regularSmall.copyWith(
                            color: _getStatusColor(reservation.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const CustomDivider(),
                  const SizedBox(height: 16),
                  
                  // Service and Trip Info
                  Row(
                    children: [
                      Expanded(
                        child: _infoItem(
                          icon: Icons.local_taxi,
                          label: MyStrings.service.tr,
                          value: reservation.service?.name ?? 'N/A',
                        ),
                      ),
                      Expanded(
                        child: _infoItem(
                          icon: Icons.repeat,
                          label: MyStrings.type.tr,
                          value: reservation.tripType == 'round_trip' ? MyStrings.roundTrip.tr : MyStrings.oneWay.tr,
                        ),
                      ),
                      Expanded(
                        child: _infoItem(
                          icon: Icons.people,
                          label: MyStrings.passengers.tr,
                          value: '${reservation.passengerCount ?? 1}',
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Pickup Location
                  _locationItem(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    label: MyStrings.pickup.tr,
                    location: reservation.pickupLocation ?? MyStrings.notSpecified.tr,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Drop Location
                  _locationItem(
                    icon: Icons.flag,
                    iconColor: Colors.red,
                    label: MyStrings.dropOff.tr,
                    location: reservation.destination ?? MyStrings.notSpecified.tr,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Schedule Info
                  if (reservation.schedules != null && reservation.schedules!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MyColor.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: MyColor.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${MyStrings.next.tr}: ${reservation.schedules!.first.scheduledDate} ${MyStrings.at.tr} ${reservation.schedules!.first.scheduledPickupTime}',
                              style: regularDefault.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: MyColor.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: regularSmall.copyWith(
            color: MyColor.colorGrey,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: semiBoldDefault.copyWith(fontSize: 13),
        ),
      ],
    );
  }

  Widget _locationItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String location,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: regularSmall.copyWith(
                  color: MyColor.colorGrey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: regularDefault.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case DriverReservationModel.STATUS_PENDING:
        return Colors.orange;
      case DriverReservationModel.STATUS_CONFIRMED:
        return Colors.blue;
      case DriverReservationModel.STATUS_DRIVER_ASSIGNED:
        return Colors.purple;
      case DriverReservationModel.STATUS_IN_PROGRESS:
        return Colors.indigo;
      case DriverReservationModel.STATUS_COMPLETED:
        return Colors.green;
      case DriverReservationModel.STATUS_CANCELLED:
        return Colors.red;
      default:
        return MyColor.colorGrey;
    }
  }

  String _getStatusText(int? status) {
    switch (status) {
      case DriverReservationModel.STATUS_PENDING:
        return MyStrings.pending.tr;
      case DriverReservationModel.STATUS_CONFIRMED:
        return MyStrings.confirmed.tr;
      case DriverReservationModel.STATUS_DRIVER_ASSIGNED:
        return MyStrings.assigned.tr;
      case DriverReservationModel.STATUS_IN_PROGRESS:
        return MyStrings.inProgress.tr;
      case DriverReservationModel.STATUS_COMPLETED:
        return MyStrings.completed.tr;
      case DriverReservationModel.STATUS_CANCELLED:
        return MyStrings.cancelled.tr;
      default:
        return MyStrings.unknown.tr;
    }
  }

  void _showFilterDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          MyStrings.filterReservations.tr,
          style: boldLarge,
        ),
        content: GetBuilder<ReservationMapController>(
          builder: (controller) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text(MyStrings.showPickupLocations.tr),
                  value: controller.showPickupMarkers,
                  onChanged: (value) {
                    controller.togglePickupMarkers();
                  },
                ),
                CheckboxListTile(
                  title: Text(MyStrings.showDropoffLocations.tr),
                  value: controller.showDropoffMarkers,
                  onChanged: (value) {
                    controller.toggleDropoffMarkers();
                  },
                ),
                CheckboxListTile(
                  title: Text(MyStrings.showRoutes.tr),
                  value: controller.showRoutes,
                  onChanged: (value) {
                    controller.toggleRoutes();
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(MyStrings.close.tr),
          ),
        ],
      ),
    );
  }

  void _showSchedulesBottomSheet(ReservationMapController controller) {
    List<DriverReservationModel> reservations = [];
    
    switch (_tabController.index) {
      case 0:
        reservations = controller.todayReservations;
        break;
      case 1:
        reservations = controller.upcomingReservations;
        break;
      case 2:
        reservations = controller.completedReservations;
        break;
    }

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: MyColor.colorWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: MyColor.colorGrey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${reservations.length} ${MyStrings.schedules.tr}',
                    style: semiBoldLarge,
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.close, color: MyColor.colorGrey),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // List of Schedules
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final reservation = reservations[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        Get.back();
                        // Show details bottom sheet
                        Get.bottomSheet(
                          _buildBottomSheet(reservation),
                          isDismissible: true,
                          enableDrag: true,
                          isScrollControlled: false,
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: MyColor.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reservation.user?.fullname ?? MyStrings.unknownUser.tr,
                                    style: semiBoldDefault,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(reservation.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _getStatusText(reservation.status),
                                    style: regularSmall.copyWith(
                                      color: _getStatusColor(reservation.status),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reservation.pickupLocation ?? MyStrings.notSpecified.tr,
                                    style: regularSmall.copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.flag, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    reservation.destination ?? MyStrings.notSpecified.tr,
                                    style: regularSmall.copyWith(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (reservation.schedules != null && reservation.schedules!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: MyColor.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.schedule, size: 12, color: MyColor.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${reservation.schedules!.first.scheduledDate} ${MyStrings.at.tr} ${reservation.schedules!.first.scheduledPickupTime}',
                                      style: regularSmall.copyWith(
                                        fontSize: 11,
                                        color: MyColor.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }
}
