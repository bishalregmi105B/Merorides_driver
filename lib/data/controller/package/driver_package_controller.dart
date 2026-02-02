import 'package:get/get.dart';

import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/data/model/package/package_model.dart';
import 'package:ovoride_driver/data/repo/package/driver_package_repo.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';

class DriverPackageController extends GetxController {
  DriverPackageRepo driverPackageRepo;
  DriverPackageController({required this.driverPackageRepo});

  bool hasLoadedInitialData = false;
  bool isLoadingStatistics = false;
  bool isLoadingAssignedPackages = false;
  
  // Computed property for overall loading state
  bool get isLoading => isLoadingStatistics || isLoadingAssignedPackages;
  List<UserPackageModel> assignedPackages = [];
  List<UserPackageModel> activePackages = [];
  UserPackageModel? selectedUserPackage;
  List<UserPackageScheduleModel> packageSchedules = [];
  Map<int, List<dynamic>> weeklySchedule = {};
  List<dynamic> todaySchedules = [];
  
  PackageStatistics? statistics;
  
  String packageImagePath = '';
  String serviceImagePath = '';
  String userImagePath = '';

  // Load initial data (called when tab is selected)
  void loadInitialData() {
    if (!hasLoadedInitialData) {
      hasLoadedInitialData = true;
      printX('🎯 DriverPackageController: Loading initial data');
      loadStatistics();
      loadAssignedPackages();
    }
  }

  @override
  void onInit() {
    super.onInit();
  }

