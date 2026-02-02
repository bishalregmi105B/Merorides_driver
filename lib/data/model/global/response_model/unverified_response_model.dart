import 'dart:convert';

import 'package:ovoride_driver/data/model/global/user/global_driver_model.dart';

UnVerifiedUserResponseModel unVarifiedUserResponseModelFromJson(String str) => UnVerifiedUserResponseModel.fromJson(json.decode(str));

class UnVerifiedUserResponseModel {
  String? remark;
  String? status;
  List<String>? message;
  Data? data;

  UnVerifiedUserResponseModel({
    this.remark,
    this.status,
    this.message,
    this.data,
  });

  factory UnVerifiedUserResponseModel.fromJson(Map<String, dynamic> json) => UnVerifiedUserResponseModel(
        remark: json["remark"],
        status: json["status"],
        message: json["message"] == null ? [] : List<String>.from(json["message"]!.map((x) => x)),
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );
}

class Data {
  String? isBan;
  String? emailVerified;
  String? mobileVerified;
  String? donationVerified;
  GlobalDriverInfoModel? driver;

  Data({this.isBan, this.emailVerified, this.mobileVerified, this.donationVerified, this.driver});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        isBan: json["is_ban"].toString(),
        emailVerified: json["email_verified"].toString(),
        mobileVerified: json["mobile_verified"].toString(),
        donationVerified: json["donation_verified"]?.toString() ?? "0",
        driver: json['driver'] != null ? GlobalDriverInfoModel.fromJson(json['driver']) : null,
      );

  Map<String, dynamic> toJson() => {
        "is_ban": isBan,
        "email_verified": emailVerified,
        "mobile_verified": mobileVerified,
        "donation_verified": donationVerified,
      };
}
