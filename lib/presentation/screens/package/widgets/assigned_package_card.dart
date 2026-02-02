import 'package:flutter/material.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/model/package/package_model.dart';

class AssignedPackageCard extends StatelessWidget {
  final UserPackageModel package;
  final VoidCallback onTap;

  const AssignedPackageCard({
    Key? key,
    required this.package,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final usagePercent = package.usagePercentage;
    final daysLeft = package.getDaysRemaining();
    
    return Card(
      margin: const EdgeInsets.only(bottom: Dimensions.space15),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with package name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      package.packageName ?? package.package?.name ?? 'Package',
                      style: boldLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(package.status ?? 0),
                ],
              ),
              
              const SizedBox(height: Dimensions.space10),
              
              // User info
              if (package.user != null && (package.user?.fullname ?? '').isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: MyColor.colorGrey),
                    const SizedBox(width: Dimensions.space5),
                    Expanded(
                      child: Text(
                        package.user?.fullname ?? 'N/A',
                        style: regularDefault,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.space5),
              ],
              
              // Rides info
              Row(
                children: [
                  Icon(Icons.directions_car, size: 18, color: MyColor.primaryColor),
                  const SizedBox(width: Dimensions.space5),
                  Text(
                    'Rides: ${package.usedRides}/${package.totalRides ?? 0}',
                    style: regularDefault,
                  ),
                  const SizedBox(width: Dimensions.space10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: usagePercent / 100,
                      backgroundColor: MyColor.colorGrey.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usagePercent > 80 ? MyColor.redCancelTextColor : MyColor.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.space5),
                  Text(
                    '${usagePercent.toStringAsFixed(0)}%',
                    style: regularSmall.copyWith(color: MyColor.colorGrey),
                  ),
                ],
              ),
              
              const SizedBox(height: Dimensions.space5),
              
              // Schedule indicator (NEW)
              if (package.hasWeeklySchedule) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: MyColor.greenSuccessColor),
                    const SizedBox(width: Dimensions.space5),
                    Text(
                      package.tripTypeName,
                      style: regularSmall.copyWith(color: MyColor.greenSuccessColor),
                    ),
                    if (package.selectedDaysString.isNotEmpty) ...[
                      const SizedBox(width: Dimensions.space5),
                      Text('•', style: regularSmall.copyWith(color: MyColor.colorGrey)),
                      const SizedBox(width: Dimensions.space5),
                      Expanded(
                        child: Text(
                          package.selectedDaysString,
                          style: regularSmall.copyWith(color: MyColor.colorGrey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: Dimensions.space5),
              ],
              
              // Footer with days and transaction
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: MyColor.colorGrey),
                      const SizedBox(width: Dimensions.space5),
                      Text(
                        '$daysLeft days left',
                        style: regularSmall.copyWith(
                          color: daysLeft <= 1 ? MyColor.redCancelTextColor : MyColor.colorGrey,
                        ),
                      ),
                    ],
                  ),
                  if (package.transactionId != null)
                    Text(
                      'ID: ${package.transactionId}',
                      style: regularSmall.copyWith(color: MyColor.colorGrey),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    String text;
    Color color;
    
    switch (status) {
      case 1:
        text = 'Active';
        color = MyColor.greenSuccessColor;
        break;
      case 2:
        text = 'Expired';
        color = MyColor.redCancelTextColor;
        break;
      case 3:
        text = 'Completed';
        color = MyColor.colorGrey;
        break;
      default:
        text = 'Cancelled';
        color = MyColor.colorOrange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space10,
        vertical: Dimensions.space5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: regularSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
