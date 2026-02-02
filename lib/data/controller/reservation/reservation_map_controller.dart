import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/data/controller/reservation/driver_reservation_controller.dart';
import 'package:ovoride_driver/data/model/reservation/driver_reservation_model.dart';
import 'package:ovoride_driver/environment.dart';

class ReservationMapController extends GetxController {
  bool isLoading = false;
  
  // Map related
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  LatLng centerPosition = const LatLng(28.3949, 84.1240); // Default center (Nepal)
  
  // Reservations data
  List<DriverReservationModel> todayReservations = [];
  List<DriverReservationModel> upcomingReservations = [];
  List<DriverReservationModel> completedReservations = [];
  
  // Selected reservation for bottom sheet
  DriverReservationModel? selectedReservation;
  
  // Current tab index (0: Today, 1: Upcoming, 2: Completed)
  int currentTabIndex = 0;
  
  // Filter options
  bool showPickupMarkers = true;
  bool showDropoffMarkers = true;
  bool showRoutes = true;
  
  // Custom marker icons
  BitmapDescriptor? pickupIcon;
  BitmapDescriptor? dropoffIcon;
  BitmapDescriptor? upcomingIcon;
  
  @override
  void onInit() {
    super.onInit();
    loadCustomMarkerIcons();
  }
  
  void setMapController(GoogleMapController controller) {
    mapController = controller;
  }
  
  Future<void> loadCustomMarkerIcons() async {
    try {
      // Create custom marker icons
      pickupIcon = await _createCustomMarkerIcon(
        Icons.location_on,
        Colors.green,
        'P',
      );
      
      dropoffIcon = await _createCustomMarkerIcon(
        Icons.flag,
        Colors.red,
        'D',
      );
      
      upcomingIcon = await _createCustomMarkerIcon(
        Icons.timer,
        Colors.orange,
        'U',
      );
    } catch (e) {
      debugPrint('Error loading custom markers: $e');
      // Fall back to default markers
      pickupIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      dropoffIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      upcomingIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    update();
  }
  
  Future<BitmapDescriptor> _createCustomMarkerIcon(
    IconData iconData,
    Color color,
    String label,
  ) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = 30.0;
    
    // Draw circle background
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      paint,
    );
    
