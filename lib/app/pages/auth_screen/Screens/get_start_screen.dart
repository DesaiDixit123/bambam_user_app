import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class GetStartScreen extends StatelessWidget {
  const GetStartScreen({super.key});

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
                  SvgPicture.asset(AssetConstants.get_start_icons),
                  Dimens.boxHeight100,
                  Text(
                    "get_startText1".tr,
                    style: Styles.txtBlackColorW70026,
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight8,
                  Text(
                    "get_startText2".tr,
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
              child: CustomButton(
                radius: Dimens.sixteen,
                isColor: true,

                onPressed: () {
                  Get.find<Repository>().saveValue(LocalKeys.isIntro, true);

                  RouteManagement.gotoLoginScreen();
                },
                text: 'get_started'.tr,
                textStyle: Styles.blackColorW50016,
                heightBtn: Dimens.fourtyEight,
                backgroundColor: ColorsValue.appColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
