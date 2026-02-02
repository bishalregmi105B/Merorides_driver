import 'package:flutter/material.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:get/get.dart';

class ReservationStatisticsCard extends StatelessWidget {
  final int totalReservations;
  final int activeReservations;
  final int todayReservations;
  final int upcomingReservations;

  const ReservationStatisticsCard({
    Key? key,
    required this.totalReservations,
    required this.activeReservations,
    required this.todayReservations,
    required this.upcomingReservations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MyColor.primaryColor,
            MyColor.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
        boxShadow: [
          BoxShadow(
            color: MyColor.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            MyStrings.reservationOverview.tr,
            style: semiBoldLarge.copyWith(
              color: MyColor.colorWhite,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: Dimensions.space15),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_view_month,
                  label: MyStrings.total.tr,
                  value: totalReservations.toString(),
                  iconColor: MyColor.colorWhite.withOpacity(0.9),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_outline,
                  label: MyStrings.active.tr,
                  value: activeReservations.toString(),
                  iconColor: MyColor.greenSuccessColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.space12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.today,
                  label: MyStrings.today.tr,
                  value: todayReservations.toString(),
                  iconColor: MyColor.colorYellow.withOpacity(0.9),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.upcoming,
                  label: MyStrings.upcoming.tr,
                  value: upcomingReservations.toString(),
                  iconColor: MyColor.informationColor.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space10),
      decoration: BoxDecoration(
        color: MyColor.colorWhite.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.defaultRadius / 2),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: Dimensions.space10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: boldLarge.copyWith(
                  color: MyColor.colorWhite,
                  fontSize: 20,
                ),
              ),
              Text(
                label,
                style: regularSmall.copyWith(
                  color: MyColor.colorWhite.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
