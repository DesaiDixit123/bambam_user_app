import 'dart:async';
import 'dart:io';

import 'package:bam_bam_user/domain/repositories/repositories.dart';
import 'package:get/get.dart';
import 'package:bam_bam_user/app/app.dart';

class SplashController extends GetxController {
  SplashController(this.splashPresenter);

  final SplashPresenter splashPresenter;

  @override
  void onInit() {
    super.onInit();
    startTimer();
  }

  String? appUrl;

void startTimer() async {
  final result = await Utility.checker.checkUpdate();

  Future.delayed(const Duration(seconds: 2)).then((value) {
    final repo = Get.find<Repository>();
    final accessToken = repo.getStringValue(LocalKeys.authToken);

   
   
    if (accessToken.isNotEmpty) {
      // ✅ This prints the actual saved token
      print("✅ User logged in. Access Token: $accessToken");

      // You can also show it in a snackbar for debugging if needed:
      // Utility.showMessage("Access Token: $accessToken", MessageType.information, null, "ok");

      RouteManagement.gotoBottomBarScreen();
    } else if( Get.find<Repository>().getBoolValue(LocalKeys.isIntro,)){
         RouteManagement.gotoLoginScreen();
      print("⚠️ No access token found. Redirecting to login...");
     
    }else{
        print("⚠️ No access token found. Redirecting to gotoIntro1Screen...");
       RouteManagement.gotoIntro1Screen();
    }
  });

  update();
}

}
