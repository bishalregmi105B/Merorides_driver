import 'package:flutter/material.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/presentation/components/divider/custom_spacer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PackageRideCard extends StatelessWidget {
  final Map<String, dynamic> packageRide;
  final String userImagePath;
  final VoidCallback? onTap;

  const PackageRideCard({
    Key? key,
    required this.packageRide,
    required this.userImagePath,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasActiveRide = packageRide['has_active_ride'] == true;
    final int? rideStatus = hasActiveRide ? packageRide['ride_status'] : packageRide['status'];
    final String rideStatusText = packageRide['ride_status_text'] ?? 'Not Started';
    
    return GestureDetector(
      onTap: hasActiveRide ? onTap : null, // Only clickable if ride is active
      child: Container(
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          color: MyColor.colorWhite,
          borderRadius: BorderRadius.circular(Dimensions.defaultRadius),
          boxShadow: [
            BoxShadow(
              color: MyColor.colorGrey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Package Header
            Row(
              children: [
                Icon(
                  Icons.card_travel,
                  color: MyColor.primaryColor,
                  size: 24,
                ),
                spaceSide(Dimensions.space10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageRide['package_name'] ?? 'Package Ride',
                        style: semiBoldLarge.copyWith(
                          color: MyColor.colorBlack,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        packageRide['trip_type_name'] ?? '',
                        style: regularSmall.copyWith(
                          color: MyColor.colorGrey2,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(
                  rideStatus,
                  hasActiveRide,
                  rideStatusText,
                ),
              ],
            ),
            
            spaceDown(Dimensions.space15),
            Divider(height: 1, color: MyColor.borderColor),
            spaceDown(Dimensions.space15),

            // User Info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: MyColor.primaryColor.withOpacity(0.1),
                  backgroundImage: packageRide['user_image'] != null && packageRide['user_image'].toString().isNotEmpty
                      ? CachedNetworkImageProvider('$userImagePath/${packageRide['user_image']}')
                      : null,
                  child: packageRide['user_image'] == null || packageRide['user_image'].toString().isEmpty
                      ? Icon(Icons.person, color: MyColor.primaryColor)
                      : null,
                ),
                spaceSide(Dimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        packageRide['user_name'] ?? 'User',
                        style: semiBoldDefault.copyWith(
                          color: MyColor.colorBlack,
                        ),
                      ),
                      Text(
                        packageRide['user_mobile'] ?? '',
                        style: regularSmall.copyWith(
                          color: MyColor.colorGrey2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            spaceDown(Dimensions.space15),

            // Schedule Info
            Container(
              padding: const EdgeInsets.all(Dimensions.space12),
              decoration: BoxDecoration(
                color: MyColor.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                border: Border.all(color: MyColor.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: MyColor.primaryColor),
                  spaceSide(Dimensions.space8),
                  Text(
                    '${packageRide['day_name']} - ${packageRide['time_slot']}',
                    style: semiBoldDefault.copyWith(color: MyColor.primaryColor),
                  ),
                  spaceSide(Dimensions.space12),
                  Icon(Icons.access_time, size: 16, color: MyColor.primaryColor),
                  spaceSide(Dimensions.space8),
                  Text(
                    packageRide['pickup_time'] ?? '',
                    style: semiBoldDefault.copyWith(color: MyColor.primaryColor),
                  ),
                ],
              ),
            ),

            spaceDown(Dimensions.space12),

            // Locations
            _buildLocationRow(
              Icons.trip_origin,
              packageRide['pickup_location'] ?? 'Pickup Location',
              MyColor.greenP,
            ),
            spaceDown(Dimensions.space8),
            _buildLocationRow(
              Icons.location_on,
              packageRide['drop_location'] ?? 'Drop Location',
              MyColor.colorRed,
            ),

            spaceDown(Dimensions.space12),

            // Remaining Rides Info
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.space12,
                vertical: Dimensions.space8,
              ),
              decoration: BoxDecoration(
                color: MyColor.colorOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.repeat, size: 16, color: MyColor.colorOrange),
                  spaceSide(Dimensions.space8),
                  Text(
                    'Remaining: ${packageRide['remaining_rides']}/${packageRide['total_rides']} rides',
                    style: regularSmall.copyWith(
                      color: MyColor.colorOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        spaceSide(Dimensions.space8),
        Expanded(
          child: Text(
            text,
            style: regularDefault.copyWith(
              color: MyColor.colorBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int? status, bool hasActiveRide, String? rideStatusText) {
    String statusText;
    Color statusColor;

    if (hasActiveRide && rideStatusText != null) {
      // Show ride status
      statusText = rideStatusText;
      switch (status) {
        case 2: // RIDE_ACTIVE
          statusColor = MyColor.colorOrange;
          break;
        case 3: // RIDE_RUNNING
          statusColor = MyColor.primaryColor;
          break;
        case 4: // RIDE_END
          statusColor = MyColor.colorOrange;
          break;
        case 5: // RIDE_COMPLETED
          statusColor = MyColor.greenP;
          break;
        case 6: // RIDE_CANCELED
          statusColor = MyColor.colorRed;
          break;
        default:
          statusColor = MyColor.colorGrey2;
      }
    } else {
      // Show schedule status
      switch (status) {
        case 0:
          statusText = 'Not Started';
          statusColor = MyColor.colorGrey2;
          break;
        case 1:
          statusText = 'In Progress';
          statusColor = MyColor.primaryColor;
          break;
        case 2:
          statusText = 'Completed';
          statusColor = MyColor.greenP;
          break;
        default:
          statusText = 'Unknown';
          statusColor = MyColor.colorGrey2;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space10,
        vertical: Dimensions.space5,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: regularSmall.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
