class DriverReservationModel {
  int? id;
  int? userId;
  int? driverId;
  int? serviceId;
  String? reservationCode;
  String? reservationType; // one_time, recurring
  String? reservationDate;
  dynamic pickupTime; // Can be String or Map for day-wise times
  dynamic returnTime; // Can be String or Map for day-wise times
  List<int>? recurringDays;
  String? recurringStartDate;
  String? recurringEndDate;
  int? totalOccurrences;
  int? completedOccurrences;
  int? totalSchedules; // Actual count of schedules created
  int? completedSchedules; // Actual count of completed schedules
  int? pendingRideId; // ID of pending ride waiting for accept/reject
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? destination;
  String? destinationLatitude;
  String? destinationLongitude;
  String? tripType; // one_way, round_trip
  double? estimatedDistance;
  double? estimatedDuration;
  String? estimatedAmount;
  String? finalAmount;
  String? paymentStatus; // pending, paid, refunded
  int? passengerCount;
  String? specialRequirements;
  String? contactNumber;
  int? status; // 0=Pending, 1=Confirmed, 2=Driver Assigned, 3=In Progress, 4=Completed, 5=Cancelled
  String? confirmedAt;
  String? startedAt;
  String? completedAt;
  String? cancelledAt;
  String? cancellationReason;
  String? cancelledBy; // user/driver/admin/system
  bool? sendReminder;
  String? reminderSentAt;
  String? adminNotes;
  String? createdAt;
  String? updatedAt;
  
  // Relations
  UserInfo? user;
  ServiceModel? service;
  List<ReservationScheduleModel>? schedules;
  
  // Constants
  static const int STATUS_PENDING = 0;
  static const int STATUS_CONFIRMED = 1;
  static const int STATUS_DRIVER_ASSIGNED = 2;
  static const int STATUS_IN_PROGRESS = 3;
  static const int STATUS_COMPLETED = 4;
  static const int STATUS_CANCELLED = 5;

  DriverReservationModel({
    this.id,
    this.userId,
    this.driverId,
    this.serviceId,
    this.reservationCode,
    this.reservationType,
    this.reservationDate,
    this.pickupTime,
    this.returnTime,
    this.recurringDays,
    this.recurringStartDate,
    this.recurringEndDate,
    this.totalOccurrences,
    this.completedOccurrences,
    this.totalSchedules,
    this.completedSchedules,
    this.pendingRideId,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.tripType,
    this.estimatedDistance,
    this.estimatedDuration,
    this.estimatedAmount,
    this.finalAmount,
    this.paymentStatus,
    this.passengerCount,
    this.specialRequirements,
    this.contactNumber,
    this.status,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.sendReminder,
    this.reminderSentAt,
    this.adminNotes,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.service,
    this.schedules,
  });

  DriverReservationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    driverId = json['driver_id'];
    serviceId = json['service_id'];
    reservationCode = json['reservation_code'];
    reservationType = json['reservation_type'];
    reservationDate = json['reservation_date'];
    pickupTime = json['pickup_time'];
    returnTime = json['return_time'];
    recurringDays = json['recurring_days'] != null 
        ? (json['recurring_days'] as List).map((e) => e is int ? e : int.parse(e.toString())).toList()
        : null;
    recurringStartDate = json['recurring_start_date'];
    recurringEndDate = json['recurring_end_date'];
    totalOccurrences = json['total_occurrences'];
    completedOccurrences = json['completed_occurrences'];
    totalSchedules = json['total_schedules'];
    completedSchedules = json['completed_schedules'];
    pendingRideId = json['pending_ride_id'];
    pickupLocation = json['pickup_location'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    destination = json['destination'];
    destinationLatitude = json['destination_latitude'];
    destinationLongitude = json['destination_longitude'];
    tripType = json['trip_type'];
    estimatedDistance = json['estimated_distance']?.toDouble();
    estimatedDuration = json['estimated_duration']?.toDouble();
    estimatedAmount = json['estimated_amount']?.toString();
    finalAmount = json['final_amount']?.toString();
    paymentStatus = json['payment_status'];
    passengerCount = json['passenger_count'];
    specialRequirements = json['special_requirements'];
    contactNumber = json['contact_number'];
    status = json['status'];
    confirmedAt = json['confirmed_at'];
    startedAt = json['started_at'];
    completedAt = json['completed_at'];
    cancelledAt = json['cancelled_at'];
    cancellationReason = json['cancellation_reason'];
    cancelledBy = json['cancelled_by'];
    sendReminder = json['send_reminder'] == 1 || json['send_reminder'] == true;
    reminderSentAt = json['reminder_sent_at'];
    adminNotes = json['admin_notes'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    
    user = json['user'] != null 
        ? UserInfo.fromJson(json['user'])
        : null;
    service = json['service'] != null 
        ? ServiceModel.fromJson(json['service'])
        : null;
    if (json['schedules'] != null) {
      schedules = <ReservationScheduleModel>[];
      json['schedules'].forEach((v) {
        schedules!.add(ReservationScheduleModel.fromJson(v));
      });
    }
  }

  bool get isOneTime => reservationType == 'one_time';
  bool get isRecurring => reservationType == 'recurring';
  bool get isOneWay => tripType == 'one_way';
  bool get isRoundTrip => tripType == 'round_trip';
  bool get isPending => status == STATUS_PENDING;
  bool get isConfirmed => status == STATUS_CONFIRMED;
  bool get isDriverAssigned => status == STATUS_DRIVER_ASSIGNED;
  bool get isInProgress => status == STATUS_IN_PROGRESS;
  bool get isCompleted => status == STATUS_COMPLETED;
  bool get isCancelled => status == STATUS_CANCELLED;
  
  String get statusText {
    switch (status) {
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_CONFIRMED:
        return 'Confirmed';
      case STATUS_DRIVER_ASSIGNED:
        return 'Assigned to You';
      case STATUS_IN_PROGRESS:
        return 'In Progress';
      case STATUS_COMPLETED:
        return 'Completed';
      case STATUS_CANCELLED:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
  
  String get typeText => isRecurring ? 'Recurring' : 'One Time';
  String get tripTypeText => isRoundTrip ? 'Round Trip' : 'One Way';
  
  String get recurringDaysText {
    if (recurringDays == null || recurringDays!.isEmpty) return '';
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return recurringDays!.map((day) => dayNames[day - 1]).join(', ');
  }
  
  bool canAcceptRide() {
    // Driver can accept ride when it's assigned to them AND there's a pending ride
    return status == STATUS_DRIVER_ASSIGNED && pendingRideId != null;
  }
  
  bool canStartRide() {
    // Driver can start ride when it's assigned and confirmed
    return status == STATUS_DRIVER_ASSIGNED || status == STATUS_CONFIRMED;
  }
  
  // Get pickup time as string (handles both string and map formats)
  String? getPickupTimeString() {
    if (pickupTime == null) return null;
    if (pickupTime is String) return pickupTime;
    if (pickupTime is Map) {
      // If it's a map, return first available time or format as needed
      var times = pickupTime as Map;
      if (times.isNotEmpty) {
        return times.values.first.toString();
      }
    }
    return null;
  }
  
  // Get return time as string (handles both string and map formats)
  String? getReturnTimeString() {
    if (returnTime == null) return null;
    if (returnTime is String) return returnTime;
    if (returnTime is Map) {
      var times = returnTime as Map;
      if (times.isNotEmpty) {
        return times.values.first.toString();
      }
    }
    return null;
  }
  
  // Get pickup time for specific day (for recurring reservations)
  String? getPickupTimeForDay(int dayOfWeek) {
    if (pickupTime == null) return null;
    if (pickupTime is String) return pickupTime;
    if (pickupTime is Map) {
      var times = pickupTime as Map;
      return times[dayOfWeek.toString()]?.toString();
    }
    return null;
  }
  
  // Get return time for specific day (for recurring reservations)
  String? getReturnTimeForDay(int dayOfWeek) {
    if (returnTime == null) return null;
    if (returnTime is String) return returnTime;
    if (returnTime is Map) {
      var times = returnTime as Map;
      return times[dayOfWeek.toString()]?.toString();
    }
    return null;
  }
}

class ReservationScheduleModel {
  int? id;
  int? reservationId;
  int? rideId;
  int? returnRideId;
  String? scheduledDate;
  String? scheduledPickupTime;
  String? scheduledReturnTime;
  int? dayOfWeek;
  int? occurrenceNumber;
  String? pickupLocation;
  String? pickupLatitude;
  String? pickupLongitude;
  String? destination;
  String? destinationLatitude;
  String? destinationLongitude;
  int? status; // 0=Pending, 1=Active, 2=Completed, 3=Cancelled
  String? rideCreatedAt;
  String? completedAt;
  String? cancelledAt;
  String? cancellationReason;
  String? notes;
  String? createdAt;
  String? updatedAt;
  
  // Constants
  static const int STATUS_PENDING = 0;
  static const int STATUS_RIDE_CREATED = 1;
  static const int STATUS_COMPLETED = 2;
  static const int STATUS_SKIPPED = 3;
  static const int STATUS_CANCELLED = 4;

  ReservationScheduleModel({
    this.id,
    this.reservationId,
    this.rideId,
    this.returnRideId,
    this.scheduledDate,
    this.scheduledPickupTime,
    this.scheduledReturnTime,
    this.dayOfWeek,
    this.occurrenceNumber,
    this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destination,
    this.destinationLatitude,
    this.destinationLongitude,
    this.status,
    this.rideCreatedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  ReservationScheduleModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    reservationId = json['reservation_id'];
    rideId = json['ride_id'];
    returnRideId = json['return_ride_id'];
    scheduledDate = json['scheduled_date'];
    scheduledPickupTime = json['scheduled_pickup_time'];
    scheduledReturnTime = json['scheduled_return_time'];
    dayOfWeek = json['day_of_week'];
    occurrenceNumber = json['occurrence_number'];
    pickupLocation = json['pickup_location'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    destination = json['destination'];
    destinationLatitude = json['destination_latitude'];
    destinationLongitude = json['destination_longitude'];
    status = json['status'];
    rideCreatedAt = json['ride_created_at'];
    completedAt = json['completed_at'];
    cancelledAt = json['cancelled_at'];
    cancellationReason = json['cancellation_reason'];
    notes = json['notes'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  bool get isPending => status == STATUS_PENDING;
  bool get isRideCreated => status == STATUS_RIDE_CREATED;
  bool get isCompleted => status == STATUS_COMPLETED;
  bool get isSkipped => status == STATUS_SKIPPED;
  bool get isCancelled => status == STATUS_CANCELLED;
  
  // Round-trip helpers
  bool get hasReturnRide => returnRideId != null && returnRideId! > 0;
  bool get hasPickupRide => rideId != null && rideId! > 0;
  bool get isRoundTrip => scheduledReturnTime != null && scheduledReturnTime!.isNotEmpty;
  
  String get statusText {
    switch (status) {
      case STATUS_PENDING:
        return 'Pending';
      case STATUS_RIDE_CREATED:
        return 'Ride Created';
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
  
  String get dayName {
    if (dayOfWeek == null) return '';
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek! - 1];
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
    firstname = json['firstname'];
    lastname = json['lastname'];
    email = json['email'];
    mobile = json['mobile'];
    image = json['image'];
  }
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
