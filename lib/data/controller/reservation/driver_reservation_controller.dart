import 'package:get/get.dart';
import 'package:ovoride_driver/data/model/reservation/driver_reservation_model.dart';
import 'package:ovoride_driver/data/repo/reservation/driver_reservation_repo.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';

class DriverReservationController extends GetxController {
  DriverReservationRepo driverReservationRepo;
  DriverReservationController({required this.driverReservationRepo});

  bool isLoading = false;
  List<DriverReservationModel> assignedReservations = [];
  List<DriverReservationModel> upcomingReservations = [];
  List<DriverReservationModel> todayReservations = [];
  List<DriverReservationModel> completedReservations = [];
  DriverReservationModel? selectedReservation;
  List<ReservationScheduleModel> reservationSchedules = [];
  Map<String, dynamic>? reservationStats;
  
  String serviceImagePath = '';
  String userImagePath = '';
  bool hasLoadedInitialData = false;
  
  // Track individual data loading states
  bool hasTodayData = false;
  bool hasUpcomingData = false;
  bool hasHistoryData = false;

  @override
  void onInit() {
    super.onInit();
  }

  // Load initial data when screen is opened
  Future<void> loadInitialData({bool forceRefresh = false}) async {
    if (hasLoadedInitialData && !forceRefresh) return;
    
    isLoading = true;
    update();
    
    try {
      await Future.wait([
        loadAssignedReservations(skipLoadingState: true),
        loadTodayReservations(skipLoadingState: true),
        loadReservationStats(skipLoadingState: true),
      ]);
      
      hasLoadedInitialData = true;
    } finally {
      isLoading = false;
      update();
    }
  }
  
  // Refresh all data (for pull-to-refresh)
  Future<void> refreshAllData() async {
    // Reset flags to force reload
    hasTodayData = false;
    hasUpcomingData = false;
    hasHistoryData = false;
    return await loadInitialData(forceRefresh: true);
  }

