import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovoride_driver/core/helper/string_format_helper.dart';
import 'package:ovoride_driver/core/utils/app_status.dart';
import 'package:ovoride_driver/core/utils/helper.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/my_icons.dart';
import 'package:ovoride_driver/data/controller/ride/ride_details/ride_details_controller.dart';
import 'package:ovoride_driver/environment.dart';
import 'package:ovoride_driver/presentation/packages/polyline_animation/polyline_animation_v1.dart';

class RideMapController extends GetxController with GetSingleTickerProviderStateMixin {
  bool isLoading = false;
  LatLng pickupLatLng = const LatLng(0, 0);
  LatLng destinationLatLng = const LatLng(0, 0);
  Map<PolylineId, Polyline> polylines = {};
  final PolylineAnimator animator = PolylineAnimator();

  // Driver live location tracking
  StreamSubscription<Position>? _positionStream;
  LatLng driverLatLng = const LatLng(0, 0);
  LatLng? _previousDriverLatLng;
  double driverRotation = 0.0;
  Uint8List? driverIcon;
  bool _isTracking = false;
  bool _cameraFollowsDriver = true;

  // Animation controller for smooth marker movement
  late final AnimationController _animController;

  @override
  void onInit() {
    super.onInit();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    stopDriverTracking();
    _animController.dispose();
    super.onClose();
  }

  void loadMap({required LatLng pickup, required LatLng destination}) async {
    pickupLatLng = pickup;
    destinationLatLng = destination;
    update();

    getPolyLinePoints().then((data) {
      polylineCoordinates = data;
      generatePolyLineFromPoints(data);
      fitPolylineBounds(data);
      if (Get.isRegistered<RideDetailsController>()) {
        if (![
          AppStatus.RIDE_RUNNING,
          AppStatus.RIDE_ACTIVE,
          AppStatus.RIDE_COMPLETED,
        ].contains(Get.find<RideDetailsController>().ride.status)) {
          animator.animatePolyline(
            data,
            'polyline_id',
            MyColor.colorOrange,
            MyColor.primaryColor,
            polylines,
            () {
              if (Get.isRegistered<RideDetailsController>()) {
                if (![
                  AppStatus.RIDE_RUNNING,
                  AppStatus.RIDE_ACTIVE,
                  AppStatus.RIDE_COMPLETED,
                ].contains(Get.find<RideDetailsController>().ride.status)) {
                  update();
                }
              }
            },
          );
        }
      }
    });
    await setCustomMarkerIcon();
  }

