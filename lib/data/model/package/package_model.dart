class PackageModel {
  int? id;
  String? name;
  String? description;
  String? image;
  String? price;
  int? durationDays;
  int? durationWeeks;
  int? totalRides;
  int? maxRidersPerRide;
  int? locationType;
  String? startLocation;
  String? startLatitude;
  String? startLongitude;
  String? endLocation;
  String? endLatitude;
  String? endLongitude;
  int? tripType;
  bool? hasSchedule;
  bool? allowCustomTiming;
  bool? showInHeader;
  int? status;
  List<ServiceModel>? services;
  List<PackageScheduleModel>? schedules;
  
  // Dynamic pricing fields
  bool? useDynamicPricing;
  String? basePrice;
  String? pricePerDay;
  String? pricePerSlot;
  String? multiSlotDiscount;
  String? multiDayDiscount;

  // Location type constants
  static const int LOCATION_FIXED = 1;
  static const int LOCATION_USER_SELECT = 2;

  PackageModel({
    this.id,
    this.name,
    this.description,
    this.image,
    this.price,
    this.durationDays,
    this.durationWeeks,
    this.totalRides,
    this.maxRidersPerRide,
    this.locationType,
    this.startLocation,
    this.startLatitude,
    this.startLongitude,
    this.endLocation,
    this.endLatitude,
    this.endLongitude,
    this.tripType,
    this.hasSchedule,
    this.allowCustomTiming,
    this.showInHeader,
    this.status,
    this.services,
    this.schedules,
    this.useDynamicPricing,
    this.basePrice,
    this.pricePerDay,
    this.pricePerSlot,
    this.multiSlotDiscount,
    this.multiDayDiscount,
  });

  PackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    image = json['image'];
    price = json['price'].toString();
    durationDays = json['duration_days'];
    durationWeeks = json['duration_weeks'];
    totalRides = json['total_rides'];
    maxRidersPerRide = json['max_riders_per_ride'];
    locationType = json['location_type'];
    startLocation = json['start_location'];
    startLatitude = json['start_latitude'];
    startLongitude = json['start_longitude'];
    endLocation = json['end_location'];
    endLatitude = json['end_latitude'];
    endLongitude = json['end_longitude'];
    tripType = json['trip_type'];
    hasSchedule = json['has_schedule'] == 1 || json['has_schedule'] == true;
    allowCustomTiming = json['allow_custom_timing'] == 1 || json['allow_custom_timing'] == true;
    showInHeader = json['show_in_header'] == 1 || json['show_in_header'] == true;
    status = json['status'];
    // Dynamic pricing fields
    useDynamicPricing = json['use_dynamic_pricing'] == 1 || json['use_dynamic_pricing'] == true;
    basePrice = json['base_price']?.toString();
    pricePerDay = json['price_per_day']?.toString();
    pricePerSlot = json['price_per_slot']?.toString();
    multiSlotDiscount = json['multi_slot_discount']?.toString();
    multiDayDiscount = json['multi_day_discount']?.toString();
    if (json['services'] != null) {
      services = <ServiceModel>[];
      json['services'].forEach((v) {
        services!.add(ServiceModel.fromJson(v));
      });
    }
    if (json['schedules'] != null) {
      schedules = <PackageScheduleModel>[];
      json['schedules'].forEach((v) {
        schedules!.add(PackageScheduleModel.fromJson(v));
      });
    }
  }

  bool get hasFixedLocations => locationType == LOCATION_FIXED;
  bool get allowsUserLocationSelection => locationType == LOCATION_USER_SELECT;
  bool get isOneWay => tripType == 1;
  bool get isTwoWay => tripType == 2;
  String get tripTypeName => isTwoWay ? 'Two-way' : 'One-way';
  bool get hasWeeklySchedule => hasSchedule == true;
  bool get allowsCustomization => allowCustomTiming == true;
  
  /// Calculate dynamic price based on selected days and time slots
  double calculateDynamicPrice({
    required List<int> selectedDays,
    required Map<int, List<String>> selectedTimeSlots,
  }) {
    if (useDynamicPricing != true) {
      return double.tryParse(price ?? '0') ?? 0.0;
    }

    double totalPrice = double.tryParse(basePrice ?? '0') ?? 0.0;
    int dayCount = selectedDays.length;
    int totalSlots = 0;
    int daysWithBothSlots = 0;

    // Count total slots and days with both morning & evening
    for (var day in selectedDays) {
      final slots = selectedTimeSlots[day] ?? [];
      totalSlots += slots.length;
      if (slots.length >= 2) {
        daysWithBothSlots++;
      }
    }

    // Add day costs
    totalPrice += dayCount * (double.tryParse(pricePerDay ?? '0') ?? 0.0);
    
    // Add slot costs
    totalPrice += totalSlots * (double.tryParse(pricePerSlot ?? '0') ?? 0.0);
    
    // Apply multi-slot discount
    if (daysWithBothSlots > 0 && multiSlotDiscount != null) {
      final discount = (double.tryParse(multiSlotDiscount ?? '0') ?? 0.0);
      if (discount > 0) {
        totalPrice -= (totalPrice * discount / 100);
      }
    }
    
    // Apply multi-day discount (more than 3 days)
    if (dayCount > 3 && multiDayDiscount != null) {
      final discount = (double.tryParse(multiDayDiscount ?? '0') ?? 0.0);
      if (discount > 0) {
        totalPrice -= (totalPrice * discount / 100);
      }
    }
    
    return totalPrice > 0 ? totalPrice : 0.0;
  }
  
  /// Get display price - returns base price for dynamic, regular price otherwise
  String get displayPrice {
    if (useDynamicPricing == true) {
      return basePrice ?? '0';
    }
    return price ?? '0';
  }
  
  /// Check if this package uses dynamic pricing
  bool get hasDynamicPricing => useDynamicPricing == true;
}

