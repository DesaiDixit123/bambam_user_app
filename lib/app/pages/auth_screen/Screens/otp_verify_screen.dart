import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpVerifyScreen extends StatelessWidget {
  const OtpVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "",
            isVisible: true,
          ),
          body: Form(
            key: controller.otpKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              padding: Dimens.edgeInsets20,
              children: [
                
                Text(
                  "otp_very".tr,
                  style: Styles.txtBlackColorW70026,
                  textAlign: TextAlign.center,
                ),
                Dimens.boxHeight5,
                Text(
                  "Enter OTP sent to ${controller.phoneForOtp} to continue login to your account",
                  textAlign: TextAlign.center,
                  style: Styles.txtG5ColorsW40016,
                ),
                Dimens.boxHeight90,
                SvgPicture.asset(AssetConstants.otp),
             
                // Show server OTP (if present) — helpful for testing/dev

 
  Dimens.boxHeight16,

                Text("otp".tr, style: Styles.black50014),
                Dimens.boxHeight10,
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  autoFocus: true,
                  hintCharacter: "0",
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    activeColor: ColorsValue.borderColors,
                    selectedColor: ColorsValue.borderColors,
                    inactiveColor: ColorsValue.borderColors,
                    errorBorderColor: Colors.red,
                    selectedFillColor: ColorsValue.whiteColor,
                    inactiveFillColor: ColorsValue.whiteColor,
                    activeFillColor: ColorsValue.whiteColor,
                    borderWidth: 1,
                    borderRadius: BorderRadius.circular(Dimens.twenty),

                    fieldHeight: Get.width / 8,
                    fieldWidth: Get.width / 8,
                  ),
                  cursorColor: ColorsValue.appColor,
                  enableActiveFill: true,
                  keyboardType: TextInputType.number,
                  errorTextMargin: const EdgeInsets.only(top: 20),
                  errorTextSpace: 25,
                  boxShadows: const [
                    BoxShadow(
                      offset: Offset(0, 1),
                      color: Colors.black12,
                      blurRadius: 2,
                    ),
                  ],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Enter Otp".tr;
                    } else if (value.length != 6) {
                      return "Enter Valid Otp".tr;
                    } else {
                      return null;
                    }
                  },
                  onCompleted: (pin) {
                    controller.code = pin;
                  },
                  onChanged: (value) {
                    debugPrint(value);
                  },
                  beforeTextPaste: (text) {
                    debugPrint("Allowing to paste $text");
                    return true;
                  },
                ),
                Dimens.boxHeight36,
               // inside ListView children (place after PinCodeTextField and spacing)
Dimens.boxHeight8,

Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text("did not receive".tr, style: Styles.black50014),
    Dimens.boxWidth8,
    Obx(() {
      final seconds = controller.resendCooldown.value;
      if (seconds > 0) {
        return Text(
          // fallback to plain string if you don't use trParams
          "Resend in ${seconds}s",
          // or if you have localization key: "resend_in".trParams({'sec': seconds.toString()})
          style: Styles.black50014.copyWith(color: ColorsValue.borderColors),
        );
      } else {
        return TextButton(
          onPressed: () async {
            final phone = controller.phoneForOtp.isNotEmpty
                ? controller.phoneForOtp
                : (AuthController.savedPhoneForOtp.isNotEmpty
                    ? AuthController.savedPhoneForOtp
                    : (controller.logainMobileNumberController.text.trim().isNotEmpty
                        ? controller.logainMobileNumberController.text.trim()
                        : controller.phoneNumberController.text.trim()));

            if (phone.isEmpty) {
              Utility.showMessage('Phone number not available', MessageType.error, null, 'ok');
              return;
            }

            await controller.sendOtp(phone: phone, showLoader: true);
            // startResendCooldown is called inside sendOtp on success
          },
          child: Text("resend".tr, style: Styles.txtBlackColorW40014),
        );
      }
    }),
  ],
),

Dimens.boxHeight36,
CustomButton(
  onPressed: () {
    if (controller.otpKey.currentState!.validate()) {
      controller.verifyOtp();
    }
  },
  text: "verify".tr,
  textStyle: Styles.txtBlackColorW40014,
  isBorder: false,
  isColor: true,
  backgroundColor: ColorsValue.appColor,
),

              ],
            ),
          ),
        );
      },
    );
  }
}
