import 'dart:io';

import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          body: PullToRefreshWrapper(
            onRefresh: () => controller.fetchProfile(showLoader: false),
            child: ListView(
                physics: kPullToRefreshScrollPhysics,
                children: [
              Dimens.boxHeight30,
              Center(
                child: Stack(
                  children: [
                    Container(
                      height: Dimens.hundred,
                      width: Dimens.hundred,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorsValue.bulycolorsCB,
                        image: controller.profileImageFile != null
                            ? DecorationImage(
                                image: FileImage(controller.profileImageFile!),
                                fit: BoxFit.cover,
                              )
                            : (controller.profileImageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        controller.profileImageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child:
                          (controller.profileImageFile == null &&
                              controller.profileImageUrl.isEmpty)
                          ? Center(
                              child: Image.asset(
                                AssetConstants.person,
                                height: Dimens.hundred,
                                width: Dimens.hundred,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () async {
                          // Open personal details screen so user can edit (or directly pick image)
                          // Option A: pick image directly:
                          await controller.pickProfileImage();
                          // Optionally call update immediately or let user go to Personal Details to save
                          // await controller.updateProfile();
                        },
                        child: SvgPicture.asset(AssetConstants.ic_edit_Imge),
                      ),
                    ),
                  ],
                ),
              ),

              Dimens.boxHeight60,
              ListTile(
                title: Text(
                  "personal_information".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoPersonalDetilesScreen();
                },
                leading: SvgPicture.asset(AssetConstants.User),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //     Divider(color: ColorsValue.borderColors, height: Dimens.one),
              ListTile(
                title: Text(
                  "privacy_policy".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoPrivcyPolicyScreen();
                },
                leading: SvgPicture.asset(AssetConstants.ic_privacy),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //     Divider(color: ColorsValue.borderColors, height: Dimens.one),
              ListTile(
                title: Text(
                  "terms_condition".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoTermsConditionsScreen();
                },
                leading: SvgPicture.asset(AssetConstants.ic_terms),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //      Divider(color: ColorsValue.borderColors, height: Dimens.one),
              ListTile(
                title: Text(
                  "support_feedback".tr,
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoMyTicketlistScreen();
                },
                leading: SvgPicture.asset(AssetConstants.ic_Headphones),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),

              ListTile(
                title: Text(
                  'FAQ',
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoFaqScreen();
                },
                leading: Icon(
                  Icons.quiz_outlined,
                  color: ColorsValue.primaryColor,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),

              ListTile(
                title: Text(
                  "Notifications",
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  RouteManagement.gotoNotificationScreen();
                },
                leading: Icon(
                  Icons.notifications_none,
                  color: ColorsValue.primaryColor,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              ListTile(
                title: Text(
                  "Delete Account",
                  style: Styles.txtRedColorW60016,
                ),
                onTap: () {
                  controller.showDeleteAccountDialog(context);
                },
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: ColorsValue.redColor,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              ListTile(
                title: Text(
                  "become a partner",
                  style: Styles.txtBlackColorW60016,
                ),
                onTap: () {
                  Utility.launchLinkURL("https://partner.bambamcabs.com/");
                },
                leading: Icon(Icons.bike_scooter),

                trailing: Icon(
                  Icons.arrow_forward_ios_sharp,
                  size: Dimens.seventeen,
                ),
              ),
              //     Divider(color: ColorsValue.borderColors, height: Dimens.one),
              Dimens.boxHeight40,
              Padding(
                padding: Dimens.edgeInsets20,
                child: Column(
                  children: [
                    CustomButton(
                      backgroundColor: ColorsValue.redColor,
                      isBorder: false,
                      onPressed: () {
                        controller.showLogoutDelog(context);
                      },
                      text: "Logout",
                      textStyle: Styles.whiteColorW60016,
                    ),
                    Dimens.boxHeight15,
                    // Deleted account option moved to settings for iOS and hidden for others
                  ],
                ),
              ),
                ],
              ),
          ),
        );
      },
    );
  }
}
