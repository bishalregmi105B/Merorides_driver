import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/reservation/driver_reservation_controller.dart';
import 'package:ovoride_driver/data/model/reservation/driver_reservation_model.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/buttons/rounded_button.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/no_data.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  final int reservationId;
  
  const WeeklyScheduleScreen({super.key, required this.reservationId});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  late DateTime _selectedWeek;
  
  @override
  void initState() {
    super.initState();
    _selectedWeek = _getStartOfWeek(DateTime.now());
    
    // Load reservation details and weekly schedule
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<DriverReservationController>();
      controller.loadReservationDetail(widget.reservationId);
      controller.loadWeeklySchedule(widget.reservationId, _selectedWeek);
    });
  }
  
  DateTime _getStartOfWeek(DateTime date) {
    // Get Monday of the week
    int daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Weekly Schedule',
        bgColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverReservationController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }
          
          final reservation = controller.selectedReservation;
          if (reservation == null) {
            return Center(
              child: NoDataWidget(
                text: 'Reservation not found',
              ),
            );
          }
          
          if (!reservation.isRecurring) {
            return _buildOneTimeReservation(reservation);
          }
          
          return Column(
            children: [
              // Week Navigation
              Container(
                color: MyColor.colorWhite,
                padding: const EdgeInsets.all(Dimensions.space15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Calculate new week FIRST
                        final newWeek = _selectedWeek.subtract(const Duration(days: 7));
                        
                        setState(() {
                          _selectedWeek = newWeek;
                        });
                        
                        // Reload weekly schedule with the NEW week
                        Get.find<DriverReservationController>().loadWeeklySchedule(
                          widget.reservationId, 
                          newWeek,
                        );
                      },
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: MyColor.primaryColor,
                      ),
                    ),
                    Text(
                      _getWeekRangeText(_selectedWeek),
                      style: semiBoldDefault.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Calculate new week FIRST
                        final newWeek = _selectedWeek.add(const Duration(days: 7));
                        
                        setState(() {
                          _selectedWeek = newWeek;
                        });
                        
                        // Reload weekly schedule with the NEW week
                        Get.find<DriverReservationController>().loadWeeklySchedule(
                          widget.reservationId, 
                          newWeek,
                        );
                      },
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: MyColor.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Weekly Schedule
              Expanded(
                child: _buildWeekSchedule(reservation, _selectedWeek),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildWeekSchedule(DriverReservationModel reservation, DateTime weekStart) {
    final schedules = reservation.schedules ?? [];
    
    return ListView.builder(
      padding: const EdgeInsets.all(Dimensions.space15),
      itemCount: 7,
      itemBuilder: (context, index) {
        final currentDay = weekStart.add(Duration(days: index));
        final dayOfWeek = currentDay.weekday; // 1 = Monday, 7 = Sunday
        
        // Get schedules for this specific date
        final daySchedules = schedules.where((s) {
          if (s.scheduledDate == null) return false;
          final scheduleDate = DateTime.tryParse(s.scheduledDate!);
          return scheduleDate != null && 
                 scheduleDate.year == currentDay.year &&
                 scheduleDate.month == currentDay.month &&
                 scheduleDate.day == currentDay.day;
        }).toList();
        
        // Check if this specific date has schedules (not just if it's a recurring day)
        bool isScheduledDay = daySchedules.isNotEmpty;
        
        // For recurring reservations, also check if this day is part of the pattern
        // This is used to show pickup/return times even if no schedule exists yet
        bool isRecurringPatternDay = false;
        if (reservation.recurringDays != null) {
          isRecurringPatternDay = reservation.recurringDays!.any((day) => 
            day.toString() == dayOfWeek.toString()
          );
        }
        
        // Get pickup and return times for this day
        String? pickupTime = reservation.getPickupTimeForDay(dayOfWeek);
        String? returnTime = reservation.getReturnTimeForDay(dayOfWeek);
        
        return Container(
          margin: const EdgeInsets.only(bottom: Dimensions.space12),
          decoration: BoxDecoration(
            color: MyColor.colorWhite,
            borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
            border: Border.all(
              color: isScheduledDay ? MyColor.primaryColor : MyColor.borderColor,
              width: isScheduledDay ? 2 : 1,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.space15,
              vertical: Dimensions.space5,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isScheduledDay ? MyColor.primaryColor.withOpacity(0.1) : MyColor.screenBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentDay.day.toString(),
                    style: semiBoldDefault.copyWith(
                      fontSize: 16,
                      color: isScheduledDay ? MyColor.primaryColor : MyColor.bodyTextColor,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(currentDay),
                    style: regularSmall.copyWith(
                      fontSize: 10,
                      color: isScheduledDay ? MyColor.primaryColor : MyColor.bodyTextColor,
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              DateFormat('EEEE').format(currentDay),
              style: semiBoldDefault.copyWith(
                fontSize: 14,
                color: isScheduledDay ? MyColor.primaryColor : MyColor.bodyTextColor,
              ),
            ),
            subtitle: (isScheduledDay || isRecurringPatternDay) && pickupTime != null
                ? Text(
                    'Pickup: $pickupTime${returnTime != null ? ' | Return: $returnTime' : ''}',
                    style: regularSmall.copyWith(
                      color: MyColor.bodyTextColor,
                    ),
                  )
                : Text(
                    'No schedule',
                    style: regularSmall.copyWith(
                      color: MyColor.bodyTextColor.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
            children: [
              if (daySchedules.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(Dimensions.space15),
                  child: Column(
                    children: daySchedules.map((schedule) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: Dimensions.space10),
                        padding: const EdgeInsets.all(Dimensions.space12),
                        decoration: BoxDecoration(
                          color: _getScheduleStatusColor(schedule.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getScheduleStatusColor(schedule.status),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Schedule #${schedule.occurrenceNumber ?? ''}',
                                  style: semiBoldDefault.copyWith(fontSize: 12),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getScheduleStatusColor(schedule.status),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    schedule.statusText,
                                    style: regularSmall.copyWith(
                                      color: MyColor.colorWhite,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Dimensions.space8),
                            if (schedule.scheduledPickupTime != null)
                              Row(
                                children: [
                                  Icon(Icons.schedule, size: 14, color: MyColor.bodyTextColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pickup: ${schedule.scheduledPickupTime}',
                                    style: regularSmall.copyWith(fontSize: 11),
                                  ),
                                  if (schedule.scheduledReturnTime != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'Return: ${schedule.scheduledReturnTime}',
                                      style: regularSmall.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            // Show ride information
                            if (schedule.rideId != null || schedule.returnRideId != null) ...[
                              const SizedBox(height: Dimensions.space8),
                              // Pickup ride info
                              if (schedule.rideId != null)
                                Row(
                                  children: [
                                    Icon(Icons.flight_takeoff, size: 14, color: MyColor.greenSuccessColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pickup Ride: #${schedule.rideId}',
                                      style: regularSmall.copyWith(
                                        fontSize: 11,
                                        color: MyColor.greenSuccessColor,
                                      ),
                                    ),
                                  ],
                                ),
                              // Return ride info (for round-trips)
                              if (schedule.returnRideId != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.flight_land, size: 14, color: MyColor.primaryColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Return Ride: #${schedule.returnRideId}',
                                      style: regularSmall.copyWith(
                                        fontSize: 11,
                                        color: MyColor.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                            
                            // Action buttons based on ride status
                            const SizedBox(height: Dimensions.space10),
                            
                            // For one-way or pickup ride not started yet
                            if (schedule.rideId == null && schedule.isPending && isScheduledDay) ...[
                              Builder(
                                builder: (context) {
                                  final canStartNow = _canStartRide(schedule.scheduledDate, schedule.scheduledPickupTime);
                                  
                                  if (!canStartNow) {
                                    // Show info why ride can't be started yet
                                    return Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: MyColor.bodyTextColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: MyColor.bodyTextColor),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'Available to start 30 minutes before scheduled time (${schedule.scheduledPickupTime})',
                                              style: regularSmall.copyWith(
                                                fontSize: 10,
                                                color: MyColor.bodyTextColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return SizedBox(
                                    height: 36,
                                    child: RoundedButton(
                                      text: schedule.scheduledReturnTime != null 
                                          ? 'Start Pickup Ride' 
                                          : 'Start Ride',
                                      press: () {
                                        _startScheduleRide(schedule);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                            
                            // For round-trip: return ride button
                            if (schedule.scheduledReturnTime != null && 
                                schedule.rideId != null && 
                                schedule.returnRideId == null &&
                                schedule.status == ReservationScheduleModel.STATUS_RIDE_CREATED)
                              Builder(
                                builder: (context) {
                                  final canStartReturn = _canStartRide(schedule.scheduledDate, schedule.scheduledReturnTime);
                                  
                                  return Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: canStartReturn 
                                              ? MyColor.primaryColor.withOpacity(0.1)
                                              : MyColor.bodyTextColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              canStartReturn ? Icons.info_outline : Icons.schedule,
                                              size: 14,
                                              color: canStartReturn ? MyColor.primaryColor : MyColor.bodyTextColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                canStartReturn
                                                    ? 'Return ride ready to start at ${schedule.scheduledReturnTime}'
                                                    : 'Return ride available at ${schedule.scheduledReturnTime} (30 min before)',
                                                style: regularSmall.copyWith(
                                                  fontSize: 10,
                                                  color: canStartReturn ? MyColor.primaryColor : MyColor.bodyTextColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Show start return ride button only if it's time
                                      if (canStartReturn)
                                        SizedBox(
                                          height: 36,
                                          child: RoundedButton(
                                            text: 'Start Return Ride',
                                            press: () {
                                              _startReturnRide(schedule);
                                            },
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ] else if (isRecurringPatternDay && pickupTime != null) ...[
                Padding(
                  padding: const EdgeInsets.all(Dimensions.space15),
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.space12),
                    decoration: BoxDecoration(
                      color: MyColor.screenBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: MyColor.bodyTextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: Dimensions.space8),
                        Text(
                          'Schedule will be activated closer to the pickup time',
                          textAlign: TextAlign.center,
                          style: regularSmall.copyWith(
                            color: MyColor.bodyTextColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildOneTimeReservation(DriverReservationModel reservation) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.space15),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: MyColor.colorWhite,
          borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One-Time Reservation',
              style: semiBoldLarge,
            ),
            const SizedBox(height: Dimensions.space15),
            _buildInfoRow(Icons.calendar_today, 'Date', _formatDate(reservation.reservationDate ?? '')),
            _buildInfoRow(Icons.access_time, 'Pickup Time', reservation.getPickupTimeString() ?? 'N/A'),
            if (reservation.getReturnTimeString() != null)
              _buildInfoRow(Icons.access_time_filled, 'Return Time', reservation.getReturnTimeString()!),
            _buildInfoRow(Icons.location_on, 'Pickup', reservation.pickupLocation ?? ''),
            _buildInfoRow(Icons.flag, 'Destination', reservation.destination ?? ''),
            
            if (reservation.schedules != null && reservation.schedules!.isNotEmpty) ...[
              const SizedBox(height: Dimensions.space20),
              Text(
                'Schedule Status',
                style: semiBoldDefault,
              ),
              const SizedBox(height: Dimensions.space10),
              ...reservation.schedules!.map((schedule) => Container(
                padding: const EdgeInsets.all(Dimensions.space12),
                margin: const EdgeInsets.only(bottom: Dimensions.space10),
                decoration: BoxDecoration(
                  color: _getScheduleStatusColor(schedule.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getScheduleStatusColor(schedule.status),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      schedule.statusText,
                      style: regularDefault.copyWith(
                        color: _getScheduleStatusColor(schedule.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (schedule.isPending) ...[
                      Builder(
                        builder: (context) {
                          final canStart = _canStartRide(schedule.scheduledDate, schedule.scheduledPickupTime);
                          
                          if (!canStart) {
                            return Text(
                              'Available 30 min before scheduled time',
                              style: regularSmall.copyWith(
                                color: MyColor.bodyTextColor.withOpacity(0.7),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            );
                          }
                          
                          return ElevatedButton(
                            onPressed: () {
                              _startScheduleRide(schedule);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColor.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.space15,
                                vertical: Dimensions.space8,
                              ),
                            ),
                            child: Text('Start Ride'),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: MyColor.primaryColor),
          const SizedBox(width: Dimensions.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: regularSmall.copyWith(
                    color: MyColor.bodyTextColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: regularDefault,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getScheduleStatusColor(int? status) {
    switch (status) {
      case ReservationScheduleModel.STATUS_PENDING:
        return MyColor.colorYellow;
      case ReservationScheduleModel.STATUS_RIDE_CREATED:
        return MyColor.primaryColor;
      case ReservationScheduleModel.STATUS_COMPLETED:
        return MyColor.greenSuccessColor;
      case ReservationScheduleModel.STATUS_SKIPPED:
        return MyColor.colorGrey;
      case ReservationScheduleModel.STATUS_CANCELLED:
        return MyColor.redCancelTextColor;
      default:
        return MyColor.bodyTextColor;
    }
  }
  
  String _getWeekRangeText(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final startFormat = DateFormat('MMM d');
    final endFormat = DateFormat('MMM d, yyyy');
    return '${startFormat.format(weekStart)} - ${endFormat.format(weekEnd)}';
  }
  
  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      return DateFormat('EEEE, MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }
  
  void _startScheduleRide(ReservationScheduleModel schedule) {
    if (schedule.id == null) return;
    
    final isRoundTrip = schedule.scheduledReturnTime != null;
    final rideType = isRoundTrip ? 'Pickup Ride' : 'Ride';
    
    Get.dialog(
      AlertDialog(
        title: Text('Start $rideType'),
        content: Text(isRoundTrip 
            ? 'Start the pickup ride from ${schedule.pickupLocation} to ${schedule.destination}?'
            : 'Are you sure you want to start this scheduled ride?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final controller = Get.find<DriverReservationController>();
              final success = await controller.startReservationRide(schedule.id!);
              if (success) {
                // Reload the reservation detail to refresh the screen
                await controller.loadReservationDetail(widget.reservationId);
                Get.snackbar(
                  'Success',
                  '$rideType has been started successfully',
                  backgroundColor: MyColor.greenSuccessColor.withOpacity(0.8),
                  colorText: MyColor.colorWhite,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.primaryColor,
            ),
            child: Text('Start'),
          ),
        ],
      ),
    );
  }
  
  void _startReturnRide(ReservationScheduleModel schedule) {
    if (schedule.id == null) return;
    
    Get.dialog(
      AlertDialog(
        title: Text('Start Return Ride'),
        content: Text('Start the return ride from ${schedule.destination} back to ${schedule.pickupLocation}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final controller = Get.find<DriverReservationController>();
              // Same endpoint - API detects it's a return ride automatically
              final success = await controller.startReservationRide(schedule.id!);
              if (success) {
                // Reload the reservation detail to refresh the screen
                await controller.loadReservationDetail(widget.reservationId);
                Get.snackbar(
                  'Success',
                  'Return ride has been started successfully',
                  backgroundColor: MyColor.primaryColor.withOpacity(0.8),
                  colorText: MyColor.colorWhite,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.primaryColor,
            ),
            child: Text('Start Return Ride'),
          ),
        ],
      ),
    );
  }
  
  // Helper method to check if ride can be started (30 minutes before scheduled time)
  bool _canStartRide(String? scheduledDate, String? scheduledTime) {
    if (scheduledDate == null || scheduledTime == null) return false;
    
    try {
      // Parse the scheduled date and time
      final scheduleDate = DateTime.parse(scheduledDate);
      final timeParts = scheduledTime.split(':');
      final scheduledDateTime = DateTime(
        scheduleDate.year,
        scheduleDate.month,
        scheduleDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        timeParts.length > 2 ? int.parse(timeParts[2].split('.')[0]) : 0,
      );
      
      final now = DateTime.now();
      final difference = scheduledDateTime.difference(now);
      
      // Allow starting 30 minutes before scheduled time and up to 2 hours after
      return difference.inMinutes <= 30 && difference.inMinutes >= -120;
    } catch (e) {
      print('Error checking ride start time: $e');
      return true; // Default to allowing if there's an error
    }
  }
}
