import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/data/model/package/package_model.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/buttons/rounded_button.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';

class PackageRideConfirmationScreen extends StatelessWidget {
  final PackageRideModel packageRide;
  final int packageRideId;

  const PackageRideConfirmationScreen({
    Key? key,
    required this.packageRide,
    required this.packageRideId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Confirm Package Ride',
        bgColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverPackageController>(
        builder: (controller) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.space15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Information Card
                _buildRideInfoCard(),
                
                const SizedBox(height: Dimensions.space15),
                
                // Confirmation Status Card
                _buildConfirmationStatusCard(),
                
                const SizedBox(height: Dimensions.space15),
                
                // Location Information
                _buildLocationCard(),
                
                const SizedBox(height: Dimensions.space30),
                
                // Confirmation Message
                if (packageRide.driverConfirmed == 0)
                  _buildConfirmationMessage(),
                
                const SizedBox(height: Dimensions.space20),
                
                // Confirm Button
                if (packageRide.driverConfirmed == 0)
                  controller.isLoading
                      ? const Center(child: CustomLoader())
                      : RoundedButton(
                          text: 'Confirm Ride Completion',
                          press: () {
                            _showConfirmationDialog(context, controller);
                          },
                          bgColor: MyColor.primaryColor,
                        ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRideInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ride Information', style: boldLarge),
            const SizedBox(height: Dimensions.space15),
            
            _buildInfoRow(Icons.confirmation_number, 'Ride Number', '#${packageRide.rideNumber}'),
            const Divider(height: Dimensions.space20),
            _buildInfoRow(Icons.event, 'Started At', packageRide.startedAt ?? 'N/A'),
            const Divider(height: Dimensions.space20),
            _buildInfoRow(Icons.event_available, 'Completed At', packageRide.completedAt ?? 'N/A'),
            const Divider(height: Dimensions.space20),
            _buildInfoRow(Icons.info, 'Status', packageRide.statusText),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirmation Status', style: boldLarge),
            const SizedBox(height: Dimensions.space15),
            
            Row(
              children: [
                Expanded(
                  child: _buildConfirmationBadge(
                    'Rider',
                    packageRide.riderConfirmed == 1,
                  ),
                ),
                const SizedBox(width: Dimensions.space10),
                Expanded(
                  child: _buildConfirmationBadge(
                    'Driver (You)',
                    packageRide.driverConfirmed == 1,
                  ),
                ),
              ],
            ),
            
            if (packageRide.isBothConfirmed) ...[
              const SizedBox(height: Dimensions.space15),
              Container(
                padding: const EdgeInsets.all(Dimensions.space10),
                decoration: BoxDecoration(
                  color: MyColor.greenSuccessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                  border: Border.all(color: MyColor.greenSuccessColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: MyColor.greenSuccessColor),
                    const SizedBox(width: Dimensions.space10),
                    Expanded(
                      child: Text(
                        'Both parties have confirmed this ride!',
                        style: regularDefault.copyWith(
                          color: MyColor.greenSuccessColor,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildConfirmationBadge(String title, bool confirmed) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.space10,
        horizontal: Dimensions.space10,
      ),
      decoration: BoxDecoration(
        color: confirmed 
            ? MyColor.greenSuccessColor.withOpacity(0.1)
            : MyColor.colorGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        border: Border.all(
          color: confirmed ? MyColor.greenSuccessColor : MyColor.colorGrey,
        ),
      ),
      child: Column(
        children: [
          Icon(
            confirmed ? Icons.check_circle : Icons.pending,
            color: confirmed ? MyColor.greenSuccessColor : MyColor.colorGrey,
            size: 32,
          ),
          const SizedBox(height: Dimensions.space5),
          Text(
            title,
            style: regularDefault.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.space3),
          Text(
            confirmed ? 'Confirmed' : 'Pending',
            style: regularSmall.copyWith(
              color: confirmed ? MyColor.greenSuccessColor : MyColor.colorGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.space15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Route Information', style: boldLarge),
            const SizedBox(height: Dimensions.space15),
            
            _buildInfoRow(
              Icons.location_on,
              'Pickup',
              packageRide.pickupLocation ?? 'N/A',
            ),
            const Divider(height: Dimensions.space20),
            _buildInfoRow(
              Icons.flag,
              'Destination',
              packageRide.destination ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationMessage() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.space15),
      decoration: BoxDecoration(
        color: MyColor.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        border: Border.all(color: MyColor.primaryColor),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: MyColor.primaryColor, size: 40),
          const SizedBox(height: Dimensions.space10),
          Text(
            'Please confirm that this ride has been completed successfully',
            style: regularDefault.copyWith(
              color: MyColor.primaryColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (packageRide.riderConfirmed == 1) ...[
            const SizedBox(height: Dimensions.space10),
            Text(
              'The rider has already confirmed. Waiting for your confirmation.',
              style: regularSmall.copyWith(color: MyColor.colorGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: MyColor.primaryColor),
        const SizedBox(width: Dimensions.space10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: regularSmall.copyWith(color: MyColor.colorGrey)),
              const SizedBox(height: Dimensions.space3),
              Text(value, style: regularDefault),
            ],
          ),
        ),
      ],
    );
  }

  void _showConfirmationDialog(BuildContext context, DriverPackageController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Ride Completion'),
        content: const Text(
          'Are you sure you want to confirm this package ride as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: MyColor.colorGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.confirmPackageRide(packageRideId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColor.primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
