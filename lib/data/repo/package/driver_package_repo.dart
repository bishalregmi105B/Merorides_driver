import 'package:ovoride_driver/data/model/global/response_model/response_model.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/core/utils/method.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';

class DriverPackageRepo {
  ApiClient apiClient;
  DriverPackageRepo({required this.apiClient});

  // Get assigned packages (updated to use new endpoint)
  Future<ResponseModel> getAssignedPackages() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesAssignedEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get package details (updated to use new endpoint)
  Future<ResponseModel> getPackageDetails(int userPackageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesDetailsEndpoint}/$userPackageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get package statistics (updated to use new endpoint)
  Future<ResponseModel> getStatistics() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesStatisticsEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Confirm package ride completion
  Future<ResponseModel> confirmPackageRide(int packageRideId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageRideConfirmEndpoint}/$packageRideId";
    return await apiClient.request(url, Method.postMethod, null, passHeader: true);
  }

  // Get pending confirmations
  Future<ResponseModel> getPendingConfirmations() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageRidePendingConfirmationsEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get active packages only
  Future<ResponseModel> getActivePackages() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packagesActiveEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get package schedule details
  Future<ResponseModel> getPackageSchedule(int userPackageId) async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.packageScheduleEndpoint}/$userPackageId";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get today's schedules
  Future<ResponseModel> getTodaySchedules() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.todaySchedulesEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }

  // Get weekly schedule overview
  Future<ResponseModel> getWeeklySchedule() async {
    String url = "${UrlContainer.baseUrl}${UrlContainer.weeklyScheduleEndpoint}";
    return await apiClient.request(url, Method.getMethod, null, passHeader: true);
  }
}
