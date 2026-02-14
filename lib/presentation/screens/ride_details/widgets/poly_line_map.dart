import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/data/controller/map/ride_map_controller.dart';

import '../../../../../environment.dart';

class PolyLineMapScreen extends StatefulWidget {
  const PolyLineMapScreen({super.key});

  @override
  State<PolyLineMapScreen> createState() => _PolyLineMapScreenState();
}

class _PolyLineMapScreenState extends State<PolyLineMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<RideMapController>(
        builder: (controller) {
          return Stack(
            children: [
              GoogleMap(
                trafficEnabled: false,
                indoorViewEnabled: false,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: true,
                myLocationEnabled: false, // We use our own driver marker
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: controller.pickupLatLng,
                  zoom: Environment.mapDefaultZoom,
                ),
                onMapCreated: (googleMapController) {
                  controller.mapController = googleMapController;
                  double southWestLat;
                  double southWestLong;
                  double northEastLat;
                  double northEastLong;

                  if (controller.pickupLatLng.latitude <= controller.destinationLatLng.latitude) {
                    southWestLat = controller.pickupLatLng.latitude;
                    northEastLat = controller.destinationLatLng.latitude;
                  } else {
                    northEastLat = controller.pickupLatLng.latitude;
                    southWestLat = controller.destinationLatLng.latitude;
                  }

                  if (controller.pickupLatLng.longitude <= controller.destinationLatLng.longitude) {
                    southWestLong = controller.pickupLatLng.longitude;
                    northEastLong = controller.destinationLatLng.longitude;
                  } else {
                    northEastLong = controller.pickupLatLng.longitude;
                    southWestLong = controller.destinationLatLng.longitude;
                  }
                  LatLngBounds bounds = LatLngBounds(
                    northeast: LatLng(northEastLat, northEastLong),
                    southwest: LatLng(southWestLat, southWestLong),
                  );

                  controller.mapController?.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 100),
                  );

                  // Start driver tracking once map is ready
                  controller.startDriverTracking();
                },
                onCameraMoveStarted: () {
                  // When user manually drags/zooms the map, pause auto-follow
                  // (the animateCamera calls set _cameraFollowsDriver internally)
                },
                markers: controller.getMarkers(
                  pickup: controller.pickupLatLng,
                  destination: controller.destinationLatLng,
                ),
                polylines: Set<Polyline>.of(controller.polylines.values),
              ),

              // Re-center on driver button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_driver',
                  backgroundColor: MyColor.colorWhite,
                  onPressed: () => controller.recenterOnDriver(),
                  child: Icon(
                    Icons.my_location,
                    color: MyColor.primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
