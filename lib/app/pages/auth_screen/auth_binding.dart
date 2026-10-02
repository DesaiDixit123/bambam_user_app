import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:bam_bam_user/domain/usecases/auth_usecases.dart';
import 'package:get/get.dart';

import 'package:bam_bam_user/app/app.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Put ApiWrapper as a singleton (or lazyPut if you prefer)
    Get.put<ApiWrapper>(ApiWrapper(), permanent: true);

    // Provide AuthPresenter with ApiWrapper
    Get.lazyPut<AuthPresenter>(
      () => AuthPresenter(Get.find<ApiWrapper>()),
      fenix: true,
    );

    // Keep AuthController instance across auth screens (Login, Signup, OtpVerify)
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(
        () => AuthController(Get.find<AuthPresenter>()),
        fenix: true,
      );
    }
  }
}
