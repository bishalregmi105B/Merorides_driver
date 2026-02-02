import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/core/utils/method.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';
import 'package:ovoride_driver/data/model/global/response_model/response_model.dart';

class DriverReservationRepo {
  ApiClient apiClient;
  DriverReservationRepo({required this.apiClient});

  // Get all assigned reservations
  Future<ResponseModel> getAssignedReservations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get upcoming reservations
  Future<ResponseModel> getUpcomingReservations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/upcoming";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get today's reservations
  Future<ResponseModel> getTodayReservations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/today";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get reservation details
  Future<ResponseModel> getReservationDetail(int id) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/show/$id";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Accept reservation ride
  Future<ResponseModel> acceptReservationRide(int id) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/accept-ride/$id";
    final response = await apiClient.request(url, Method.postMethod, null, passHeader: true);
    return response;
  }

  // Reject reservation ride
  Future<ResponseModel> rejectReservationRide(int id, String reason) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/reject-ride/$id";
    Map<String, dynamic> data = {'rejection_reason': reason};
    final response = await apiClient.request(url, Method.postMethod, data, passHeader: true);
    return response;
  }

  // Start reservation ride (create and activate a ride for a schedule)
  Future<ResponseModel> startReservationRide(int scheduleId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/start-ride/$scheduleId";
    final response = await apiClient.request(url, Method.postMethod, null, passHeader: true);
    return response;
  }

  // Get reservation statistics
  Future<ResponseModel> getReservationStats() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/stats";
    final response = await apiClient.request(url, Method.getMethod, null, passHeader: true);
    return response;
  }

  // Get weekly schedule for a reservation
  Future<ResponseModel> getWeeklySchedule(int reservationId, String weekStart) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.driverReservationEndpoint}/weekly-schedule";
    Map<String, dynamic> params = {
      'reservation_id': reservationId.toString(),
      'week_start': weekStart,
    };
    final response = await apiClient.request(url, Method.getMethod, params, passHeader: true);
    return response;
  }
}
