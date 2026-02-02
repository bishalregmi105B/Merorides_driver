import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/reservation/driver_reservation_controller.dart';
import 'package:ovoride_driver/data/model/reservation/driver_reservation_model.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_divider.dart';
import 'package:ovoride_driver/presentation/components/image/my_network_image_widget.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';

class ReservationDetailScreen extends StatefulWidget {
  const ReservationDetailScreen({super.key});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  int? reservationId;
  
  @override
  void initState() {
    super.initState();
    reservationId = Get.arguments;
    if (reservationId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.find<DriverReservationController>().loadReservationDetail(reservationId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: MyStrings.reservationDetails.tr,
        isShowBackBtn: true,
      ),
      body: GetBuilder<DriverReservationController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const CustomLoader();
          }

          if (controller.selectedReservation == null) {
            return Center(
              child: Text(
                MyStrings.noDataFound.tr,
                style: regularDefault.copyWith(color: MyColor.bodyTextColor),
              ),
            );
          }

          final reservation = controller.selectedReservation!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.space15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(reservation),
                const SizedBox(height: Dimensions.space15),
                _buildUserInfoCard(reservation),
                const SizedBox(height: Dimensions.space15),
                _buildServiceInfoCard(reservation),
                const SizedBox(height: Dimensions.space15),
                _buildLocationCard(reservation),
                const SizedBox(height: Dimensions.space15),
                _buildScheduleCard(reservation),
                if (reservation.specialRequirements != null) ...[
                  const SizedBox(height: Dimensions.space15),
                  _buildSpecialRequirementsCard(reservation),
                ],
                const SizedBox(height: Dimensions.space15),
                // View Weekly Schedule button for recurring reservations
                if (reservation.isRecurring)
                  _buildWeeklyScheduleButton(reservation),
                const SizedBox(height: Dimensions.space20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(DriverReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${reservation.reservationCode ?? ''}',
                style: semiBoldExtraLarge.copyWith(
                  color: MyColor.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.space10,
                  vertical: Dimensions.space5,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(reservation.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                ),
                child: Text(
                  _getStatusText(reservation.status),
                  style: semiBoldDefault.copyWith(
                    color: _getStatusColor(reservation.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space10),
          Row(
            children: [
              Icon(
                (reservation.reservationType ?? '') == 'recurring'
                    ? Icons.repeat
                    : Icons.event,
                color: MyColor.bodyTextColor,
                size: 18,
              ),
              const SizedBox(width: Dimensions.space5),
              Text(
                (reservation.reservationType ?? '') == 'recurring'
                    ? MyStrings.recurring.tr
                    : MyStrings.oneTime.tr,
                style: regularDefault.copyWith(
                  color: MyColor.bodyTextColor,
                ),
              ),
              const SizedBox(width: Dimensions.space15),
              Icon(
                (reservation.tripType ?? '') == 'round_trip'
                    ? Icons.swap_horiz
                    : Icons.arrow_forward,
                color: MyColor.bodyTextColor,
                size: 18,
              ),
              const SizedBox(width: Dimensions.space5),
              Text(
                (reservation.tripType ?? '') == 'round_trip'
                    ? MyStrings.roundTrip.tr
                    : MyStrings.oneWay.tr,
                style: regularDefault.copyWith(
                  color: MyColor.bodyTextColor,
                ),
              ),
            ],
          ),
          if (reservation.estimatedAmount != null) ...[
            const CustomDivider(space: Dimensions.space10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  MyStrings.estimatedFare.tr,
                  style: regularDefault.copyWith(
                    color: MyColor.bodyTextColor,
                  ),
                ),
                Text(
                  '\$${reservation.estimatedAmount}',
                  style: semiBoldLarge.copyWith(
                    color: MyColor.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(DriverReservationModel reservation) {
    final userInfo = reservation.user;
    if (userInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.passengerDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: MyImageWidget(
                  imageUrl: '${UrlContainer.domainUrl}/assets/images/user/${userInfo.image}',
                  height: 60,
                  width: 60,
                ),
              ),
              const SizedBox(width: Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${userInfo.firstname ?? ''} ${userInfo.lastname ?? ''}',
                      style: semiBoldLarge.copyWith(
                        color: MyColor.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space5),
                    if (userInfo.mobile != null && userInfo.mobile!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: MyColor.bodyTextColor,
                          ),
                          const SizedBox(width: Dimensions.space5),
                          Text(
                            userInfo.mobile ?? '',
                            style: regularDefault.copyWith(
                              color: MyColor.bodyTextColor,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (reservation.passengerCount != null) ...[
            const CustomDivider(space: Dimensions.space10),
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 18,
                  color: MyColor.bodyTextColor,
                ),
                const SizedBox(width: Dimensions.space5),
                Text(
                  '${MyStrings.passengerCount.tr}: ${reservation.passengerCount}',
                  style: regularDefault.copyWith(
                    color: MyColor.bodyTextColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceInfoCard(DriverReservationModel reservation) {
    final service = reservation.service;
    if (service == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.serviceDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                child: MyImageWidget(
                  imageUrl: '${UrlContainer.domainUrl}/assets/admin/images/service/${service.image}',
                  height: 50,
                  width: 50,
                ),
              ),
              const SizedBox(width: Dimensions.space15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name ?? '',
                      style: semiBoldLarge.copyWith(
                        color: MyColor.primaryTextColor,
                      ),
                    ),
                    if (service.subtitle != null && service.subtitle!.isNotEmpty)
                      Text(
                        service.subtitle ?? '',
                        style: regularDefault.copyWith(
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(DriverReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.locationDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MyColor.colorGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyStrings.pickUpLocation.tr,
                      style: regularSmall.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                    Text(
                      reservation.pickupLocation ?? '',
                      style: regularDefault.copyWith(
                        color: MyColor.primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MyColor.colorRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Dimensions.space10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MyStrings.destination.tr,
                      style: regularSmall.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                    Text(
                      reservation.destination ?? '',
                      style: regularDefault.copyWith(
                        color: MyColor.primaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(DriverReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.scheduleDetails.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space15),
          if (reservation.reservationDate != null && reservation.reservationDate!.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: MyColor.bodyTextColor,
                ),
                const SizedBox(width: Dimensions.space10),
                Text(
                  _formatDate(reservation.reservationDate ?? ''),
                  style: regularDefault.copyWith(
                    color: MyColor.primaryTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Dimensions.space10),
          ],
          if (reservation.schedules != null && reservation.schedules!.isNotEmpty) ...[
            Text(
              MyStrings.upcomingSchedules.tr,
              style: semiBoldDefault.copyWith(
                color: MyColor.primaryTextColor,
              ),
            ),
            const SizedBox(height: Dimensions.space10),
            ...reservation.schedules!.map((schedule) => Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.space8),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: MyColor.bodyTextColor,
                  ),
                  const SizedBox(width: Dimensions.space5),
                  Expanded(
                    child: Text(
                      _formatScheduleDateTime(schedule.scheduledDate, schedule.scheduledPickupTime, schedule.scheduledReturnTime),
                      style: regularSmall.copyWith(
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getScheduleStatusColor(schedule.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                    ),
                    child: Text(
                      _getScheduleStatusText(schedule.status),
                      style: regularExtraSmall.copyWith(
                        color: _getScheduleStatusColor(schedule.status),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialRequirementsCard(DriverReservationModel reservation) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.colorWhite,
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.colorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.specialRequirements.tr,
            style: semiBoldLarge.copyWith(color: MyColor.primaryTextColor),
          ),
          const SizedBox(height: Dimensions.space10),
          Text(
            reservation.specialRequirements ?? '',
            style: regularDefault.copyWith(
              color: MyColor.bodyTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleButton(DriverReservationModel reservation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MyColor.primaryColor.withOpacity(0.1),
            MyColor.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        border: Border.all(color: MyColor.primaryColor.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (reservation.id != null) {
              Get.toNamed('/reservation_weekly_schedule_screen', arguments: reservation.id);
            }
          },
          borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.space15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.space10),
                  decoration: BoxDecoration(
                    color: MyColor.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_view_week,
                    color: MyColor.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: Dimensions.space15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Weekly Schedule',
                        style: semiBoldDefault.copyWith(
                          color: MyColor.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'See all upcoming schedules for this recurring reservation',
                        style: regularSmall.copyWith(
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: MyColor.primaryColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatusText(int? status) {
    if (status == null) return 'UNKNOWN';
    switch (status) {
      case DriverReservationModel.STATUS_PENDING:
        return 'PENDING';
      case DriverReservationModel.STATUS_CONFIRMED:
        return 'CONFIRMED';
      case DriverReservationModel.STATUS_DRIVER_ASSIGNED:
        return 'ASSIGNED';
      case DriverReservationModel.STATUS_IN_PROGRESS:
        return 'IN PROGRESS';
      case DriverReservationModel.STATUS_COMPLETED:
        return 'COMPLETED';
      case DriverReservationModel.STATUS_CANCELLED:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  Color _getStatusColor(int? status) {
    if (status == null) return MyColor.bodyTextColor;
    switch (status) {
      case DriverReservationModel.STATUS_PENDING:
        return MyColor.pendingColor;
      case DriverReservationModel.STATUS_CONFIRMED:
      case DriverReservationModel.STATUS_DRIVER_ASSIGNED:
        return MyColor.greenSuccessColor;
      case DriverReservationModel.STATUS_CANCELLED:
        return MyColor.colorRed;
      case DriverReservationModel.STATUS_COMPLETED:
        return MyColor.informationColor;
      default:
        return MyColor.bodyTextColor;
    }
  }

  String _getScheduleStatusText(int? status) {
    if (status == null) return 'UNKNOWN';
    switch (status) {
      case ReservationScheduleModel.STATUS_PENDING:
        return 'PENDING';
      case ReservationScheduleModel.STATUS_RIDE_CREATED:
        return 'RIDE CREATED';
      case ReservationScheduleModel.STATUS_COMPLETED:
        return 'COMPLETED';
      case ReservationScheduleModel.STATUS_SKIPPED:
        return 'SKIPPED';
      case ReservationScheduleModel.STATUS_CANCELLED:
        return 'CANCELLED';
      default:
        return 'UNKNOWN';
    }
  }

  Color _getScheduleStatusColor(int? status) {
    if (status == null) return MyColor.bodyTextColor;
    switch (status) {
      case ReservationScheduleModel.STATUS_PENDING:
        return MyColor.pendingColor;
      case ReservationScheduleModel.STATUS_RIDE_CREATED:
        return MyColor.informationColor;
      case ReservationScheduleModel.STATUS_COMPLETED:
        return MyColor.greenSuccessColor;
      case ReservationScheduleModel.STATUS_SKIPPED:
        return MyColor.bodyTextColor;
      case ReservationScheduleModel.STATUS_CANCELLED:
        return MyColor.colorRed;
      default:
        return MyColor.bodyTextColor;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
  
  /// Format schedule date and time properly
  /// scheduledDate: YYYY-MM-DD (date only)
  /// scheduledPickupTime: HH:MM:SS (time only)
  /// scheduledReturnTime: HH:MM:SS (time only, optional)
  String _formatScheduleDateTime(String? scheduledDate, String? scheduledPickupTime, String? scheduledReturnTime) {
    try {
      if (scheduledDate == null || scheduledDate.isEmpty) {
        return 'No date';
      }
      
      // Parse date (YYYY-MM-DD format)
      final date = DateTime.parse(scheduledDate);
      final formattedDate = '${date.day}/${date.month}/${date.year}';
      
      // Format pickup time (HH:MM:SS → HH:MM)
      String formattedPickupTime = 'N/A';
      if (scheduledPickupTime != null && scheduledPickupTime.isNotEmpty) {
        final timeParts = scheduledPickupTime.split(':');
        if (timeParts.length >= 2) {
          formattedPickupTime = '${timeParts[0]}:${timeParts[1]}';
        }
      }
      
      // Format return time if present (HH:MM:SS → HH:MM)
      String result = '$formattedDate $formattedPickupTime';
      if (scheduledReturnTime != null && scheduledReturnTime.isNotEmpty) {
        final returnTimeParts = scheduledReturnTime.split(':');
        if (returnTimeParts.length >= 2) {
          final formattedReturnTime = '${returnTimeParts[0]}:${returnTimeParts[1]}';
          result += ' • $formattedReturnTime';
        }
      }
      
      return result;
    } catch (e) {
      print('Error formatting schedule datetime: $e');
      return '$scheduledDate $scheduledPickupTime';
    }
  }
}
