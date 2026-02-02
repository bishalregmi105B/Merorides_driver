import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/presentation/components/app-bar/custom_appbar.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:intl/intl.dart';

class PackageDetailsScreen extends StatefulWidget {
  final int packageId;
  
  const PackageDetailsScreen({Key? key, required this.packageId}) : super(key: key);

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<DriverPackageController>().loadPackageDetails(widget.packageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.screenBgColor,
      appBar: CustomAppBar(
        title: 'Package Details',
        bgColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverPackageController>(
        builder: (controller) {
          if (controller.isLoading) {
            return const Center(child: CustomLoader());
          }

          final package = controller.selectedUserPackage;
          if (package == null) {
            return const Center(child: Text('Package not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.space15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Header Card
                _buildHeaderCard(package),
                
                const SizedBox(height: Dimensions.space15),
                
                // Usage Progress Card
                _buildUsageCard(package),
                
                const SizedBox(height: Dimensions.space15),
                
                // User Information
                if (package.user != null) _buildUserInfoCard(package),
                
                const SizedBox(height: Dimensions.space15),
                
                // Package Details
                _buildDetailsCard(package),
                
                const SizedBox(height: Dimensions.space15),
                
                // Schedule Information (NEW)
                if (package.hasWeeklySchedule) _buildScheduleCard(package),
                
                const SizedBox(height: Dimensions.space15),
                
                // Services List
                if (package.package?.services != null && package.package!.services!.isNotEmpty)
                  _buildServicesCard(package),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(package) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Schedule Information', style: boldLarge),
                Icon(Icons.schedule, color: MyColor.primaryColor),
              ],
            ),
            const SizedBox(height: Dimensions.space15),
            
            _buildDetailRow(Icons.schedule_outlined, 'Trip Type', package.tripTypeName),
            
            if (package.selectedDaysString.isNotEmpty) ...[
              const Divider(height: Dimensions.space20),
              _buildDetailRow(Icons.calendar_month, 'Selected Days', package.selectedDaysString),
            ],
            
            if (package.selectedTimeSlotsString.isNotEmpty) ...[
              const Divider(height: Dimensions.space20),
              _buildDetailRow(Icons.access_time, 'Time Slots', package.selectedTimeSlotsString),
            ],
            
            if (package.scheduleStartDate != null) ...[
              const Divider(height: Dimensions.space20),
              _buildDetailRow(Icons.event_available, 'Schedule Start', 
                DateFormat('MMM dd, yyyy').format(DateTime.parse(package.scheduleStartDate!))),
            ],
            
            const SizedBox(height: Dimensions.space15),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed(RouteHelper.packageScheduleScreen, arguments: package.id);
                },
                icon: const Icon(Icons.calendar_view_week),
                label: const Text('View Full Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColor.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.space12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimensions.cardRadius),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(package) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.space15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [MyColor.primaryColor, MyColor.primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(Dimensions.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              package.packageName ?? package.package?.name ?? 'Package',
              style: boldExtraLarge.copyWith(color: Colors.white),
            ),
            if (package.packageDescription != null || package.package?.description != null) ...[
              const SizedBox(height: Dimensions.space5),
              Text(
                package.packageDescription ?? package.package?.description ?? '',
                style: regularDefault.copyWith(color: Colors.white.withValues(alpha: 0.9)),
              ),
            ],
            const SizedBox(height: Dimensions.space15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  Icons.calendar_today,
                  '${package.getDaysRemaining()} days left',
                  Colors.white,
                ),
                _buildStatusBadge(package.status ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(package) {
    final usagePercent = package.usagePercentage;
    final ridesRemaining = package.ridesRemaining ?? 0;
    
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
            Text('Rides Usage', style: boldLarge),
            const SizedBox(height: Dimensions.space15),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Total', '${package.totalRides ?? 0}', MyColor.primaryColor),
                _buildStatColumn('Used', '${package.usedRides}', MyColor.colorOrange),
                _buildStatColumn('Remaining', '$ridesRemaining', MyColor.greenSuccessColor),
              ],
            ),
            
            const SizedBox(height: Dimensions.space15),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: regularDefault),
                    Text(
                      '${usagePercent.toStringAsFixed(1)}%',
                      style: boldDefault.copyWith(color: MyColor.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.space5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: usagePercent / 100,
                    minHeight: 10,
                    backgroundColor: MyColor.colorGrey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usagePercent > 80 ? MyColor.redCancelTextColor : MyColor.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(package) {
    final user = package.user!;
    
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
            Text('Customer Information', style: boldLarge),
            const SizedBox(height: Dimensions.space15),
            
            _buildDetailRow(Icons.person, 'Name', user.fullname),
            const Divider(height: Dimensions.space20),
            _buildDetailRow(Icons.email, 'Email', user.email ?? 'N/A'),
            const Divider(height: Dimensions.space20),
            _buildDetailRow(Icons.phone, 'Mobile', user.mobile ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(package) {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    
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
            Text('Package Details', style: boldLarge),
            const SizedBox(height: Dimensions.space15),
            
            _buildDetailRow(Icons.confirmation_number, 'Transaction ID', package.transactionId ?? 'N/A'),
            const Divider(height: Dimensions.space20),
            if (Get.find<ApiClient>().isPaymentSystemEnabled())
              _buildDetailRow(Icons.attach_money, 'Amount Paid', '${Get.find<ApiClient>().getCurrency()}${package.price ?? package.amountPaid ?? '0'}'),
            if (Get.find<ApiClient>().isPaymentSystemEnabled())
              const Divider(height: Dimensions.space20),
            _buildDetailRow(
              Icons.shopping_cart, 
              'Purchased At',
              package.purchasedAt != null 
                ? dateFormat.format(DateTime.parse(package.purchasedAt!))
                : 'N/A'
            ),
            const Divider(height: Dimensions.space20),
            _buildDetailRow(
              Icons.event, 
              'Expires At',
              package.expiresAt != null 
                ? dateFormat.format(DateTime.parse(package.expiresAt!))
                : 'N/A'
            ),
            const Divider(height: Dimensions.space20),
            _buildDetailRow(
              Icons.people, 
              'Max Riders Per Ride',
              '${package.package?.maxRidersPerRide ?? 1}'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesCard(package) {
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
            Text('Included Services', style: boldLarge),
            const SizedBox(height: Dimensions.space10),
            
            Wrap(
              spacing: Dimensions.space10,
              runSpacing: Dimensions.space10,
              children: package.package!.services!.map<Widget>((service) {
                return Chip(
                  avatar: Icon(Icons.check_circle, color: MyColor.greenSuccessColor, size: 18),
                  label: Text(service.name ?? ''),
                  backgroundColor: MyColor.greenSuccessColor.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: boldExtraLarge.copyWith(color: color, fontSize: 28),
        ),
        const SizedBox(height: Dimensions.space5),
        Text(
          label,
          style: regularDefault.copyWith(color: MyColor.colorGrey),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Dimensions.space5),
        Text(text, style: regularDefault.copyWith(color: color)),
      ],
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
        color = Colors.white;
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
        color: status == 3 ? MyColor.colorGrey : color.withValues(alpha: 0.2),
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
