import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';
import 'package:ovoride_driver/data/model/reservation/driver_reservation_model.dart';
import 'package:ovoride_driver/data/controller/reservation/driver_reservation_controller.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';
import 'package:ovoride_driver/presentation/components/image/my_network_image_widget.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';

class DriverReservationCard extends StatelessWidget {
  final DriverReservationModel reservation;
  final String serviceImagePath;
  final String userImagePath;

  const DriverReservationCard({
    super.key,
    required this.reservation,
    required this.serviceImagePath,
    required this.userImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          RouteHelper.reservationDetailScreen,
          arguments: reservation.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.space12),
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
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reservation Code & Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.reservationCode ?? '',
                        style: semiBoldDefault.copyWith(
                          fontSize: 16,
                          color: MyColor.primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              reservation.statusText,
                              style: regularSmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                          if (reservation.isRecurring) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: MyColor.colorPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sync,
                                    size: 12,
                                    color: MyColor.colorPurple,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    MyStrings.recurring.tr,
                                    style: regularSmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: MyColor.colorPurple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Buttons for Driver
                if (reservation.canAcceptRide()) ...[
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          _showAcceptDialog(context);
                        },
                        icon: Icon(
                          Icons.check_circle,
                          color: MyColor.greenSuccessColor,
                        ),
                        tooltip: MyStrings.accept.tr,
                      ),
                      IconButton(
                        onPressed: () {
                          _showRejectDialog(context);
                        },
                        icon: Icon(
                          Icons.cancel,
                          color: MyColor.redCancelTextColor,
                        ),
                        tooltip: MyStrings.reject.tr,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: Dimensions.space12),
            const Divider(height: 1),
            const SizedBox(height: Dimensions.space12),

            // User Info
            if (reservation.user != null) ...[
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MyColor.borderColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: reservation.user!.image != null
                          ? MyImageWidget(
                              imageUrl: "${UrlContainer.domainUrl}/$userImagePath${reservation.user!.image}",
                              height: 32,
                              width: 32,
                              boxFit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.person,
                              size: 20,
                              color: MyColor.bodyTextColor,
                            ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.user!.fullname,
                          style: semiBoldDefault.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        if (reservation.contactNumber != null)
                          Text(
                            reservation.contactNumber!,
                            style: regularSmall.copyWith(
                              color: MyColor.bodyTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.space12),
            ],

            // Date & Time Info
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: MyColor.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _getDateText(),
                  style: regularDefault.copyWith(
                    fontSize: 13,
                    color: MyColor.primaryTextColor,
                  ),
                ),
                const SizedBox(width: Dimensions.space15),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: MyColor.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  reservation.getPickupTimeString() ?? '',
                  style: regularDefault.copyWith(
                    fontSize: 13,
                    color: MyColor.primaryTextColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dimensions.space12),

            // Location Info
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MyColor.greenSuccessColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: MyColor.borderColor,
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: MyColor.redCancelTextColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.pickupLocation ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: regularDefault.copyWith(
                          fontSize: 13,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        reservation.destination ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: regularDefault.copyWith(
                          fontSize: 13,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: Dimensions.space12),
            const Divider(height: 1),
            const SizedBox(height: Dimensions.space12),

            // Bottom Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Service Info
                if (reservation.service != null) ...[
                  Row(
                    children: [
                      if (reservation.service!.image != null)
                        MyImageWidget(
                          imageUrl: "${UrlContainer.domainUrl}/$serviceImagePath${reservation.service!.image}",
                          height: 24,
                          width: 24,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        reservation.service!.name ?? '',
                        style: regularDefault.copyWith(
                          fontSize: 12,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
                // Estimated Amount - only show if prices can be shown
                if (reservation.estimatedAmount != null && 
                    Get.find<LocalStorageService>().canShowPrices())
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        MyStrings.estimatedFare.tr,
                        style: regularSmall.copyWith(
                          fontSize: 10,
                          color: MyColor.bodyTextColor,
                        ),
                      ),
                      Text(
                        '\$${reservation.estimatedAmount}',
                        style: semiBoldDefault.copyWith(
                          fontSize: 16,
                          color: MyColor.primaryColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Additional Info for Recurring
            if (reservation.isRecurring) ...[
              const SizedBox(height: Dimensions.space10),
              Container(
                padding: const EdgeInsets.all(Dimensions.space8),
                decoration: BoxDecoration(
                  color: MyColor.screenBgColor,
                  borderRadius: BorderRadius.circular(Dimensions.defaultRadius / 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: MyColor.bodyTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          reservation.recurringDaysText,
                          style: regularSmall.copyWith(
                            fontSize: 11,
                            color: MyColor.bodyTextColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${reservation.completedSchedules ?? reservation.completedOccurrences ?? 0}/${reservation.totalSchedules ?? reservation.totalOccurrences ?? 0} ${MyStrings.completed.tr}',
                      style: regularSmall.copyWith(
                        fontSize: 11,
                        color: MyColor.bodyTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (reservation.status) {
      case DriverReservationModel.STATUS_PENDING:
        return MyColor.colorYellow;
      case DriverReservationModel.STATUS_CONFIRMED:
        return MyColor.primaryColor;
      case DriverReservationModel.STATUS_DRIVER_ASSIGNED:
        return MyColor.colorPurple;
      case DriverReservationModel.STATUS_IN_PROGRESS:
        return MyColor.primaryColor;
      case DriverReservationModel.STATUS_COMPLETED:
        return MyColor.greenSuccessColor;
      case DriverReservationModel.STATUS_CANCELLED:
        return MyColor.redCancelTextColor;
      default:
        return MyColor.bodyTextColor;
    }
  }

  String _getDateText() {
    if (reservation.isRecurring) {
      final startDate = reservation.recurringStartDate ?? '';
      final endDate = reservation.recurringEndDate ?? '';
      if (startDate.isNotEmpty && endDate.isNotEmpty) {
        return '${_formatShortDate(startDate)} - ${_formatShortDate(endDate)}';
      }
    }
    return _formatDate(reservation.reservationDate ?? '');
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatShortDate(String date) {
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    } catch (e) {
      return date;
    }
  }

  void _showAcceptDialog(BuildContext context) {
    // Check if there's a pending ride to accept
    if (reservation.pendingRideId == null) {
      CustomSnackBar.error(errorList: ['No pending ride to accept']);
      return;
    }
    
    Get.dialog(
      AlertDialog(
        title: Text(MyStrings.acceptReservation.tr),
        content: Text(MyStrings.confirmAcceptReservation.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(MyStrings.cancel.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Pass the pending ride ID, not the reservation ID
              Get.find<DriverReservationController>().acceptReservationRide(reservation.pendingRideId!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.greenSuccessColor,
            ),
            child: Text(MyStrings.accept.tr),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    // Check if there's a pending ride to reject
    if (reservation.pendingRideId == null) {
      CustomSnackBar.error(errorList: ['No pending ride to reject']);
      return;
    }
    
    final reasonController = TextEditingController();
    
    Get.dialog(
      AlertDialog(
        title: Text(MyStrings.rejectReservation.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(MyStrings.provideRejectionReason.tr),
            const SizedBox(height: Dimensions.space15),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: MyStrings.reason.tr,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(MyStrings.cancel.tr),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Get.back();
                // Pass the pending ride ID, not the reservation ID
                Get.find<DriverReservationController>().rejectReservationRide(
                  reservation.pendingRideId!,
                  reasonController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.redCancelTextColor,
            ),
            child: Text(MyStrings.reject.tr),
          ),
        ],
      ),
    );
  }
}
