import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({Key? key}) : super(key: key);

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DriverPackageController>().loadWeeklySchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Weekly Schedule',
        bgColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverPackageController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CustomLoader());
          }

          if (controller.weeklySchedule.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadWeeklySchedule();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(Dimensions.space15),
              itemCount: 7,
              itemBuilder: (context, index) {
                final dayOfWeek = index + 1; // 1 = Monday, 7 = Sunday
                final daySchedule = controller.weeklySchedule[dayOfWeek];
                return _buildDayCard(dayOfWeek, daySchedule);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(int dayOfWeek, List<dynamic>? schedules) {
    const dayNames = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = dayNames[dayOfWeek];
    
    final morningSchedules = schedules != null && schedules.isNotEmpty ? schedules[0] as List : [];
    final eveningSchedules = schedules != null && schedules.length > 1 ? schedules[1] as List : [];
    
    final totalSchedules = morningSchedules.length + eveningSchedules.length;
    
    // Highlight today
    final now = DateTime.now();
    final isToday = now.weekday == dayOfWeek;

    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.space15),
      elevation: isToday ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        side: isToday 
          ? BorderSide(color: MyColor.primaryColor, width: 2)
          : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(Dimensions.space10),
          decoration: BoxDecoration(
            color: isToday 
              ? MyColor.primaryColor
              : totalSchedules > 0 
                ? MyColor.greenSuccessColor.withOpacity(0.2)
                : MyColor.colorGrey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isToday ? Icons.today : Icons.calendar_today,
            color: isToday 
              ? Colors.white
              : totalSchedules > 0 
                ? MyColor.greenSuccessColor
                : MyColor.colorGrey,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              dayName,
              style: boldLarge.copyWith(
                color: isToday ? MyColor.primaryColor : null,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: Dimensions.space5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space8,
                  vertical: Dimensions.space3,
                ),
                decoration: BoxDecoration(
                  color: MyColor.primaryColor,
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Text(
                  'Today',
                  style: regularSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          totalSchedules == 0 
            ? 'No schedules'
            : '$totalSchedules schedule${totalSchedules > 1 ? 's' : ''}',
          style: regularDefault.copyWith(color: MyColor.colorGrey),
        ),
        children: [
          if (totalSchedules == 0)
            Padding(
              padding: const EdgeInsets.all(Dimensions.space15),
              child: Text(
                'No schedules for this day',
                style: regularDefault.copyWith(color: MyColor.colorGrey),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            if (morningSchedules.isNotEmpty) ...[
              _buildTimeSlotSection('Morning', morningSchedules, MyColor.colorOrange),
            ],
            if (eveningSchedules.isNotEmpty) ...[
              _buildTimeSlotSection('Evening', eveningSchedules, MyColor.primaryColor),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotSection(String timeSlot, List<dynamic> schedules, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.space15),
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wb_sunny, size: 18, color: color),
              const SizedBox(width: Dimensions.space5),
              Text(
                timeSlot,
                style: boldDefault.copyWith(color: color),
              ),
              const SizedBox(width: Dimensions.space10),
              Text(
                '${schedules.length} schedule${schedules.length > 1 ? 's' : ''}',
                style: regularSmall.copyWith(color: MyColor.colorGrey),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          ...schedules.map((schedule) => _buildScheduleItem(schedule)).toList(),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.space10),
      padding: const EdgeInsets.all(Dimensions.space10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: MyColor.primaryColor),
              const SizedBox(width: Dimensions.space5),
              Text(
                schedule['pickup_time'] ?? 'N/A',
                style: boldDefault.copyWith(color: MyColor.primaryColor),
              ),
              const Spacer(),
              Text(
                schedule['user_name'] ?? 'N/A',
                style: regularDefault,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space5),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: MyColor.greenSuccessColor),
              const SizedBox(width: Dimensions.space5),
              Expanded(
                child: Text(
                  schedule['pickup_location'] ?? 'N/A',
                  style: regularSmall.copyWith(color: MyColor.colorGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: MyColor.redCancelTextColor),
              const SizedBox(width: Dimensions.space5),
              Expanded(
                child: Text(
                  schedule['drop_location'] ?? 'N/A',
                  style: regularSmall.copyWith(color: MyColor.colorGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_view_week,
            size: 80,
            color: MyColor.colorGrey.withOpacity(0.5),
          ),
          const SizedBox(height: Dimensions.space15),
          Text(
            'No weekly schedules',
            style: regularLarge.copyWith(color: MyColor.colorGrey),
          ),
          const SizedBox(height: Dimensions.space10),
          Text(
            'Your weekly schedule will appear here',
            style: regularDefault.copyWith(color: MyColor.colorGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
