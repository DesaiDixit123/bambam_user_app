import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'app_pages.dart';

abstract class RouteManagement {
  static void gotoHomeScreen() => Get.offAllNamed<void>(Routes.homeScreen);
  static void goToInAppUpdateScreen(String appUrl) =>
      Get.offAllNamed<void>(Routes.inAppUpdateScreen, arguments: appUrl);
  static void gotoLoginScreen() => Get.toNamed<void>(Routes.loginScreen);
  static void gotoGetStartScreen() => Get.toNamed<void>(Routes.getStartScreen);
  static void gotoIntro1Screen() => Get.toNamed<void>(Routes.intro1Screen);
  static void gotoIntro2Screen() => Get.toNamed<void>(Routes.intro2Screen);
  static void gotoOtpVerifyScreen() =>
      Get.toNamed<void>(Routes.otpVerifyScreen);
  static void gotoBookingHistoryScreen(BuildContext context) =>
      Navigator.pushNamed(context, Routes.bookingHistoryScreen);
  //  Get.toNamed<void>(Routes.bookingHistoryScreen);
  static void gotoProfileScreen() => Get.toNamed<void>(Routes.profileScreen);
  //  static void gotoBottomBarScreenn(BuildContext ctx) =>Navigator.pushNamed(ctx, Routes.bottomBarScreen);
  static void gotoBottomBarScreen() =>
      Get.offAllNamed<void>(Routes.bottomBarScreen);
  static void gotoVehicalDetilesScreen() =>
      Get.toNamed<void>(Routes.vehicalDetilesScreen);
  static void gotoSelectVehicalScreen() =>
      Get.toNamed<void>(Routes.selectVehicalScreen);
  static void gotoSerchScreen() => Get.toNamed<void>(Routes.serchScreen);
  static void gotoCouponoffersScreen() =>
      Get.toNamed<void>(Routes.couponoffersScreen);
  static void gotoBookinghistoryDetilesScreen(
    bool isCancle,
    bool isAginbooking,
    bool isReview,
  ) => Get.toNamed<void>(
    Routes.bookinghistoryDetilesScreen,
    arguments: [isCancle, isAginbooking, isReview],
  );
  static void gotoPersonalDetilesScreen() =>
      Get.toNamed<void>(Routes.personalDetilesScreen);
  static void gotoTermsConditionsScreen() =>
      Get.toNamed<void>(Routes.termsConditionsScreen);
  static void gotoPrivcyPolicyScreen() =>
      Get.toNamed<void>(Routes.privcyPolicyScreen);
  static void gotoCreatTicketScreen() =>
      Get.toNamed<void>(Routes.creatTicketScreen);
  static void gotoTicketDetilesScreen() =>
      Get.toNamed<void>(Routes.ticketDetilesScreen);
  static void gotoMyTicketlistScreen() =>
      Get.toNamed<void>(Routes.myTicketlistScreen);
  static void gotoNotificationScreen() =>
      Get.toNamed<void>(Routes.notificationScreen);
  static void gotoNotificationDetailsScreen(dynamic notification) =>
      Get.toNamed<void>(Routes.notificationDetailsScreen, arguments: notification);
  static void gotoWalletScreen() => Get.toNamed<void>(Routes.walletScreen);
  static void gotoFaqScreen() => Get.toNamed<void>(Routes.faqScreen);

}
