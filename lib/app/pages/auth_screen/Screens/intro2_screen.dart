import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class Intro2Screen extends StatelessWidget {
  const Intro2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          body: SafeArea(
            child: Padding(
              padding: Dimens.edgeInsets20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        Get.find<Repository>().saveValue(
                          LocalKeys.isIntro,
                          true,
                        );
                        RouteManagement.gotoLoginScreen();
                      },
                      child: Text(
                        "skip".tr,
                        style: Styles.txtDrakBulyColorw40016,
                      ),
                    ),
                  ),
                  Dimens.boxHeight100,
                  SvgPicture.asset(AssetConstants.intro2_icons),
                  Dimens.boxHeight100,
                  Text(
                    "intro2_1".tr,
                    style: Styles.txtBlackColorW70026,
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight8,
                  Text(
                    "intro2_2".tr,
                    style: Styles.txtG5ColorsW40014,
                    textAlign: TextAlign.center,
                  ),
                  // Dimens.boxHeight90,
                  Spacer(),
                ],
              ),
            ),
          ),

          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: Dimens.edgeInsets20_30_20_30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      Get.find<Repository>().saveValue(LocalKeys.isIntro, true);
                      RouteManagement.gotoGetStartScreen();
                    },
                    child: Container(
                      height: Dimens.fourtyEight,
                      width: Dimens.fourtyEight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        color: ColorsValue.appColor,
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: ColorsValue.blackColor,
                        size: Dimens.twenty,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