  // Get all assigned reservations
  Future<void> loadAssignedReservations({bool skipLoadingState = false, bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (hasHistoryData && !forceRefresh && !skipLoadingState) return;
    
    if (!skipLoadingState) {
      isLoading = true;
      update();
    }

    try {
      var response = await driverReservationRepo.getAssignedReservations();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        serviceImagePath = data['data']['service_image_path'] ?? '';
        userImagePath = data['data']['user_image_path'] ?? '';

        if (data['data']['reservations'] != null && data['data']['reservations']['data'] != null) {
          assignedReservations.clear();
          // Access the nested 'data' array from paginated response
          (data['data']['reservations']['data'] as List).forEach((reservation) {
            assignedReservations.add(DriverReservationModel.fromJson(reservation));
          });
          
          // Separate completed reservations
          completedReservations = assignedReservations
              .where((r) => r.isCompleted || r.isCancelled)
              .toList();
          
          hasHistoryData = true;
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading assigned reservations: $e');
      CustomSnackBar.error(errorList: ['Failed to load reservations']);
    } finally {
      if (!skipLoadingState) {
        isLoading = false;
        update();
      }
    }
  }

  // Get upcoming reservations
  Future<void> loadUpcomingReservations({bool skipLoadingState = false, bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (hasUpcomingData && !forceRefresh && !skipLoadingState) return;
    
    if (!skipLoadingState) {
      isLoading = true;
      update();
    }

    try {
      var response = await driverReservationRepo.getUpcomingReservations();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        upcomingReservations.clear();
        
        // Process reservation objects (one-time reservations)
        if (data['data']['reservations'] != null && data['data']['reservations']['data'] != null) {
          (data['data']['reservations']['data'] as List).forEach((reservation) {
            upcomingReservations.add(DriverReservationModel.fromJson(reservation));
          });
        }
        
        // Process upcoming_schedules (individual schedule instances for recurring)
        if (data['data']['upcoming_schedules'] != null) {
          (data['data']['upcoming_schedules'] as List).forEach((schedule) {
            // Extract the parent reservation from the schedule
            if (schedule['reservation'] != null) {
              var reservation = DriverReservationModel.fromJson(schedule['reservation']);
              // Only add if not already in the list
              if (!upcomingReservations.any((r) => r.id == reservation.id)) {
                upcomingReservations.add(reservation);
              }
            }
          });
        }
        
        hasUpcomingData = true;
        printX('Loaded ${upcomingReservations.length} upcoming reservations/schedules');
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading upcoming reservations: $e');
      CustomSnackBar.error(errorList: ['Failed to load upcoming reservations']);
    } finally {
      if (!skipLoadingState) {
        isLoading = false;
        update();
      }
    }
  }

  // Get today's reservations
  Future<void> loadTodayReservations({bool skipLoadingState = false, bool forceRefresh = false}) async {
    // Skip if already loaded and not forcing refresh
    if (hasTodayData && !forceRefresh && !skipLoadingState) return;
    
    if (!skipLoadingState) {
      isLoading = true;
      update();
    }

    try {
      var response = await driverReservationRepo.getTodayReservations();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        todayReservations.clear();
        
        // Process reservation objects (one-time reservations)
        if (data['data']['reservations'] != null && data['data']['reservations']['data'] != null) {
          (data['data']['reservations']['data'] as List).forEach((reservation) {
            todayReservations.add(DriverReservationModel.fromJson(reservation));
          });
        }
        
        // Process today_schedules (individual schedule instances for recurring)
        if (data['data']['today_schedules'] != null) {
          (data['data']['today_schedules'] as List).forEach((schedule) {
            // Extract the parent reservation from the schedule
            if (schedule['reservation'] != null) {
              var reservation = DriverReservationModel.fromJson(schedule['reservation']);
              // Only add if not already in the list
              if (!todayReservations.any((r) => r.id == reservation.id)) {
                todayReservations.add(reservation);
              }
            }
          });
        }
        
        hasTodayData = true;
        printX('Loaded ${todayReservations.length} today reservations/schedules');
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading today reservations: $e');
      CustomSnackBar.error(errorList: ['Failed to load today\'s reservations']);
    } finally {
      if (!skipLoadingState) {
        isLoading = false;
        update();
      }
    }
  }

  // Get reservation details
  Future<void> loadReservationDetail(int id) async {
    isLoading = true;
    update();

    try {
      var response = await driverReservationRepo.getReservationDetail(id);

      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        if (data['data']['reservation'] != null) {
          // Parse reservation (includes embedded schedules)
          selectedReservation = DriverReservationModel.fromJson(data['data']['reservation']);
          
          // The schedules are already embedded in reservation object from API
          // But also provided separately in 'schedules' key for convenience
          // Use the separate schedules if provided (more explicit filtering)
          if (data['data']['schedules'] != null && data['data']['schedules'] is List) {
            reservationSchedules.clear();
            (data['data']['schedules'] as List).forEach((schedule) {
              reservationSchedules.add(ReservationScheduleModel.fromJson(schedule));
            });
            
            // Override embedded schedules with filtered upcoming schedules
            selectedReservation?.schedules = reservationSchedules;
            
            printX('✅ Loaded ${reservationSchedules.length} upcoming schedules for reservation ${selectedReservation?.id}');
          } else {
            // Use embedded schedules from reservation object
            reservationSchedules = selectedReservation?.schedules ?? [];
            printX('✅ Using embedded schedules: ${reservationSchedules.length} schedules');
          }
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading reservation detail: $e');
      CustomSnackBar.error(errorList: ['Failed to load reservation details']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Load weekly schedule for a reservation
  Future<void> loadWeeklySchedule(int reservationId, DateTime weekStart) async {
    isLoading = true;
    update();

    try {
      var response = await driverReservationRepo.getWeeklySchedule(reservationId, weekStart.toIso8601String());

      if (response.statusCode == 200) {
        var data = response.responseJson;
        
        // The weekly schedule data is already processed by the backend
        // We can use it directly or store it as needed
        if (data['data']['schedule'] != null) {
          // Process the weekly schedule data
          printX('Loaded weekly schedule with ${data['data']['total_schedules']} schedules');
        }
      } else {
        CustomSnackBar.error(errorList: [response.message]);
      }
    } catch (e) {
      printX('Error loading weekly schedule: $e');
      CustomSnackBar.error(errorList: ['Failed to load weekly schedule']);
    } finally {
      isLoading = false;
      update();
    }
  }

  // Accept reservation ride
  Future<bool> acceptReservationRide(int id) async {
    isLoading = true;
    update();

    try {
      var response = await driverReservationRepo.acceptReservationRide(id);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message.toString()]);
        // Reload reservations
        await loadAssignedReservations();
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error accepting reservation: $e');
      CustomSnackBar.error(errorList: ['Failed to accept reservation']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Reject reservation ride
  Future<bool> rejectReservationRide(int id, String reason) async {
    isLoading = true;
    update();

    try {
      var response = await driverReservationRepo.rejectReservationRide(id, reason);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message.toString()]);
        // Reload reservations
        await loadAssignedReservations();
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error rejecting reservation: $e');
      CustomSnackBar.error(errorList: ['Failed to reject reservation']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Start reservation ride
  Future<bool> startReservationRide(int scheduleId) async {
    isLoading = true;
    update();

    try {
      var response = await driverReservationRepo.startReservationRide(scheduleId);

      if (response.statusCode == 200) {
        CustomSnackBar.success(successList: [response.message.toString()]);
        return true;
      } else {
        CustomSnackBar.error(errorList: [response.message]);
        return false;
      }
    } catch (e) {
      printX('Error starting reservation ride: $e');
      CustomSnackBar.error(errorList: ['Failed to start ride']);
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }

  // Load reservation statistics
  Future<void> loadReservationStats({bool skipLoadingState = false}) async {
    try {
      var response = await driverReservationRepo.getReservationStats();

      if (response.statusCode == 200) {
        var data = response.responseJson;
        reservationStats = data['data']['stats'];
        if (!skipLoadingState) {
          update();
        }
      }
    } catch (e) {
      printX('Error loading reservation stats: $e');
    }
  }

  // Helper methods
  int get totalReservations => assignedReservations.length;
  int get activeReservations => assignedReservations
      .where((r) => !r.isCompleted && !r.isCancelled)
      .length;
  int get todayCount => todayReservations.length;
  int get upcomingCount => upcomingReservations.length;
  
  // Use stats from API if available for more accurate counts
  int get todaySchedulesCount => reservationStats?['today_schedules'] ?? todayCount;
  int get upcomingSchedulesCount => reservationStats?['upcoming_schedules'] ?? upcomingCount;
  
  // Get reservations by status
  List<DriverReservationModel> getReservationsByStatus(int status) {
    return assignedReservations.where((reservation) => reservation.status == status).toList();
  }

  // Check if there are any reservations today
  bool get hasReservationsToday => todayReservations.isNotEmpty;
  
  // Check if there are any upcoming reservations
  bool get hasUpcomingReservations => upcomingReservations.isNotEmpty;

  // Clear all data
  void clearData() {
    assignedReservations.clear();
    upcomingReservations.clear();
    todayReservations.clear();
    completedReservations.clear();
    selectedReservation = null;
    reservationSchedules.clear();
    reservationStats = null;
    hasLoadedInitialData = false;
    hasTodayData = false;
    hasUpcomingData = false;
    hasHistoryData = false;
    update();
  }
}
