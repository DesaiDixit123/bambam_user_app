import 'dart:async';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class PersonalDetilesScreen extends StatelessWidget {
  const PersonalDetilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "Personal Information",
          ),
          bottomSheet: Container(
            color: ColorsValue.appBg,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: CustomButton(
              onPressed: () async {
                if (controller.isCheckingPhone) {
                  Utility.showMessage("Please wait, checking phone number...", MessageType.information, null, "OK");
                  return;
                }
                if (controller.isPhoneAlreadyRegistered) {
                  Utility.showMessage("This phone number is already registered with another account.", MessageType.error, null, "OK");
                  return;
                }
                if (controller.saveKey.currentState!.validate()) {
                  if (controller.selectedState == null || controller.selectedState!.isEmpty) {
                    Utility.showMessage("Please select a state", MessageType.error, null, "OK");
                    return;
                  }
                  if (controller.selectedCity == null || controller.selectedCity!.isEmpty) {
                    Utility.showMessage("Please select a city", MessageType.error, null, "OK");
                    return;
                  }
                  await controller.updateProfile();
                  Get.back();
                }
              },

              text: "Save",
              textStyle: Styles.whiteColorW60016,
              isBorder: false,
              isColor: true,
              backgroundColor: ColorsValue.appColor,
            ),
          ),
          body: Form(
            key: controller.saveKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: PullToRefreshWrapper(
              onRefresh: () => controller.fetchProfile(showLoader: false),
              child: ListView(
                physics: kPullToRefreshScrollPhysics,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
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
                                        image: NetworkImage(controller.profileImageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: (controller.profileImageFile == null && controller.profileImageUrl.isEmpty)
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
                            onTap: () {
                              controller.pickProfileImage();
                            },
                            child: SvgPicture.asset(AssetConstants.ic_gallery),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Dimens.boxHeight24,

                  // Full Name
                  CustomTextFormField(
                    style: Styles.txtBlackColorW40014,
                    hintText: "enter_full_name".tr,
                    isBorder: true,
                    isTitle: true,
                    textEditingController: controller.fullNameController,
                    onChanged: (_) => controller.update(),
                    isCompulsory: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "enter_full_name".tr;
                      }
                      return null;
                    },
                    title: "full_name".tr,
                    hintStyle: Styles.txtG7Colors40014,
                    titleStyle: Styles.black50014,
                  ),
                  Dimens.boxHeight16,

                  // Email
                  CustomTextFormField(
                    style: Styles.txtBlackColorW40014,
                    hintText: "enter_email".tr,
                    isBorder: true,
                    isTitle: true,
                    textEditingController: controller.emailController,
                    onChanged: (_) => controller.update(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "enter_email".tr;
                      }
                      return null;
                    },
                    title: "email".tr,
                    hintStyle: Styles.txtG7Colors40014,
                    titleStyle: Styles.black50014,
                  ),
                  Dimens.boxHeight16,

                  // Phone Number
                  CustomTextFormField(
                    hintText: "enter_phone_no".tr,
                    isBorder: true,
                    isTitle: true,
                    style: Styles.txtBlackColorW40014,
                    textEditingController: controller.phoneNumberController,
                    onChanged: (value) => controller.onPhoneChanged(value),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    isCompulsory: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "enter_phone_no".tr;
                      }
                      if (value.trim().length != 10) {
                        return "Enter valid 10 digit phone number";
                      }
                      if (controller.isPhoneAlreadyRegistered) {
                        return "This phone number is already registered with another account.";
                      }
                      return null;
                    },
                    title: "phone_no".tr,
                    hintStyle: Styles.txtG7Colors40014,
                    titleStyle: Styles.black50014,
                  ),
                  if (controller.isCheckingPhone) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorsValue.appColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(

                          "Checking phone number availability...",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                              "This phone number is already registered with another account.",
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Dimens.boxHeight16,


                  // Select State Picker Field
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

                  // Select City Picker Field
                  _buildPickerField(
                    title: "Select City",
                    value: controller.selectedCity,
                    hintText: "Select City",
                    isLoading: controller.isFetchingCities,
                    onTap: () {
                      if (controller.selectedState == null || controller.selectedState!.isEmpty) {
                        Utility.showMessage("Please select State first", MessageType.information, null, "OK");
                        return;
                      }
                      _showCityBottomSheet(context, controller);
                    },
                  ),
                  Dimens.boxHeight16,

                  // Pincode
                  CustomTextFormField(
                    hintText: "enter_code".tr,
                    isBorder: true,
                    isTitle: true,
                    style: Styles.txtBlackColorW40014,
                    textEditingController: controller.pinCodeController,
                    onChanged: (_) => controller.update(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (value.trim().length != 6) {
                          return "Enter valid 6 digit zip code";
                        }
                      }
                      return null;
                    },
                    title: "Pincode",
                    hintStyle: Styles.txtG7Colors40014,
                    titleStyle: Styles.black50014,
                  ),
                  Dimens.boxHeight36,
                ],
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

  void _showStateBottomSheet(BuildContext context, ProfileController controller) {
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
                                    final isSelected = controller.selectedState != null &&
                                        controller.selectedState!.toLowerCase() == stateName.toLowerCase();
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
                                        controller.selectedCity = null;
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

  void _showCityBottomSheet(BuildContext context, ProfileController controller) {
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
                              "Select City (${controller.selectedState ?? ''})",
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
                                    final isSelected = controller.selectedCity != null &&
                                        controller.selectedCity!.toLowerCase() == cityName.toLowerCase();
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
}
