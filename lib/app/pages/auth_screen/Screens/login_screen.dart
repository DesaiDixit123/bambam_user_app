import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/widgets/droup_down_widgets.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      initState: (state) {
        var controller = Get.find<AuthController>();
        controller.initializeFieldListeners();
      },

      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          body: SafeArea(
            child: Form(
              key: controller.singUpKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: Dimens.edgeInsets20,

                //physics: BouncingScrollPhysics(),
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      AssetConstants.bamBamLogo,
                      height: 80.0,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Dimens.boxHeight36,
                  if (controller.isLogin) ...[
                    Text(
                      "welcome_back".tr,
                      style: Styles.txtBlackColorW70026,
                      textAlign: TextAlign.center,
                    ),
                    Dimens.boxHeight4,
                    Text(
                      "logain_account".tr,
                      style: Styles.txtG5ColorsW40014,
                      textAlign: TextAlign.center,
                    ),
                  ] else ...[
                    Text(
                      "sign_up".tr,
                      style: Styles.txtBlackColorW70026,
                      textAlign: TextAlign.center,
                    ),
                    Dimens.boxHeight4,
                    Text(
                      "signUP_account".tr,
                      style: Styles.txtG5ColorsW40014,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  Dimens.boxHeight36,
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimens.twelve),
                      color: ColorsValue.bulycolorsCB,
                    ),
                    child: Padding(
                      padding: Dimens.edgeInsets4,
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            alignment: controller.isLogin ? Alignment.centerLeft : Alignment.centerRight,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: FractionallySizedBox(
                              widthFactor: 0.5,
                              heightFactor: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(Dimens.twelve),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    controller.isLogin = true;
                                    controller.update();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      style: controller.isLogin
                                          ? Styles.txtBlackColorW40014.copyWith(fontWeight: FontWeight.bold, fontSize: 16)
                                          : Styles.txtDrakBulyColorw40016.copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                                      child: Text("log_in".tr),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    controller.isLogin = false;
                                    controller.update();
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      style: !controller.isLogin
                                          ? Styles.txtBlackColorW40014.copyWith(fontWeight: FontWeight.bold, fontSize: 16)
                                          : Styles.txtDrakBulyColorw40016.copyWith(fontWeight: FontWeight.w500, fontSize: 16),
                                      child: Text("sign_up".tr),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (controller.isLogin) ...[
                    Dimens.boxHeight90,
                    CustomTextFormField(
                      style: Styles.txtBlackColorW40014,
                      hintText: "enter_phone_no".tr,
                      //filled: true,
                      isBorder: true,
                      isTitle: true,
                      textEditingController:
                          controller.logainMobileNumberController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your phone number";
                        }
                        if (value.trim().length != 10) {
                          return "Phone number must be exactly 10 digits";
                        }
                        return null;
                      },
                      title: "phone_no".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    Dimens.boxHeight36,
                    CustomButton(
                      onPressed: () async {
                        final phone = controller
                            .logainMobileNumberController
                            .text
                            .trim();
                        if (phone.isEmpty) {
                          Utility.showMessage(
                            'enter_phone_no'.tr,
                            MessageType.error,
                            null,
                            'ok',
                          );
                          return;
                        }

                        // call sendOtp (this stores phoneForOtp and receivedOtp in controller)
                        await controller.sendOtp(
                          phone: phone,
                          showLoader: true,
                        );

                        // navigate to OTP screen after API call (controller already stores phone & otp)
                      },
                      text: "log_in".tr,
                      textStyle:
                          controller
                              .logainMobileNumberController
                              .text
                              .isNotEmpty
                          ? Styles.whiteColorW70014.copyWith(fontSize: 16)
                          : Styles.txtBlackColorW40014.copyWith(fontSize: 16, color: Colors.black54),
                      isBorder: false,
                      isColor: true,
                      backgroundColor:
                          controller
                              .logainMobileNumberController
                              .text
                              .isNotEmpty
                          ? ColorsValue.appColor
                          : ColorsValue.bulycolorsCB,
                    ),

                    Dimens.boxHeight24,
                    Row(
                      spacing: Dimens.ten,
                      children: [
                        Expanded(
                          child: Container(
                            height: Dimens.two,
                            color: ColorsValue.bulycolorsCB,
                          ),
                        ),
                        Text("or".tr, style: Styles.txtG7Colors40014),
                        Expanded(
                          child: Container(
                            height: Dimens.two,
                            color: ColorsValue.bulycolorsCB,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight24,
                    CustomButton(
                      onPressed: () async {
                        Get.find<AuthController>().signInWithGoogle(
                          isSignup: false,
                        );
                      },
                      leading: SvgPicture.asset(AssetConstants.ic_google),
                      text: "con_google".tr,
                      textStyle: Styles.txtBlackColorW40014,
                      isBorder: true,
                      //isColor: true,
                      backgroundColor: ColorsValue.whiteColor,
                      bordercolors: ColorsValue.borderColors,
                      isboxsedo: true,
                    ),
                    Dimens.boxHeight15,
                    CustomButton(
                      onPressed: () async {
                        await Get.find<AuthController>().signInWithFacebook(
                          isSignup: controller.isLogin ? false : true,
                        );
                      },
                      leading: SvgPicture.asset(AssetConstants.ic_facebook),
                      text: "con_facebook".tr,
                      textStyle: Styles.txtBlackColorW40014,
                      isBorder: true,
                      bordercolors: ColorsValue.borderColors,
                      backgroundColor: ColorsValue.whiteColor,
                      isboxsedo: true,
                    ),
                    if (Platform.isIOS) ...[
                      Dimens.boxHeight15,
                      SizedBox(
                        height: 55,
                        child: SignInWithAppleButton(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          onPressed: () async {
                            await Get.find<AuthController>().signInWithApple(
                              isSignup: controller.isLogin ? false : true,
                            );
                          },
                        ),
                      ),
                    ],
                  ] else ...[
                    Dimens.boxHeight36,
                    CustomButton(
                      onPressed: () async {
                        Get.find<AuthController>().signInWithGoogle(
                          isSignup: controller.isLogin ? false : true,
                        );
                      },
                      leading: SvgPicture.asset(AssetConstants.ic_google),
                      text: "con_google".tr,
                      textStyle: Styles.txtBlackColorW40014,
                      isBorder: true,
                      //isColor: true,
                      backgroundColor: ColorsValue.whiteColor,
                      bordercolors: ColorsValue.borderColors,
                      isboxsedo: true,
                    ),
                    Dimens.boxHeight15,
                    CustomButton(
                      onPressed: () async {
                        await Get.find<AuthController>().signInWithFacebook(
                          isSignup: controller.isLogin ? false : true,
                        );
                      },
                      leading: SvgPicture.asset(AssetConstants.ic_facebook),
                      text: "con_facebook".tr,
                      textStyle: Styles.txtBlackColorW40014,
                      isBorder: true,
                      bordercolors: ColorsValue.borderColors,
                      backgroundColor: ColorsValue.whiteColor,
                      isboxsedo: true,
                    ),
                    if (Platform.isIOS) ...[
                      Dimens.boxHeight15,
                      SizedBox(
                        height: 55,
                        child: SignInWithAppleButton(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(12),
                          ),
                          onPressed: () async {
                            await Get.find<AuthController>().signInWithApple(
                              isSignup: controller.isLogin ? false : true,
                            );
                          },
                        ),
                      ),
                    ],
                    Dimens.boxHeight36,
                    Row(
                      spacing: Dimens.ten,
                      children: [
                        Expanded(
                          child: Container(
                            height: Dimens.two,
                            color: ColorsValue.bulycolorsCB,
                          ),
                        ),
                        Text("or".tr, style: Styles.txtG7Colors40014),
                        Expanded(
                          child: Container(
                            height: Dimens.two,
                            color: ColorsValue.bulycolorsCB,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight36,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            InkWell(
                              onTap: () {
                                controller.pickProfileImage();
                              },
                              child: Container(
                                height: Dimens.seventy,
                                width: Dimens.seventy,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: ColorsValue.bulycolorsCB,
                                  image: controller.profileImageFile != null
                                      ? DecorationImage(
                                          image: FileImage(
                                            controller.profileImageFile!,
                                          ),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: controller.profileImageFile == null
                                    ? Center(
                                        child: SvgPicture.asset(
                                          AssetConstants.ic_user,
                                        ),
                                      )
                                    : null,
                              ),
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: SvgPicture.asset(
                                AssetConstants.ic_gallery,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      style: Styles.txtBlackColorW40014,
                      hintText: "enter_full_name".tr,
                      isBorder: true,
                      isTitle: true,
                      textEditingController: controller.fullNameController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      isCompulsory: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your full name";
                        }
                        return null;
                      },
                      title: "full_name".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      style: Styles.txtBlackColorW40014,
                      hintText: "enter_email".tr,
                      isBorder: true,
                      isTitle: true,
                      keyboardType: TextInputType.emailAddress,
                      textEditingController: controller.emailController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your email";
                        }
                        if (!GetUtils.isEmail(value)) {
                          return "Please enter a valid email address";
                        }
                        return null;
                      },
                      title: "email".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      hintText: "enter_phone_no".tr,
                      isBorder: true,
                      isTitle: true,
                      style: Styles.txtBlackColorW40014,
                      textEditingController: controller.phoneNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (vaule) {
                        controller.update();
                      },
                      isCompulsory: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your phone number";
                        }
                        if (value.trim().length != 10) {
                          return "Phone number must be exactly 10 digits";
                        }
                        return null;
                      },
                      title: "phone_no".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    Dimens.boxHeight16,
                    controller.isFetchingStates
                        ? const Center(child: CircularProgressIndicator())
                        : DroupDownButtonWigeat<String>(
                            hintText: "Select State",
                            isTitle: true,
                            borderRadius: BorderRadius.circular(Dimens.twelve),
                            items: controller.stateList,
                            value: controller.selectedState.isNotEmpty ? controller.selectedState : null,
                            onChanged: (newValue) {
                              if (newValue != null && newValue.isNotEmpty) {
                                controller.selectedState = newValue;
                                controller.fetchCities(newValue);
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please select a state";
                              }
                              return null;
                            },
                            textStyle: Styles.txtBlackColorW40014,
                            isCompulsory: true,
                            title: "Select State",
                            hintStyle: Styles.txtG7Colors40014,
                            titleStyle: Styles.black50014,
                            isBorder: true,
                          ),
                    Dimens.boxHeight16,
                    controller.isFetchingCities
                        ? const Center(child: CircularProgressIndicator())
                        : DroupDownButtonWigeat<String>(
                            hintText: "Select City",
                            isTitle: true,
                            borderRadius: BorderRadius.circular(Dimens.twelve),
                            items: controller.cityList,
                            value: controller.selectedCity.isNotEmpty ? controller.selectedCity : null,
                            onChanged: (newValue) {
                              controller.selectedCity = newValue ?? "";
                              controller.update();
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please select a city";
                              }
                              return null;
                            },
                            textStyle: Styles.txtBlackColorW40014,
                            isCompulsory: true,
                            title: "Select City",
                            hintStyle: Styles.txtG7Colors40014,
                            titleStyle: Styles.black50014,
                            isBorder: true,
                          ),
                    Dimens.boxHeight16,
                    CustomTextFormField(
                      hintText: "Enter Pin Code",
                      isBorder: true,
                      isTitle: true,
                      style: Styles.txtBlackColorW40014,
                      textEditingController: controller.pinCodeController,
                      onChanged: (vaule) {
                        controller.update();
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a pin code";
                        }
                        if (value.trim().length != 6) {
                          return "Pin code must be exactly 6 digits";
                        }
                        return null;
                      },
                      title: "Pin Code",
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    Dimens.boxHeight36,
                    CustomButton(
                      onPressed: () async {
                        await controller.signUp();
                      },
                      text: "sign_up".tr,
                      textStyle:
                          controller.singUpKey.currentState?.validate() == true
                          ? Styles.whiteColorW70014.copyWith(fontSize: 16)
                          : Styles.txtBlackColorW40014.copyWith(fontSize: 16, color: Colors.black54),
                      isBorder: false,
                      isColor: true,
                      backgroundColor:
                          controller.singUpKey.currentState?.validate() == true
                          ? ColorsValue.appColor
                          : ColorsValue.bulycolorsCB,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
