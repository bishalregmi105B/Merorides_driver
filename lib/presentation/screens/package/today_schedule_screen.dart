import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({Key? key}) : super(key: key);

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DriverPackageController>().loadTodaySchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: "Today's Schedule",
        bgColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverPackageController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CustomLoader());
          }

          if (controller.todaySchedules.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadTodaySchedules();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(Dimensions.space15),
              itemCount: controller.todaySchedules.length,
              itemBuilder: (context, index) {
                final schedule = controller.todaySchedules[index];
                return _buildScheduleCard(schedule);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final timeSlot = schedule['time_slot'] ?? '';
    final isMorning = timeSlot.toLowerCase() == 'morning';

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.space15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
          border: Border(
            left: BorderSide(
              color: isMorning ? MyColor.colorOrange : MyColor.primaryColor,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with time and time slot
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: isMorning ? MyColor.colorOrange : MyColor.primaryColor,
                      ),
                      const SizedBox(width: Dimensions.space5),
                      Text(
                        schedule['pickup_time'] ?? 'N/A',
                        style: boldLarge.copyWith(
                          color: isMorning ? MyColor.colorOrange : MyColor.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space10,
                      vertical: Dimensions.space5,
                    ),
                    decoration: BoxDecoration(
                      color: isMorning 
                        ? MyColor.colorOrange.withOpacity(0.1)
                        : MyColor.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                    ),
                    child: Text(
                      timeSlot[0].toUpperCase() + timeSlot.substring(1),
                      style: regularSmall.copyWith(
                        color: isMorning ? MyColor.colorOrange : MyColor.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.space15),

              // User and package info
              _buildInfoRow(
                Icons.person,
                'Customer',
                schedule['user_name'] ?? 'N/A',
                MyColor.primaryColor,
              ),

              const SizedBox(height: Dimensions.space10),

              _buildInfoRow(
                Icons.card_giftcard,
                'Package',
                schedule['package_name'] ?? 'N/A',
                MyColor.colorGrey,
              ),

              const SizedBox(height: Dimensions.space10),

              _buildInfoRow(
                Icons.swap_horiz,
                'Trip Type',
                schedule['trip_type'] ?? 'N/A',
                MyColor.colorGrey,
              ),

              const Divider(height: Dimensions.space20),

              // Pickup location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space5),
                    decoration: BoxDecoration(
                      color: MyColor.greenSuccessColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      size: 16,
                      color: MyColor.greenSuccessColor,
                    ),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup',
                          style: regularSmall.copyWith(color: MyColor.colorGrey),
                        ),
                        Text(
                          schedule['pickup_location'] ?? 'N/A',
                          style: regularDefault,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.space10),

              // Drop location
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.space5),
                    decoration: BoxDecoration(
                      color: MyColor.redCancelTextColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      size: 16,
                      color: MyColor.redCancelTextColor,
                    ),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Drop',
                          style: regularSmall.copyWith(color: MyColor.colorGrey),
                        ),
                        Text(
                          schedule['drop_location'] ?? 'N/A',
                          style: regularDefault,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.space15),

              // Contact button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement call functionality
                  },
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(schedule['user_mobile'] ?? 'Contact Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColor.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.space10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Dimensions.space5),
        Text(
          '$label: ',
          style: regularDefault.copyWith(color: MyColor.colorGrey),
        ),
        Expanded(
          child: Text(
            value,
            style: regularDefault.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: MyColor.colorGrey.withOpacity(0.5),
          ),
          const SizedBox(height: Dimensions.space15),
          Text(
            'No schedules for today',
            style: regularLarge.copyWith(color: MyColor.colorGrey),
          ),
          const SizedBox(height: Dimensions.space10),
          Text(
            'Your scheduled pickups will appear here',
            style: regularDefault.copyWith(color: MyColor.colorGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
