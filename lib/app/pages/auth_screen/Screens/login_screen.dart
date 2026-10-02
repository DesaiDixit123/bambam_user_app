import 'dart:async';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';
import 'package:bam_bam_user/app/utils/strings/string_constants.dart';
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
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            if (!controller.isLogin) {
              controller.isLogin = true;
              controller.update();
              return;
            }
            _showExitDialog(context);
          },
          child: Scaffold(
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
                      onPressed: () {
                        controller.signInWithGoogle(
                          isSignup: false,
                        );
                      },
                      isLoading: controller.isSigningIn,
                      leading: SvgPicture.asset(AssetConstants.ic_google),
                      text: "con_google".tr,
                      textStyle: Styles.txtBlackColorW40014,
                      isBorder: true,
                      //isColor: true,
                      backgroundColor: ColorsValue.whiteColor,
                      bordercolors: ColorsValue.borderColors,
                      isboxsedo: true,
                    ),
                    // Dimens.boxHeight15,
                    // CustomButton(
                    //   onPressed: () {
                    //     controller.signInWithFacebook(
                    //       isSignup: false,
                    //     );
                    //   },
                    //   leading: SvgPicture.asset(AssetConstants.ic_facebook),
                    //   text: "con_facebook".tr,
                    //   textStyle: Styles.txtBlackColorW40014,
                    //   isBorder: true,
                    //   bordercolors: ColorsValue.borderColors,
                    //   backgroundColor: ColorsValue.whiteColor,
                    //   isboxsedo: true,
                    // ),
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
                      onPressed: () {
                        controller.signInWithGoogle(
                          isSignup: true,
                        );
                      },
                      isLoading: controller.isSigningIn,
                      leading: SvgPicture.asset(AssetConstants.ic_google),
                      text: "con_google".tr,
                      textStyle: Styles.txtBlackColorW40014,
                      isBorder: true,
                      //isColor: true,
                      backgroundColor: ColorsValue.whiteColor,
                      bordercolors: ColorsValue.borderColors,
                      isboxsedo: true,
                    ),
                    // Dimens.boxHeight15,
                    // CustomButton(
                    //   onPressed: () {
                    //     controller.signInWithFacebook(
                    //       isSignup: true,
                    //     );
                    //   },
                    //   leading: SvgPicture.asset(AssetConstants.ic_facebook),
                    //   text: "con_facebook".tr,
                    //   textStyle: Styles.txtBlackColorW40014,
                    //   isBorder: true,
                    //   bordercolors: ColorsValue.borderColors,
                    //   backgroundColor: ColorsValue.whiteColor,
                    //   isboxsedo: true,
                    // ),
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
                        if (value != null && value.trim().isNotEmpty) {
                          if (!GetUtils.isEmail(value.trim())) {
                            return "Please enter a valid email address";
                          }
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
                        controller.onSignupPhoneChanged(vaule);
                      },
                      isCompulsory: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter your phone number";
                        }
                        if (value.trim().length != 10) {
                          return "Phone number must be exactly 10 digits";
                        }
                        if (controller.isPhoneAlreadyRegistered) {
                          return "This phone number is already registered. Please login.";
                        }
                        return null;
                      },
                      title: "phone_no".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    if (controller.isPhoneAlreadyRegistered) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "This number is already registered. Please login instead.",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                controller.isLogin = true;
                                controller.logainMobileNumberController.text =
                                    controller.phoneNumberController.text.trim();
                                controller.update();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: ColorsValue.appColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Dimens.boxHeight16,
                    _buildPickerField(
                      title: "Select State",
                      value: controller.selectedState,
                      hintText: "Select State",
                      isLoading: controller.isFetchingStates,
                      onTap: () {
                        _showStateBottomSheet(context, controller);
                      },
                    ),
                    Dimens.boxHeight16,
                    _buildPickerField(
                      title: "Select City",
                      value: controller.selectedCity,
                      hintText: "Select City",
                      isLoading: controller.isFetchingCities,
                      onTap: () {
                        if (controller.selectedState.isEmpty) {
                          Utility.showMessage("Please select State first", MessageType.information, null, "OK");
                          return;
                        }
                        _showCityBottomSheet(context, controller);
                      },
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
                        if (value != null && value.trim().isNotEmpty) {
                          if (value.trim().length != 6) {
                            return "Pin code must be exactly 6 digits";
                          }
                        }
                        return null;
                      },
                      title: "Pin Code",
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                    ),
                    Dimens.boxHeight36,
                    CustomButton(
                      onPressed: controller.isSignupFormValid
                          ? () async {
                              await controller.signUp();
                            }
                          : null,
                      text: "sign_up".tr,
                      textStyle: controller.isSignupFormValid
                          ? Styles.whiteColorW70014.copyWith(fontSize: 16)
                          : Styles.txtBlackColorW40014.copyWith(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                      isBorder: false,
                      isColor: controller.isSignupFormValid,
                      backgroundColor: controller.isSignupFormValid
                          ? ColorsValue.appColor
                          : ColorsValue.bulycolorsCB,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildPickerField({
    required String title,
    required String? value,
    required String hintText,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Styles.black50014),
        Dimens.boxHeight5,
        InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(Dimens.twelve),
          child: Container(
            width: double.infinity,
            padding: Dimens.edgeInsets12_14_12_14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Dimens.twelve),
              border: Border.all(width: 0.8, color: ColorsValue.borderColors),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? value : hintText,
                    style: hasValue ? Styles.txtBlackColorW40014 : Styles.txtG7Colors40014,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStateBottomSheet(BuildContext context, AuthController controller) {
    if (controller.stateList.isEmpty && !controller.isFetchingStates) {
      controller.fetchStates();
    }
    final TextEditingController searchCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardOpen = bottomInset > 0;
            final screenHeight = MediaQuery.of(context).size.height;
            final query = searchCtrl.text.trim().toLowerCase();
            final filteredStates = query.isEmpty
                ? controller.stateList
                : controller.stateList
                    .where((s) => s.toLowerCase().contains(query))
                    .toList();

            final sheetHeight = isKeyboardOpen
                ? (screenHeight * 0.90 - bottomInset).clamp(320.0, screenHeight * 0.88)
                : (query.isNotEmpty ? screenHeight * 0.72 : screenHeight * 0.55);

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottomInset),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Container(
                height: sheetHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
                      child: Row(
                        children: [
                          const Text(
                            "Select State",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          hintText: "Search State...",
                          hintStyle: Styles.txtG7Colors40014,
                          prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                          suffixIcon: searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Colors.black54),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setSheetState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: ColorsValue.appColor, width: 1.5),
                          ),
                        ),
                        onChanged: (_) {
                          setSheetState(() {});
                        },
                      ),
                    ),
                    if (query.isEmpty) ...[
                      InkWell(
                        onTap: () async {
                          Navigator.pop(ctx);
                          await controller.detectAndFillLocation();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: ColorsValue.appColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.my_location, color: ColorsValue.appColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Use your current location",
                                      style: TextStyle(
                                        color: ColorsValue.appColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Auto-detect state, city & pincode via GPS",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: ColorsValue.appColor),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    const SizedBox(height: 6),
                  Expanded(
                    child: controller.isFetchingStates
                        ? const Center(child: CircularProgressIndicator())
                        : filteredStates.isEmpty
                            ? Center(
                                child: Text(
                                  "No state found",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: filteredStates.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                itemBuilder: (context, index) {
                                  final stateName = filteredStates[index];
                                  final isSelected = controller.selectedState.toLowerCase() == stateName.toLowerCase();
                                  return ListTile(
                                    title: Text(
                                      stateName,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                        color: isSelected ? ColorsValue.appColor : Colors.black87,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(Icons.check_circle, color: ColorsValue.appColor, size: 20)
                                        : null,
                                    onTap: () {
                                      controller.selectedState = stateName;
                                      controller.selectedCity = "";
                                      controller.fetchCities(stateName);
                                      controller.update();
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  }

  void _showCityBottomSheet(BuildContext context, AuthController controller) {
    final TextEditingController searchCtrl = TextEditingController();
    List<String> googleSuggestions = [];
    bool isSearchingGoogle = false;
    Timer? debounce;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isKeyboardOpen = bottomInset > 0;
            final screenHeight = MediaQuery.of(context).size.height;
            final query = searchCtrl.text.trim().toLowerCase();

            final filteredCities = query.isEmpty
                ? controller.cityList
                : controller.cityList
                    .where((c) => c.toLowerCase().contains(query))
                    .toList();

            final combinedList = <String>[...filteredCities];
            for (var g in googleSuggestions) {
              if (!combinedList.any((c) => c.toLowerCase() == g.toLowerCase())) {
                combinedList.add(g);
              }
            }

            final sheetHeight = isKeyboardOpen
                ? (screenHeight * 0.90 - bottomInset).clamp(320.0, screenHeight * 0.88)
                : (query.isNotEmpty ? screenHeight * 0.72 : screenHeight * 0.55);

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottomInset),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Container(
                height: sheetHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Select City (${controller.selectedState})",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () {
                            debounce?.cancel();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: "Search City...",
                        hintStyle: Styles.txtG7Colors40014,
                        prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                        suffixIcon: isSearchingGoogle
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Colors.black54),
                                    onPressed: () {
                                      searchCtrl.clear();
                                      googleSuggestions.clear();
                                      setSheetState(() {});
                                    },
                                  )
                                : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: ColorsValue.appColor, width: 1.5),
                        ),
                      ),
                      onChanged: (text) {
                        setSheetState(() {});
                        debounce?.cancel();
                        if (text.trim().length >= 2) {
                          debounce = Timer(const Duration(milliseconds: 350), () async {
                            setSheetState(() => isSearchingGoogle = true);
                            final results = await GooglePlacesHelper.searchCities(
                              text.trim(),
                              StringConstants.gpooglePlaceKey,
                              stateName: controller.selectedState,
                            );
                            if (context.mounted) {
                              setSheetState(() {
                                googleSuggestions = results;
                                isSearchingGoogle = false;
                              });
                            }
                          });
                        } else {
                          googleSuggestions.clear();
                          isSearchingGoogle = false;
                          setSheetState(() {});
                        }
                      },
                    ),
                  ),
                    if (query.isEmpty) ...[
                      InkWell(
                        onTap: () async {
                          debounce?.cancel();
                          Navigator.pop(ctx);
                          await controller.detectAndFillLocation();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: ColorsValue.appColor.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.my_location, color: ColorsValue.appColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Use your current location",
                                      style: TextStyle(
                                        color: ColorsValue.appColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Auto-detect state, city & pincode via GPS",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: ColorsValue.appColor),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                    const SizedBox(height: 6),
                    Expanded(
                      child: controller.isFetchingCities
                          ? const Center(child: CircularProgressIndicator())
                          : combinedList.isEmpty
                              ? Center(
                                  child: Text(
                                    "No city found",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  itemCount: combinedList.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                  itemBuilder: (context, index) {
                                    final cityName = combinedList[index];
                                    final isSelected = controller.selectedCity.toLowerCase() == cityName.toLowerCase();
                                    return ListTile(
                                      title: Text(
                                        cityName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                          color: isSelected ? ColorsValue.appColor : Colors.black87,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? Icon(Icons.check_circle, color: ColorsValue.appColor, size: 20)
                                          : null,
                                      onTap: () {
                                        controller.selectedCity = cityName;
                                        controller.update();
                                        debounce?.cancel();
                                        Navigator.pop(ctx);
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ColorsValue.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.sixteen),
        ),
        title: Text(
          "Exit App",
          style: Styles.txtBlackColorW70018,
        ),
        content: Text(
          "Are you sure you want to exit the app?",
          style: Styles.txtBlackColorW40014,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: Styles.txtG7Colors40014,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsValue.appColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimens.eight),
              ),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SystemNavigator.pop();
            },
            child: Text(
              "Exit",
              style: Styles.whiteColorW60016.copyWith(fontSize: Dimens.fourteen),
            ),
          ),
        ],
      ),
    );
  }
}