    // Draw white circle inside
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 5,
      paint,
    );
    
    // Draw text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );
    
    // Draw pin
    final path = Path();
    path.moveTo(radius - 15, radius + 15);
    path.lineTo(radius, radius + 30);
    path.lineTo(radius + 15, radius + 15);
    path.close();
    paint.color = color;
    canvas.drawPath(path, paint);
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(60, 90);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }
  
  Future<void> loadReservations() async {
    isLoading = true;
    update();
    
    try {
      // Get reservations from the existing controller
      final reservationController = Get.find<DriverReservationController>();
      
      // Load all data if not already loaded
      if (!reservationController.hasLoadedInitialData) {
        await reservationController.loadInitialData();
      }
      
      // Get reservations by category
      todayReservations = List.from(reservationController.todayReservations);
      upcomingReservations = List.from(reservationController.upcomingReservations);
      completedReservations = List.from(reservationController.completedReservations);
      
      // Update map with markers
      updateMapMarkers();
      
      // Center map on first reservation if available
      centerMapOnReservations();
      
    } catch (e) {
      debugPrint('Error loading reservations: $e');
    } finally {
      isLoading = false;
      update();
    }
  }
  
  Future<void> updateMapMarkers() async {
    markers.clear();
    polylines.clear();
    
    List<DriverReservationModel> reservationsToShow = [];
    
    // Get reservations based on current tab
    switch (currentTabIndex) {
      case 0: // Today
        reservationsToShow = todayReservations;
        break;
      case 1: // Upcoming
        reservationsToShow = upcomingReservations;
        break;
      case 2: // Completed
        reservationsToShow = completedReservations;
        break;
    }
    
    // Create markers for each reservation
    for (int i = 0; i < reservationsToShow.length; i++) {
      final reservation = reservationsToShow[i];
      
      if (reservation.pickupLatitude != null && reservation.pickupLongitude != null) {
        // Add pickup marker
        if (showPickupMarkers) {
          markers.add(
            Marker(
              markerId: MarkerId('pickup_${reservation.id}'),
              position: LatLng(
                double.tryParse(reservation.pickupLatitude.toString()) ?? 0,
                double.tryParse(reservation.pickupLongitude.toString()) ?? 0,
              ),
              infoWindow: InfoWindow(
                title: 'Pickup: ${reservation.user?.fullname ?? ""}',
                snippet: reservation.pickupLocation,
                onTap: () => _onMarkerTapped(reservation),
              ),
              icon: _getMarkerIcon(reservation, true),
              onTap: () => _onMarkerTapped(reservation),
            ),
          );
        }
        
        // Add dropoff marker
        if (showDropoffMarkers && 
            reservation.destinationLatitude != null && 
            reservation.destinationLongitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('dropoff_${reservation.id}'),
              position: LatLng(
                double.tryParse(reservation.destinationLatitude.toString()) ?? 0,
                double.tryParse(reservation.destinationLongitude.toString()) ?? 0,
              ),
              infoWindow: InfoWindow(
                title: 'Drop: ${reservation.user?.fullname ?? ""}',
                snippet: reservation.destination,
                onTap: () => _onMarkerTapped(reservation),
              ),
              icon: dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              onTap: () => _onMarkerTapped(reservation),
            ),
          );
        }
        
        // Add route polyline - AWAIT the polyline creation
        if (showRoutes && 
            reservation.destinationLatitude != null && 
            reservation.destinationLongitude != null) {
          await _addPolyline(reservation);
        }
      }
    }
    
    update();
  }
  
  BitmapDescriptor _getMarkerIcon(DriverReservationModel reservation, bool isPickup) {
    if (!isPickup) {
      return dropoffIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    
    // For today's tab, show upcoming markers for future rides
    if (currentTabIndex == 0 && reservation.schedules != null && reservation.schedules!.isNotEmpty) {
      final now = DateTime.now();
      final schedule = reservation.schedules!.first;
      
      // Parse schedule time
      try {
        final scheduleParts = schedule.scheduledPickupTime?.split(':');
        if (scheduleParts != null && scheduleParts.length >= 2) {
          final scheduleTime = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(scheduleParts[0]),
            int.parse(scheduleParts[1]),
          );
          
          // If scheduled time is in the future, show upcoming icon
          if (scheduleTime.isAfter(now)) {
            return upcomingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          }
        }
      } catch (e) {
        debugPrint('Error parsing schedule time: $e');
      }
    }
    
    return pickupIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  }
  
  Future<void> _addPolyline(DriverReservationModel reservation) async {
    try {
      final pickupLat = double.tryParse(reservation.pickupLatitude.toString()) ?? 0;
      final pickupLng = double.tryParse(reservation.pickupLongitude.toString()) ?? 0;
      final destLat = double.tryParse(reservation.destinationLatitude.toString()) ?? 0;
      final destLng = double.tryParse(reservation.destinationLongitude.toString()) ?? 0;
      
      if (pickupLat == 0 || pickupLng == 0 || destLat == 0 || destLng == 0) return;
      
      debugPrint('Creating polyline for reservation ${reservation.id} from ($pickupLat, $pickupLng) to ($destLat, $destLng)');
      
      // Get polyline points
      PolylinePoints polylinePoints = PolylinePoints(apiKey: Environment.mapKey);
      
      // Create Routes API request
      RoutesApiRequest request = RoutesApiRequest(
        origin: PointLatLng(pickupLat, pickupLng),
        destination: PointLatLng(destLat, destLng),
        travelMode: TravelMode.driving,
        routingPreference: RoutingPreference.trafficAware,
      );
      
      // Get route using Routes API V2
      RoutesApiResponse response = await polylinePoints.getRouteBetweenCoordinatesV2(request: request);
      
      List<LatLng> polylineCoordinates = [];
      if (response.primaryRoute?.polylinePoints case List<PointLatLng> points) {
        debugPrint('Got ${points.length} polyline points for reservation ${reservation.id}');
        for (var point in points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        debugPrint('No polyline points received for reservation ${reservation.id}');
      }
      
      if (polylineCoordinates.isNotEmpty) {
        // Add polyline to map with better visibility
        PolylineId id = PolylineId('route_${reservation.id}');
        
        Color routeColor = _getPolylineColor(reservation);
        
        Polyline polyline = Polyline(
          polylineId: id,
          color: routeColor,
          points: polylineCoordinates,
          width: 5, // Increased width for better visibility
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: reservation.tripType == 'round_trip' 
              ? [PatternItem.dash(30), PatternItem.gap(15)]
              : [],
        );
        
        polylines[id] = polyline;
        debugPrint('Added polyline for reservation ${reservation.id} with ${polylineCoordinates.length} points');
      } else {
        debugPrint('No coordinates to create polyline for reservation ${reservation.id}');
      }
    } catch (e) {
      debugPrint('Error creating polyline for reservation ${reservation.id}: $e');
    }
  }
  
  Color _getPolylineColor(DriverReservationModel reservation) {
    // Use vibrant, distinct colors based on status
    switch (reservation.status) {
      case DriverReservationModel.STATUS_COMPLETED:
        return const Color(0xFF4CAF50); // Bright Green
      case DriverReservationModel.STATUS_IN_PROGRESS:
        return const Color(0xFF2196F3); // Bright Blue
      case DriverReservationModel.STATUS_CANCELLED:
        return const Color(0xFFF44336); // Bright Red
      case DriverReservationModel.STATUS_CONFIRMED:
        return const Color(0xFFFF9800); // Orange
      case DriverReservationModel.STATUS_DRIVER_ASSIGNED:
        return const Color(0xFF9C27B0); // Purple
      default:
        return MyColor.primaryColor; // Primary color (no transparency)
    }
  }
  
  void _onMarkerTapped(DriverReservationModel reservation) {
    selectedReservation = reservation;
    update();
  }
  
  void clearSelectedReservation() {
    selectedReservation = null;
    update();
  }
  
  void centerMapOnReservations() {
    if (markers.isEmpty) {
      // If no markers, just set a default position
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: centerPosition,
            zoom: 12,
          ),
        ),
      );
      return;
    }
    
    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;
    
    for (final marker in markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }
    
    if (minLat != 90 && maxLat != -90) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      
      mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }
  
  int getScheduleCount() {
    switch (currentTabIndex) {
      case 0:
        return todayReservations.length;
      case 1:
        return upcomingReservations.length;
      case 2:
        return completedReservations.length;
      default:
        return 0;
    }
  }
  
  void togglePickupMarkers() {
    showPickupMarkers = !showPickupMarkers;
    updateMapMarkers();
  }
  
  void toggleDropoffMarkers() {
    showDropoffMarkers = !showDropoffMarkers;
    updateMapMarkers();
  }
  
  void toggleRoutes() {
    showRoutes = !showRoutes;
    updateMapMarkers();
  }
  
  @override
  void onClose() {
    mapController?.dispose();
    super.onClose();
  }
}