  // Get assigned packages
  Future<void> loadAssignedPackages() async {
    printX('📦 Starting loadAssignedPackages...');
    isLoadingAssignedPackages = true;
    update();

    try {
      printX('📦 Calling API: getAssignedPackages');
      var response = await driverPackageRepo.getAssignedPackages();
      printX('📦 API Response StatusCode: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        userImagePath = data['data']['user_image_path'] ?? '';
        
        if (data['data']['packages'] != null) {
          assignedPackages.clear();
          data['data']['packages'].forEach((package) {
            assignedPackages.add(UserPackageModel.fromJson(package));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('❌ Error loading assigned packages: $e');
      printX('❌ Stack trace: ${StackTrace.current}');
      CustomSnackBar.error(errorList: ['Failed to load assigned packages']);
    } finally {
      isLoadingAssignedPackages = false;
      update();
    }
  }

  // Get active packages (for driver, active packages are assigned packages)
  Future<void> loadActivePackages() async {
    await loadAssignedPackages();
    activePackages = List.from(assignedPackages);
  }

  // Get statistics
  Future<void> loadStatistics() async {
    printX('📊 Starting loadStatistics...');
    isLoadingStatistics = true;
    update();
    
    try {
      printX('📊 Calling API: getStatistics');
      var response = await driverPackageRepo.getStatistics();
      printX('📊 API Response StatusCode: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        var data = response.responseJson['data'];
        statistics = PackageStatistics.fromJson(data);
      }
    } catch (e) {
      printX('❌ Error loading statistics: $e');
      printX('❌ Stack trace: ${StackTrace.current}');
    } finally {
      isLoadingStatistics = false;
      update();
    }
  }

  // Get package details
  Future<void> loadPackageDetails(int packageId) async {
    isLoadingAssignedPackages = true;
    update();

    try {
      var response = await driverPackageRepo.getPackageDetails(packageId);
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        userImagePath = data['data']['user_image_path'] ?? '';
        
        if (data['data']['user_package'] != null) {
          selectedUserPackage = UserPackageModel.fromJson(data['data']['user_package']);
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading package details: $e');
      CustomSnackBar.error(errorList: ['Failed to load package details']);
    } finally {
      isLoadingAssignedPackages = false;
      update();
    }
  }

  // Confirm package ride completion
  Future<void> confirmPackageRide(int packageRideId) async {
    isLoadingAssignedPackages = true;
    update();

    try {
      var response = await driverPackageRepo.confirmPackageRide(packageRideId);
      
      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message]);
        // Reload data to reflect changes
        await loadAssignedPackages();
        await loadStatistics();
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error confirming package ride: $e');
      CustomSnackBar.error(errorList: ['Failed to confirm package ride']);
    } finally {
      isLoadingAssignedPackages = false;
      update();
    }
  }

  // Get pending confirmations
  List<PackageRideModel> pendingConfirmations = [];
  
  Future<void> loadPendingConfirmations() async {
    try {
      var response = await driverPackageRepo.getPendingConfirmations();
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        pendingConfirmations.clear();
        
        if (data['data']['pending_rides'] != null) {
          data['data']['pending_rides'].forEach((ride) {
            pendingConfirmations.add(PackageRideModel.fromJson(ride));
          });
        }
      }
    } catch (e) {
      printX('Error loading pending confirmations: $e');
    }
    update();
  }

  // Get package schedule details
  Future<void> loadPackageSchedule(int userPackageId) async {
    isLoadingAssignedPackages = true;
    update();

    try {
      var response = await driverPackageRepo.getPackageSchedule(userPackageId);
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        userImagePath = data['data']['user_image_path'] ?? '';
        
        if (data['data']['user_package'] != null) {
          selectedUserPackage = UserPackageModel.fromJson(data['data']['user_package']);
        }

        if (data['data']['schedules'] != null) {
          packageSchedules.clear();
          data['data']['schedules'].forEach((schedule) {
            // Parse grouped schedule data
            if (schedule['morning'] != null) {
              packageSchedules.add(UserPackageScheduleModel.fromJson(schedule['morning']));
            }
            if (schedule['evening'] != null) {
              packageSchedules.add(UserPackageScheduleModel.fromJson(schedule['evening']));
            }
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading package schedule: $e');
      CustomSnackBar.error(errorList: ['Failed to load package schedule']);
    } finally {
      isLoadingAssignedPackages = false;
      update();
    }
  }

  // Get today's schedules
  Future<void> loadTodaySchedules() async {
    try {
      var response = await driverPackageRepo.getTodaySchedules();
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['schedules'] != null) {
          todaySchedules = data['data']['schedules'];
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading today schedules: $e');
      CustomSnackBar.error(errorList: ['Failed to load today\'s schedules']);
    }
    update();
  }

  // Get weekly schedule overview
  Future<void> loadWeeklySchedule() async {
    isLoadingAssignedPackages = true;
    update();

    try {
      var response = await driverPackageRepo.getWeeklySchedule();
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['weekly_schedule'] != null) {
          weeklySchedule.clear();
          List<dynamic> scheduleList = data['data']['weekly_schedule'];
          
          for (var daySchedule in scheduleList) {
            int dayOfWeek = daySchedule['day_of_week'];
            weeklySchedule[dayOfWeek] = [
              daySchedule['morning_schedules'] ?? [],
              daySchedule['evening_schedules'] ?? [],
            ];
          }
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading weekly schedule: $e');
      CustomSnackBar.error(errorList: ['Failed to load weekly schedule']);
    } finally {
      isLoadingAssignedPackages = false;
      update();
    }
  }

  // Get active packages using new endpoint
  Future<void> loadActivePackagesOnly() async {
    isLoadingAssignedPackages = true;
    update();

    try {
      var response = await driverPackageRepo.getActivePackages();
      
      if (response.statusCode == 200) {
        var data = response.responseJson;
        packageImagePath = data['data']['package_image_path'] ?? '';
        serviceImagePath = data['data']['service_image_path'] ?? '';
        userImagePath = data['data']['user_image_path'] ?? '';
        
        if (data['data']['packages'] != null) {
          activePackages.clear();
          data['data']['packages'].forEach((package) {
            activePackages.add(UserPackageModel.fromJson(package));
          });
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading active packages: $e');
      CustomSnackBar.error(errorList: ['Failed to load active packages']);
    } finally {
      isLoadingAssignedPackages = false;
      update();
    }
  }

  void clearData() {
    assignedPackages.clear();
    activePackages.clear();
    selectedUserPackage = null;
    packageSchedules.clear();
    weeklySchedule.clear();
    todaySchedules.clear();
    statistics = null;
    pendingConfirmations.clear();
    update();
  }
}
