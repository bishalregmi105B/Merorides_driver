import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get/get.dart';
import 'package:ovoride_driver/core/helper/shared_preference_helper.dart';
import 'package:ovoride_driver/core/route/route.dart';
import 'package:ovoride_driver/core/utils/dimensions.dart';
import 'package:ovoride_driver/core/utils/my_color.dart';
import 'package:ovoride_driver/core/utils/url_container.dart';
import 'package:ovoride_driver/core/utils/method.dart';
import 'package:ovoride_driver/core/utils/style.dart';
import 'package:ovoride_driver/data/services/api_client.dart';
import 'package:ovoride_driver/presentation/components/buttons/rounded_button.dart';
import 'package:ovoride_driver/presentation/components/custom_loader/custom_loader.dart';
import 'package:ovoride_driver/presentation/components/snack_bar/show_custom_snackbar.dart';

import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VolunteerAgreementScreen extends StatefulWidget {
  const VolunteerAgreementScreen({super.key});

  @override
  State<VolunteerAgreementScreen> createState() => _VolunteerAgreementScreenState();
}

class _VolunteerAgreementScreenState extends State<VolunteerAgreementScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  bool _isLoading = true;
  String _agreementContent = '';

  // Fallback content if API fails
  static const String _fallbackContent = '''
<h3>Volunteer Driver Agreement & Liability Waiver</h3>
<p><strong>(Volunteer Ride Program)</strong></p>
<p>By registering as a volunteer driver with Mero Rides powered by Sparsha Yatayat, I acknowledge and agree to the following:</p>

<h4>1. Volunteer Status</h4>
<p>I understand that I am participating voluntarily and am not an employee of Mero Rides powered by Sparsha Yatayat.</p>

<h4>2. Insurance Requirement</h4>
<p>I carry valid auto insurance that meets Texas minimum legal requirements.</p>

<h4>3. Acknowledgment & Acceptance</h4>
<p>By signing, I confirm that I have read, understood, and voluntarily accept all terms.</p>
''';

  @override
  void initState() {
    super.initState();
    _loadAgreementContent();
    _signatureController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadAgreementContent() async {
    try {
      final ApiClient apiClient = Get.find();
      apiClient.initToken();
      String url = '${UrlContainer.baseUrl}${UrlContainer.agreementsEndPoint}';
      final response = await apiClient.request(url, Method.getMethod, null);

      if (response.statusCode == 200 && response.responseJson['status'] == 'success') {
        final data = response.responseJson['data'];
        if (data != null && data['driver_agreement'] != null) {
          var driverAgreement = data['driver_agreement'];

          // Handle case where driver_agreement is a JSON string
          if (driverAgreement is String) {
            try {
              driverAgreement = jsonDecode(driverAgreement);
            } catch (e) {
              debugPrint('Error decoding driver_agreement JSON: $e');
            }
          }

          if (driverAgreement is Map && driverAgreement['details'] != null) {
            setState(() {
              _agreementContent = driverAgreement['details'];
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading agreement content: $e');
    }

    // Fallback to hardcoded content
    setState(() {
      _agreementContent = _fallbackContent;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColor.getScreenBgColor(),
      appBar: AppBar(
        backgroundColor: MyColor.primaryColor,
        elevation: 0,
        title: Text(
          'Volunteer Agreement',
          style: boldLarge.copyWith(color: MyColor.colorWhite),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Dimensions.space15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Dimensions.space20),

              // Header
              Text(
                'Before you begin driving',
                style: boldExtraLarge.copyWith(
                  fontSize: Dimensions.fontOverLarge21,
                ),
              ),
              const SizedBox(height: Dimensions.space10),
              Text(
                'Please read and accept the following terms to continue as a community volunteer driver.',
                style: regularDefault.copyWith(
                  color: MyColor.getBodyTextColor(),
                ),
              ),

              const SizedBox(height: Dimensions.space30),

              // Agreement Text Scroll View
              Container(
                height: 400,
                padding: const EdgeInsets.all(Dimensions.space15),
                decoration: BoxDecoration(
                  color: MyColor.colorWhite,
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  border: Border.all(color: MyColor.borderColor, width: 1),
                ),
                child: _isLoading
                    ? const Center(child: CustomLoader())
                    : SingleChildScrollView(
                        child: HtmlWidget(
                          _agreementContent,
                          textStyle: regularDefault.copyWith(color: MyColor.getBodyTextColor()),
                        ),
                      ),
              ),

              const SizedBox(height: Dimensions.space30),

              // Date
              Text(
                "Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}",
                style: boldDefault,
              ),

              const SizedBox(height: Dimensions.space10),

              // Signature Label
              Text(
                "Driver's Signature (Required)",
                style: boldDefault,
              ),
              const SizedBox(height: Dimensions.space10),

              // Signature Pad
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: MyColor.borderColor, width: 1),
                  borderRadius: BorderRadius.circular(Dimensions.mediumRadius),
                  color: Colors.white,
                ),
                child: Signature(
                  controller: _signatureController,
                  height: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: Dimensions.space10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _signatureController.clear(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Clear"),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.space20),

              // Submit Button
              RoundedButton(
                text: "Accept and Continue",
                press: _signatureController.isNotEmpty ? () => _submitAgreement() : () {},
              ),

              const SizedBox(height: Dimensions.space30),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitAgreement() async {
    if (_signatureController.isEmpty) return;

    try {
      // Get signature as PNG bytes
      final signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) return;

      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final signaturePath = '${appDir.path}/driver_signature.png';

      // Save signature to file
      final file = File(signaturePath);
      await file.writeAsBytes(signatureBytes);

      // Store agreement accepted flag and signature path in SharedPreferences
      final apiClient = Get.find<ApiClient>();
      await apiClient.sharedPreferences.setBool(
        SharedPreferenceHelper.volunteerAgreementAcceptedKey,
        true,
      );
      await apiClient.sharedPreferences.setString(
        SharedPreferenceHelper.kycSignatureFile,
        signaturePath,
      );

      // Submit agreement to API using multipart request (backend expects file upload)
      String url = '${UrlContainer.baseUrl}${UrlContainer.driverAgreementUrl}';
      final response = await apiClient.multipartRequest(
        url,
        Method.postMethod,
        {
          'agreement_signed': '1',
        },
        files: {
          'kyc_signature': file, // Backend expects 'kyc_signature' as the file field name
        },
        passHeader: true,
      );

      debugPrint('Agreement submission response: ${response.statusCode} - ${response.responseJson}');

      if (response.statusCode == 200 && response.responseJson['status'] == 'success') {
        CustomSnackBar.success(successList: ['Agreement signed successfully!']);
        // Navigate to splash screen to re-run verification flow with fresh user data
        Get.offAllNamed(RouteHelper.splashScreen);
      } else {
        // Show error but still allow proceeding if local save succeeded
        final errorMessage = response.responseJson['message'] ?? ['Could not save agreement to server'];
        CustomSnackBar.error(errorList: errorMessage is List ? errorMessage.cast<String>() : [errorMessage.toString()]);
        // Navigate to splash screen to re-run verification flow
        Get.offAllNamed(RouteHelper.splashScreen);
      }
    } catch (e) {
      debugPrint('Error submitting agreement: $e');
      Get.offAllNamed(RouteHelper.splashScreen);
    }
  }
}