  GoogleMapController? mapController;
  void animateMapCameraPosition() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(pickupLatLng.latitude, pickupLatLng.longitude),
          zoom: Environment.mapDefaultZoom,
        ),
      ),
    );
  }

  void generatePolyLineFromPoints(List<LatLng> polylineCoordinates) async {
    isLoading = true;
    update();
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: MyColor.primaryColor,
      points: polylineCoordinates,
      width: 5,
    );
    polylines[id] = polyline;
    isLoading = false;
    update();
  }

  List<LatLng> polylineCoordinates = [];
  Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints(apiKey: Environment.mapKey);
    // Create Routes API request
    RoutesApiRequest request = RoutesApiRequest(
      origin: PointLatLng(pickupLatLng.latitude, pickupLatLng.longitude),
      destination: PointLatLng(
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      ),
      travelMode: TravelMode.driving,
      routingPreference: RoutingPreference.trafficAware,
    );

    // Get route using Routes API
    RoutesApiResponse response = await polylinePoints.getRouteBetweenCoordinatesV2(request: request);

    if (response.primaryRoute?.polylinePoints case List<PointLatLng> points) {
      for (var point in points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }

    return polylineCoordinates;
  }

  Uint8List? pickupIcon;
  Uint8List? destinationIcon;

  Set<Marker> getMarkers({
    required LatLng pickup,
    required LatLng destination,
  }) {
    final markers = <Marker>{};

    // Driver live location marker (car icon)
    if (driverLatLng.latitude != 0 || driverLatLng.longitude != 0) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_live_marker'),
          position: driverLatLng,
          rotation: driverRotation,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 100,
          icon: driverIcon != null
              ? BitmapDescriptor.bytes(
                  driverIcon!,
                  width: 40,
                  height: 40,
                  bitmapScaling: MapBitmapScaling.auto,
                )
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // Pickup marker
    markers.add(
      Marker(
        markerId: MarkerId('markerId${pickup.latitude}'),
        position: LatLng(pickup.latitude, pickup.longitude),
        icon: pickupIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                pickupIcon!,
                height: 40,
                width: 40,
                bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () {
          _cameraFollowsDriver = false;
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(pickup.latitude, pickup.longitude),
                zoom: 17,
              ),
            ),
          );
        },
      ),
    );

    // Destination marker
    markers.add(
      Marker(
        markerId: MarkerId('markerId${destination.latitude}'),
        position: LatLng(destination.latitude, destination.longitude),
        icon: destinationIcon == null
            ? BitmapDescriptor.defaultMarker
            : BitmapDescriptor.bytes(
                destinationIcon!,
                height: 45,
                width: 45,
                bitmapScaling: MapBitmapScaling.auto,
              ),
        onTap: () {
          _cameraFollowsDriver = false;
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(destination.latitude, destination.longitude),
                zoom: 17,
              ),
            ),
          );
        },
      ),
    );

    return markers;
  }

  Future<void> setCustomMarkerIcon({bool? isRunning}) async {
    pickupIcon = await Helper.getBytesFromAsset(
      MyIcons.mapMarkerPickUpIcon,
      150,
    );
    destinationIcon = await Helper.getBytesFromAsset(
      MyIcons.mapMarkerIcon,
      150,
    );
    // Load driver/car icon for live marker
    driverIcon = await Helper.getBytesFromAsset(
      'assets/images/map/driver.png',
      120,
    );
    update();

    // Automatically start tracking when ride is active/running
    if (isRunning == true) {
      startDriverTracking();
    }
  }

  // ─── Driver Live Location Tracking ──────────────────────────

  /// Start listening to the driver's GPS and updating the marker + camera
  void startDriverTracking() {
    if (_isTracking) return;
    _isTracking = true;
    _cameraFollowsDriver = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5, // update every 5 meters for smooth tracking
      ),
    ).listen(_onPositionUpdate);

    printX('🚗 Driver live tracking started');
  }

  /// Stop listening
  void stopDriverTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    printX('🛑 Driver live tracking stopped');
  }

  /// Re-center camera on driver (e.g. after tapping a button)
  void recenterOnDriver() {
    _cameraFollowsDriver = true;
    if (driverLatLng.latitude != 0 && driverLatLng.longitude != 0) {
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: driverLatLng,
            zoom: 17,
            bearing: driverRotation,
            tilt: 45,
          ),
        ),
      );
    }
  }

  void _onPositionUpdate(Position position) {
    final newLatLng = LatLng(position.latitude, position.longitude);

    if (driverLatLng.latitude == 0 && driverLatLng.longitude == 0) {
      // First position — set immediately
      _previousDriverLatLng = newLatLng;
      driverLatLng = newLatLng;
      driverRotation = position.heading;
      update();
      _moveCameraToDriver();
      return;
    }

    // Animate marker from old to new position
    _animateDriverMarker(newLatLng, position.heading);
  }

  void _animateDriverMarker(LatLng newPosition, double heading) {
    final oldPosition = _previousDriverLatLng ?? driverLatLng;
    _previousDriverLatLng = oldPosition;

    _animController.stop();
    _animController.reset();

    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.linear),
    );

    final latTween = Tween<double>(
      begin: oldPosition.latitude,
      end: newPosition.latitude,
    );
    final lngTween = Tween<double>(
      begin: oldPosition.longitude,
      end: newPosition.longitude,
    );

    void listener() {
      final lat = latTween.evaluate(animation);
      final lng = lngTween.evaluate(animation);
      driverLatLng = LatLng(lat, lng);

      // Update rotation (bearing)
      driverRotation = _getBearing(
        oldPosition.latitude,
        oldPosition.longitude,
        lat,
        lng,
      );

      update();

      // Follow the driver with camera
      if (_cameraFollowsDriver) {
        _moveCameraToDriver();
      }
    }

    _animController.removeListener(() {});
    _animController.addListener(listener);

    _animController.forward().whenComplete(() {
      driverLatLng = newPosition;
      driverRotation = heading != 0
          ? heading
          : _getBearing(
              oldPosition.latitude,
              oldPosition.longitude,
              newPosition.latitude,
              newPosition.longitude,
            );
      _previousDriverLatLng = newPosition;
      update();
      _animController.removeListener(listener);
    });
  }

  void _moveCameraToDriver() {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: driverLatLng,
          zoom: 17,
          bearing: driverRotation,
          tilt: 45,
        ),
      ),
    );
  }

  double _toRadians(double degree) => degree * pi / 180.0;

  /// Bearing in degrees from (lat1,lon1) → (lat2,lon2)
  double _getBearing(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final dLambda = _toRadians(lon2 - lon1);

    final y = sin(dLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda);
    return (atan2(y, x) * 180.0 / pi + 360.0) % 360.0;
  }

  void fitPolylineBounds(List<LatLng> coords) {
    if (coords.isEmpty) return;

    setMapFitToTour(Set<Polyline>.of(polylines.values));
  }

  void setMapFitToTour(Set<Polyline> p) {
    double minLat = p.first.points.first.latitude;
    double minLong = p.first.points.first.longitude;
    double maxLat = p.first.points.first.latitude;
    double maxLong = p.first.points.first.longitude;
    for (var poly in p) {
      for (var point in poly.points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLong) minLong = point.longitude;
        if (point.longitude > maxLong) maxLong = point.longitude;
      }
    }
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLong),
          northeast: LatLng(maxLat, maxLong),
        ),
        30,
      ),
    );
    mapController?.moveCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong)), 30));
  }
}
