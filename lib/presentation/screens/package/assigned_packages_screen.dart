import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_strings.dart';
import 'package:ovoride_driver/data/controller/package/driver_package_controller.dart';
import 'package:ovoride_driver/data/model/package/package_model.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/no_data.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/data/services/local_storage_service.dart';

class AssignedPackagesScreen extends StatefulWidget {
  const AssignedPackagesScreen({Key? key}) : super(key: key);

  @override
  State<AssignedPackagesScreen> createState() => _AssignedPackagesScreenState();
}

class _AssignedPackagesScreenState extends State<AssignedPackagesScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<DriverPackageController>().loadAssignedPackages();
    Get.find<DriverPackageController>().loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(MyStrings.assignedPackages.tr),
        backgroundColor: MyColor.primaryColor,
      ),
      body: GetBuilder<DriverPackageController>(
        builder: (controller) {
          return Column(
            children: [
              // Statistics Card
              if (controller.statistics != null)
                Container(
                  margin: EdgeInsets.all(Dimensions.space15),
                  padding: EdgeInsets.all(Dimensions.space15),
                  decoration: BoxDecoration(
                    color: MyColor.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        MyStrings.total.tr,
                        controller.statistics!.totalAssigned.toString(),
                        Icons.assignment,
                      ),
                      _buildStatItem(
                        MyStrings.active.tr,
                        controller.statistics!.activePackages.toString(),
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      _buildStatItem(
                        MyStrings.completed.tr,
                        controller.statistics!.completedPackages.toString(),
                        Icons.done_all,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),

              // Package List
              Expanded(
                child: controller.isLoading
                    ? const CustomLoader()
                    : controller.assignedPackages.isEmpty
                        ? const NoDataWidget()
                        : RefreshIndicator(
                            onRefresh: () async {
                              await controller.loadAssignedPackages();
                              await controller.loadStatistics();
                            },
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: Dimensions.space15),
                              itemCount: controller.assignedPackages.length,
                              itemBuilder: (context, index) {
                                final userPackage = controller.assignedPackages[index];
                                return _buildPackageCard(userPackage, controller);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? MyColor.primaryColor, size: 30),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? MyColor.primaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildPackageCard(UserPackageModel userPackage, DriverPackageController controller) {
    return Card(
      margin: EdgeInsets.only(bottom: Dimensions.space15),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPackageDetails(userPackage, controller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: userPackage.user?.image != null
                        ? NetworkImage('${controller.userImagePath}/${userPackage.user!.image}')
                        : null,
                    child: userPackage.user?.image == null
                        ? Icon(Icons.person)
                        : null,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userPackage.user?.fullname ?? '',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userPackage.package?.name ?? '',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(userPackage.status!),
                ],
              ),
              SizedBox(height: 12),

              // Rides Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${MyStrings.rides.tr}: ${userPackage.remainingRides}/${userPackage.totalRides}',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${userPackage.usagePercentage.toStringAsFixed(0)}% ${MyStrings.completed.tr}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: userPackage.usagePercentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      userPackage.status == 1 ? MyColor.primaryColor : Colors.grey,
                    ),
                    minHeight: 8,
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Expiry and Contact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        '${userPackage.daysRemaining} ${MyStrings.daysLeft.tr}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (userPackage.user?.mobile != null)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 6),
                        Text(
                          userPackage.user!.mobile!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
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
    Color color;
    String text;

    switch (status) {
      case 1: // Active
        color = Colors.green;
        text = MyStrings.active.tr;
        break;
      case 2: // Expired
        color = Colors.red;
        text = MyStrings.expired.tr;
        break;
      case 3: // Completed
        color = Colors.blue;
        text = MyStrings.completed.tr;
        break;
      case 0: // Cancelled
        color = Colors.grey;
        text = MyStrings.cancelled.tr;
        break;
      default:
        color = Colors.grey;
        text = MyStrings.unknown.tr;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showPackageDetails(UserPackageModel userPackage, DriverPackageController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(Dimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // User Info
                ListTile(
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: userPackage.user?.image != null
                        ? NetworkImage('${controller.userImagePath}/${userPackage.user!.image}')
                        : null,
                    child: userPackage.user?.image == null ? Icon(Icons.person, size: 30) : null,
                  ),
                  title: Text(
                    userPackage.user?.fullname ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userPackage.user?.email ?? ''),
                      Text(userPackage.user?.mobile ?? ''),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Package Info
                Text(
                  userPackage.package?.name ?? '',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text(
                  userPackage.package?.description ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),

                SizedBox(height: 20),

                // Usage Summary
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: MyColor.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(MyStrings.totalRides.tr, userPackage.totalRides.toString()),
                      Divider(),
                      _buildSummaryRow(MyStrings.remainingRides.tr, userPackage.remainingRides.toString()),
                      Divider(),
                      _buildSummaryRow(MyStrings.completedRides.tr, userPackage.usedRides.toString()),
                      Divider(),
                      _buildSummaryRow(MyStrings.progress.tr, '${userPackage.usagePercentage.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Details
                if (Get.find<LocalStorageService>().canShowPrices())
                  _buildDetailRow(Icons.attach_money, MyStrings.amount.tr, '${Get.find<ApiClient>().getCurrency()}${userPackage.amountPaid ?? '0'}'),
                _buildDetailRow(Icons.calendar_today, MyStrings.purchasedOn.tr, _formatDate(userPackage.purchasedAt)),
                _buildDetailRow(Icons.event_available, MyStrings.expiresOn.tr, _formatDate(userPackage.expiresAt)),
                _buildDetailRow(Icons.access_time, MyStrings.daysRemaining.tr, userPackage.daysRemaining.toString()),

                // Services
                if (userPackage.package?.services != null) ...[
                  SizedBox(height: 20),
                  Text(
                    MyStrings.includedServices.tr,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ...userPackage.package!.services!.map((service) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage('${controller.serviceImagePath}/${service.image}'),
                        ),
                        title: Text(service.name ?? ''),
                        subtitle: Text(service.subtitle ?? ''),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: MyColor.primaryColor, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