class ServiceModel {
  int? id;
  String? name;
  String? subtitle;
  String? image;

  ServiceModel({this.id, this.name, this.subtitle, this.image});

  ServiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    subtitle = json['subtitle'];
    image = json['image'];
  }
}

class UserPackageModel {
  int? id;
  int? userId;
  int? packageId;
  int? driverId;
  String? transactionId;
  String? amountPaid;
  String? price;
  int? totalRides;
  int? ridesUsed;
  int? ridesRemaining;
  int? remainingRides; // Keep for backward compatibility
  String? purchasedAt;
  String? expiresAt;
  int? status;
  int? daysRemaining;
  
  // Schedule-related fields
  int? tripType;
  List<int>? selectedDays;
  List<String>? selectedTimeSlots;
  Map<String, dynamic>? customSchedule;
  String? scheduleStartDate;
  
  // Direct fields from API
  String? packageName;
  String? packageDescription;
  String? packageImage;
  
  PackageModel? package;
  UserInfo? user;
  List<UserPackageScheduleModel>? schedules;

  // Computed properties
  int get usedRides => ridesUsed ?? ((totalRides ?? 0) - (ridesRemaining ?? remainingRides ?? 0));
  
  double get usagePercentage {
    if (totalRides == null || totalRides == 0) return 0;
    int used = ridesUsed ?? usedRides;
    return (used / totalRides!) * 100;
  }

  int getDaysRemaining() {
    if (daysRemaining != null) return daysRemaining!;
    if (expiresAt == null) return 0;
    try {
      final expiry = DateTime.parse(expiresAt!);
      final now = DateTime.now();
      final difference = expiry.difference(now).inDays;
      return difference > 0 ? difference : 0;
    } catch (e) {
      return 0;
    }
  }

