import 'dart:collection';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/widgets/droup_down_widgets.dart'
    show DroupDownButtonWigeat;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class PersonalDetilesScreen extends StatelessWidget {
  const PersonalDetilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return GetBuilder<ProfileController>(
      builder: (controller) {
        final dedupedItems = LinkedHashSet<String>.from(controller.cityList).toList();

// make sure selected value is valid and unique
final safeValue = (dedupedItems.where((e) => e == controller.selectedCity).length == 1)
    ? controller.selectedCity
    : null;
        return Scaffold(
          bottomSheet: Padding(
            padding: Dimens.edgeInsets20_30_20_30,
            child:CustomButton(
  onPressed: () async {
    if (controller.saveKey.currentState!.validate()) {
      await controller.updateProfile();
      // On success the controller.fetchProfile() will update UI; close the screen:
      Get.back();
      // don't clear controllers here — controller.fetchProfile will set latest values
    }
  },
  text: "Save".tr,
  textStyle: Styles.whiteColorW60016,
  isBorder: false,
  isColor: true,
  backgroundColor: ColorsValue.appColor,
),

          ),
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Personal Information",
          ),
          body: Form(
            key: controller.saveKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: PullToRefreshWrapper(
              onRefresh: () => controller.fetchProfile(showLoader: false),
              child: ListView(
              physics: kPullToRefreshScrollPhysics,
              padding: Dimens.edgeInsets20,
              children: [
                // above form fields in PersonalDetilesScreen:
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
              ? DecorationImage(image: FileImage(controller.profileImageFile!), fit: BoxFit.cover)
              : (controller.profileImageUrl.isNotEmpty
                  ? DecorationImage(image: NetworkImage(controller.profileImageUrl), fit: BoxFit.cover)
                  : null),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: InkWell(
          onTap: () {
            controller.pickProfileImage();
          },
          child: SvgPicture.asset(AssetConstants.ic_gallery),
        ),
      ),
    ],
  ),
),
Dimens.boxHeight20,

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
                    if (value!.isEmpty) {
                      return "enter_full_name".tr;
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
                  textEditingController: controller.emailController,
                  onChanged: (vaule) {
                    controller.update();
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "enter_email".tr;
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
                  onChanged: (vaule) {
                    controller.update();
                  },

                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "enter_phone_no".tr;
                    }
                    if (value.length < 10) {
                      return "Enter valid 10 digit phone number";
                    }
                    return null;
                  },

                  title: "phone_no".tr,
                  hintStyle: Styles.txtG7Colors40014,
                  titleStyle: Styles.black50014,
                ),
                Dimens.boxHeight16,
                DroupDownButtonWigeat<String>(
                  hintText: "Select State",
                  isTitle: true,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  items: controller.stateList,
                  value: controller.selectedState,
                  onChanged: (newValue) {
                    controller.selectedState = newValue;
                    controller.selectedCity = null; // reset city
                    controller.cityList.clear();
                    if (newValue != null) {
                      controller.fetchCities(newValue);
                    }
                    controller.update();
                  },
                  textStyle: Styles.txtBlackColorW40014,
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select a state";
                    }
                    return null;
                  },
                  title: "Select State",
                  hintStyle: Styles.txtG7Colors40014,
                  titleStyle: Styles.black50014,
                  isBorder: true,
                ),
                Dimens.boxHeight16,
                DroupDownButtonWigeat<String>(
                  hintText: "Select City",
                  isTitle: true,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                   items: dedupedItems,        // pass deduped list
  value: safeValue,          // pass safeValue
  onChanged: (newValue) {
    controller.selectedCity = newValue;
    controller.update();
  },

                  textStyle: Styles.txtBlackColorW40014,
                  isCompulsory: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select a city";
                    }
                    return null;
                  },
                  title: "Select City",
                  hintStyle: Styles.txtG7Colors40014,
                  titleStyle: Styles.black50014,
                  isBorder: true,
                ),
                Dimens.boxHeight16,
                CustomTextFormField(
                  hintText: "enter_code".tr,
                  isBorder: true,
                  isTitle: true,
                  style: Styles.txtBlackColorW40014,
                  textEditingController: controller.pinCodeController,
                  onChanged: (vaule) {
                    controller.update();
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "enter_code".tr;
                    }
                    if (value.length < 6) {
                      return "Enter valid 6 digit zip code";
                    }
                    return null;
                  },
                  title: "Pincode",
                  hintStyle: Styles.txtG7Colors40014,
                  titleStyle: Styles.black50014,
                ),
                Dimens.boxHeight36,
                Dimens.boxHeight36,
                Dimens.boxHeight36,
              ],
            ),
            ),
          ),
        );
      },
    );
  }
}
