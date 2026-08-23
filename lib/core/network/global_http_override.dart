import 'package:bam_bam_user/app/navigators/app_pages.dart';
import 'package:bam_bam_user/app/navigators/routes_management.dart';
import 'package:bam_bam_user/app/pages/auth_screen/Screens/login_screen.dart';
import 'package:bam_bam_user/domain/repositories/repository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class InterceptorClient extends http.BaseClient {
  final http.Client _inner;

  InterceptorClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);

    // Intercept 401 here
    if (response.statusCode == 401) {
      final repo = Get.find<Repository>();

      print("🔐 GLOBAL INTERCEPTOR → 401 detected");

      await repo.deleteAllSecuredValues();

      print("🧹 Token cleared → navigating to login screen");

      Get.offAllNamed(Routes.loginScreen);
    }

    return response;
  }
}