  String get statusText {
    switch (status) {
      case 1:
        return 'Active';
      case 2:
        return 'Expired';
      case 3:
        return 'Completed';
      case 0:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool get isOneWay => tripType == 1;
  bool get isTwoWay => tripType == 2;
  String get tripTypeName => isTwoWay ? 'Two-way (Round trip)' : 'One-way';
  
  String get selectedDaysString {
    if (selectedDays == null || selectedDays!.isEmpty) return 'All days';
    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return selectedDays!.map((d) => dayNames[d]).join(', ');
  }
  
  String get selectedTimeSlotsString {
    if (selectedTimeSlots == null || selectedTimeSlots!.isEmpty) return 'N/A';
    return selectedTimeSlots!.map((s) => s[0].toUpperCase() + s.substring(1)).join(' & ');
  }
  
  bool get hasWeeklySchedule => (schedules != null && schedules!.isNotEmpty) || 
                                (package?.hasSchedule == true) || 
                                (selectedDays != null && selectedDays!.isNotEmpty);

  UserPackageModel({
    this.id,
    this.userId,
    this.packageId,
    this.driverId,
    this.transactionId,
    this.amountPaid,
    this.price,
    this.totalRides,
    this.ridesUsed,
    this.ridesRemaining,
    this.remainingRides,
    this.purchasedAt,
    this.expiresAt,
    this.status,
    this.daysRemaining,
    this.tripType,
    this.selectedDays,
    this.selectedTimeSlots,
    this.customSchedule,
    this.scheduleStartDate,
    this.packageName,
    this.packageDescription,
    this.packageImage,
    this.package,
    this.user,
    this.schedules,
  });

  UserPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    packageId = json['package_id'];
    driverId = json['driver_id'];
    transactionId = json['transaction_id'];
    amountPaid = json['amount_paid']?.toString();
    price = json['price']?.toString();
    totalRides = json['total_rides'];
    ridesUsed = json['rides_used'];
    ridesRemaining = json['rides_remaining'];
    remainingRides = json['remaining_rides']; // Backward compatibility
    purchasedAt = json['purchased_at'];
    expiresAt = json['expires_at'];
    status = json['status'];
    // Handle days_remaining as double from API and convert to int
    if (json['days_remaining'] != null) {
      daysRemaining = (json['days_remaining'] is double) 
          ? (json['days_remaining'] as double).ceil() 
          : json['days_remaining'] as int;
    }
    tripType = json['trip_type'];
    selectedDays = json['selected_days'] != null ? List<int>.from(json['selected_days']) : null;
    selectedTimeSlots = json['selected_time_slots'] != null ? List<String>.from(json['selected_time_slots']) : null;
    customSchedule = json['custom_schedule'];
    scheduleStartDate = json['schedule_start_date'];
    packageName = json['package_name'];
    packageDescription = json['package_description'];
    packageImage = json['package_image'];
    package = json['package'] != null ? PackageModel.fromJson(json['package']) : null;
    user = json['user'] != null ? UserInfo.fromJson(json['user']) : null;
    if (json['schedules'] != null) {
      schedules = <UserPackageScheduleModel>[];
      json['schedules'].forEach((v) {
        schedules!.add(UserPackageScheduleModel.fromJson(v));
      });
    }
  }
}

class UserInfo {
  int? id;
  String? firstname;
  String? lastname;
  String? email;
  String? mobile;
  String? image;

  String get fullname => '${firstname ?? ''} ${lastname ?? ''}'.trim();

  UserInfo({this.id, this.firstname, this.lastname, this.email, this.mobile, this.image});

  UserInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    // Handle both 'name' (direct from API) and 'firstname'/'lastname' format
    if (json['name'] != null) {
      final nameParts = (json['name'] as String).split(' ');
      firstname = nameParts.isNotEmpty ? nameParts[0] : '';
      lastname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    } else {
      firstname = json['firstname'];
      lastname = json['lastname'];
    }
    email = json['email'];
    mobile = json['mobile'];
    image = json['image'];
  }
}

class PackageStatistics {
  int? totalAssigned;
  int? activePackages;
  int? completedPackages;
  int? totalRidesAvailable;
  int? totalRidesCompleted;

  PackageStatistics({
    this.totalAssigned,
    this.activePackages,
    this.completedPackages,
    this.totalRidesAvailable,
    this.totalRidesCompleted,
  });

  PackageStatistics.fromJson(Map<String, dynamic> json) {
    totalAssigned = json['total_assigned'];
    activePackages = json['active_packages'];
    completedPackages = json['completed_packages'];
    totalRidesAvailable = json['total_rides_available'];
    totalRidesCompleted = json['total_rides_completed'];
  }
}

class PackageRideModel {
  int? id;
  int? userPackageId;
  int? rideId;
  int? userId;
  int? driverId;
  int? rideNumber;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? destination;
  String? destinationLatitude;
  String? destinationLongitude;
  String? startedAt;
  String? completedAt;
  int? riderConfirmed;
  int? driverConfirmed;
  String? riderConfirmedAt;
  String? driverConfirmedAt;
  int? status;

  // Status constants
  static const int STATUS_PENDING = 0;
  static const int STATUS_ACTIVE = 1;
  static const int STATUS_RUNNING = 2;
  static const int STATUS_COMPLETED = 3;
  static const int STATUS_CANCELLED = 9;

  PackageRideModel({
    this.id,
    this.userPackageId,
    this.rideId,
    this.userId,
    this.driverId,
    this.rideNumber,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.startedAt,
    this.completedAt,
    this.riderConfirmed,
    this.driverConfirmed,
    this.riderConfirmedAt,
    this.driverConfirmedAt,
    this.status,
  });

  PackageRideModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userPackageId = json['user_package_id'];
    rideId = json['ride_id'];
    userId = json['user_id'];
    driverId = json['driver_id'];
    rideNumber = json['ride_number'];
    pickupLocation = json['pickup_location'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    destination = json['destination'];
    destinationLatitude = json['destination_latitude'];
    destinationLongitude = json['destination_longitude'];
    startedAt = json['started_at'];
    completedAt = json['completed_at'];
    riderConfirmed = json['rider_confirmed'];
    driverConfirmed = json['driver_confirmed'];
    riderConfirmedAt = json['rider_confirmed_at'];
    driverConfirmedAt = json['driver_confirmed_at'];
    status = json['status'];
  }

  bool get isBothConfirmed => riderConfirmed == 1 && driverConfirmed == 1;
  bool get isPendingConfirmation => riderConfirmed == 0 || driverConfirmed == 0;
  
  String get statusText {
    switch (status) {
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_ACTIVE:
        return 'Active';
      case STATUS_RUNNING:
        return 'Running';
      case STATUS_COMPLETED:
        return 'Completed';
      case STATUS_CANCELLED:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}

// Package Schedule Models
class PackageScheduleModel {
  int? dayOfWeek;
  String? dayName;
  ScheduleSlot? morning;
  ScheduleSlot? evening;

  PackageScheduleModel({this.dayOfWeek, this.dayName, this.morning, this.evening});

  PackageScheduleModel.fromJson(Map<String, dynamic> json) {
    dayOfWeek = json['day_of_week'];
    dayName = json['day_name'];
    morning = json['morning'] != null ? ScheduleSlot.fromJson(json['morning']) : null;
    evening = json['evening'] != null ? ScheduleSlot.fromJson(json['evening']) : null;
  }

  bool get hasMorningSlot => morning != null;
  bool get hasEveningSlot => evening != null;
}

class ScheduleSlot {
  LocationData? pickup;
  LocationData? drop;

  ScheduleSlot({this.pickup, this.drop});

  ScheduleSlot.fromJson(Map<String, dynamic> json) {
    pickup = json['pickup'] != null ? LocationData.fromJson(json['pickup']) : null;
    drop = json['drop'] != null ? LocationData.fromJson(json['drop']) : null;
  }
}

class LocationData {
  String? location;
  String? latitude;
  String? longitude;
  String? time;

  LocationData({this.location, this.latitude, this.longitude, this.time});

  LocationData.fromJson(Map<String, dynamic> json) {
    location = json['location'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    time = json['time'];
  }
}

// User Package Schedule Model
class UserPackageScheduleModel {
  int? id;
  int? userPackageId;
  int? packageScheduleId;
  int? dayOfWeek;
  String? dayName;
  String? timeSlot;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? pickupTime;
  String? dropLocation;
  String? dropLatitude;
  String? dropLongitude;
  String? dropTime;
  int? rideId;
  int? status;
  String? scheduledDate;
  String? completedAt;

  // Status constants
  static const int STATUS_PENDING = 0;
  static const int STATUS_COMPLETED = 1;
  static const int STATUS_SKIPPED = 2;
  static const int STATUS_CANCELLED = 3;

  UserPackageScheduleModel({
    this.id,
    this.userPackageId,
    this.packageScheduleId,
    this.dayOfWeek,
    this.dayName,
    this.timeSlot,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.pickupTime,
    this.dropLocation,
    this.dropLatitude,
    this.dropLongitude,
    this.dropTime,
    this.rideId,
    this.status,
    this.scheduledDate,
    this.completedAt,
  });

  UserPackageScheduleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userPackageId = json['user_package_id'];
    packageScheduleId = json['package_schedule_id'];
    dayOfWeek = json['day_of_week'];
    dayName = json['day_name'];
    timeSlot = json['time_slot'];
    pickupLocation = json['pickup_location'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    pickupTime = json['pickup_time'];
    dropLocation = json['drop_location'];
    dropLatitude = json['drop_latitude'];
    dropLongitude = json['drop_longitude'];
    dropTime = json['drop_time'];
    rideId = json['ride_id'];
    status = json['status'];
    scheduledDate = json['scheduled_date'];
    completedAt = json['completed_at'];
  }

  bool get isMorning => timeSlot == 'morning';
  bool get isEvening => timeSlot == 'evening';
  bool get isPending => status == STATUS_PENDING;
  bool get isCompleted => status == STATUS_COMPLETED;
  
  String get statusText {
    switch (status) {
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_COMPLETED:
        return 'Completed';
      case STATUS_SKIPPED:
        return 'Skipped';
      case STATUS_CANCELLED:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
  
  String get timeSlotFormatted => timeSlot != null ? timeSlot![0].toUpperCase() + timeSlot!.substring(1) : 'N/A';
}
