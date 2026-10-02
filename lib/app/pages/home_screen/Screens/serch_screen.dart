import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/citys_list.dart';
import 'package:bam_bam_user/app/utils/airports_list.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';
import 'package:bam_bam_user/app/utils/strings/string_constants.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class SerchScreen extends StatelessWidget {
  const SerchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "",
          ),
          body: PullToRefreshWrapper(
            onRefresh: () => controller.refreshBookingFormScreen(),
            child: ListView(
              physics: kPullToRefreshScrollPhysics,
              padding: Dimens.edgeInsets15,
              children: [
                // --- Tab Toggle: One Way / Round Trip / Local Rental / Airport ---
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTripModeTab(
                            controller,
                            0,
                            "one_way".tr,
                            Icons.arrow_right_alt,
                          ),
                        ),
                        Dimens.boxWidth12,
                        Expanded(
                          child: _buildTripModeTab(
                            controller,
                            1,
                            "round_Trip".tr,
                            Icons.swap_horiz,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight12,
                    Row(
                      children: [
                        Expanded(
                          child: _buildTripModeTab(
                            controller,
                            2,
                            "Local Rental",
                            Icons.directions_car,
                          ),
                        ),
                        Dimens.boxWidth12,
                        Expanded(
                          child: _buildTripModeTab(
                            controller,
                            3,
                            "Airport",
                            Icons.local_airport,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // --- Airport Mode Toggle (Pickup / Drop) ---
                if (controller.tripMode == 3) ...[
                  Dimens.boxHeight20,
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.setPickupType('pickup'),
                          borderRadius: BorderRadius.circular(Dimens.sixteen),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            padding: Dimens.edgeInsets12_14_12_14,
                            decoration: BoxDecoration(
                              color: controller.pickupType == 'pickup'
                                  ? ColorsValue.appColor
                                  : ColorsValue.whiteColor,
                              borderRadius: BorderRadius.circular(
                                Dimens.sixteen,
                              ),
                              border: controller.pickupType == 'pickup'
                                  ? Border.all(
                                      color: ColorsValue.appColor,
                                      width: 1,
                                    )
                                  : Border.all(
                                      color: ColorsValue.borderColors,
                                      width: 1,
                                    ),
                              boxShadow: controller.pickupType == 'pickup'
                                  ? [
                                      BoxShadow(
                                        color: ColorsValue.appColor.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (controller.pickupType == 'pickup') ...[
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: ColorsValue.whiteColor,
                                  ),
                                  Dimens.boxWidth8,
                                ],
                                Text(
                                  "Pickup",
                                  style: controller.pickupType == 'pickup'
                                      ? Styles.whiteColorW70014
                                      : Styles.txtG5ColorsW40014.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Dimens.boxWidth12,
                      Expanded(
                        child: InkWell(
                          onTap: () => controller.setPickupType('drop'),
                          borderRadius: BorderRadius.circular(Dimens.sixteen),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            padding: Dimens.edgeInsets12_14_12_14,
                            decoration: BoxDecoration(
                              color: controller.pickupType == 'drop'
                                  ? ColorsValue.appColor
                                  : ColorsValue.whiteColor,
                              borderRadius: BorderRadius.circular(
                                Dimens.sixteen,
                              ),
                              border: controller.pickupType == 'drop'
                                  ? Border.all(
                                      color: ColorsValue.appColor,
                                      width: 1,
                                    )
                                  : Border.all(
                                      color: ColorsValue.borderColors,
                                      width: 1,
                                    ),
                              boxShadow: controller.pickupType == 'drop'
                                  ? [
                                      BoxShadow(
                                        color: ColorsValue.appColor.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (controller.pickupType == 'drop') ...[
                                  Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: ColorsValue.whiteColor,
                                  ),
                                  Dimens.boxWidth8,
                                ],
                                Text(
                                  "Drop",
                                  style: controller.pickupType == 'drop'
                                      ? Styles.whiteColorW70014
                                      : Styles.txtG5ColorsW40014.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                Dimens.boxHeight30,

                if (controller.tripMode != 2) ...[
                  // --- ONE WAY, ROUND TRIP or AIRPORT "From" field ---
                  Text(
                    (controller.tripMode == 3)
                        ? (controller.pickupType == 'pickup'
                              ? "From Airport"
                              : "From Location")
                        : "From".tr,
                    style: Styles.txtBlackColorW50014,
                  ),
                  Dimens.boxHeight8,

                  CityAutocompleteField(
                    controller: controller.formController,
                    showPoweredByGoogle: !(controller.tripMode == 3 && controller.pickupType == 'pickup'),
                    optionsBuilder: (textEditingValue) async {
                      if (textEditingValue.text.trim().isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      if (controller.tripMode == 3 && controller.pickupType == 'pickup') {
                        return AirportsList.allAirports.where(
                          (airport) => airport.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      }
                      return await GooglePlacesHelper.searchAddress(
                        textEditingValue.text,
                        StringConstants.gpooglePlaceKey,
                      );
                    },
                    onChanged: (_) => controller.update(),
                    decoration: InputDecoration(
                      hintText: (controller.tripMode == 3 && controller.pickupType == 'pickup')
                          ? "Select From Airport"
                          : (controller.tripMode == 3 && controller.pickupType == 'drop')
                              ? "Enter Pickup Address"
                              : "Enter Location".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      filled: true,
                      fillColor: ColorsValue.whiteColor,
                      contentPadding: Dimens.edgeInsets16,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        borderSide: BorderSide(
                          color: ColorsValue.borderColors,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        borderSide: BorderSide(
                          color: ColorsValue.borderColors,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        borderSide: BorderSide(
                          color: ColorsValue.appColor,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: (controller.tripMode == 3 && controller.pickupType == 'pickup')
                          ? null
                          : GestureDetector(
                              onTap: () {
                                controller.useCurrentLocationAndFillCity();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorsValue.appColor.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.my_location,
                                        size: 16,
                                        color: ColorsValue.appColor,
                                      ),
                                      Dimens.boxWidth6,
                                      Text(
                                        "current_location".tr,
                                        style: Styles.appColorw50014,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    style: Styles.txtBlackColorW40014,
                  ),
                ],

                // Swap button for One Way, Round Trip, and Airport
                if (controller.tripMode != 2) ...[
                  Dimens.boxHeight12,
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        controller.swapFromTo();
                      },
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: ColorsValue.whiteColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: ColorsValue.borderColors.withOpacity(0.5),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.swap_vert,
                            color: ColorsValue.appColor,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Dimens.boxHeight12,
                ],


                //Dimens.boxHeight20,

                // --- CONDITIONAL: Round Trip -> multiple "To" cities UI; OneWay -> single To; Local -> City only ---
                if (controller.tripMode == 2) ...[
                  // Local Rental: single City/Location input
                  Text("City".tr, style: Styles.txtBlackColorW50014),
                  Dimens.boxHeight8,
                  CityAutocompleteField(
                    controller: controller.localCityController,
                    showPoweredByGoogle: true,
                    optionsBuilder: (textEditingValue) async {
                      if (textEditingValue.text.trim().isEmpty) {
                        return const Iterable<String>.empty();
                      }
                      return await GooglePlacesHelper.searchAddress(
                        textEditingValue.text,
                        StringConstants.gpooglePlaceKey,
                      );
                    },
                    onChanged: (_) => controller.update(),
                    decoration: InputDecoration(
                      hintText: "Enter City".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      filled: true,
                      fillColor: ColorsValue.whiteColor,
                      contentPadding: Dimens.edgeInsets16,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        borderSide: BorderSide(
                          color: ColorsValue.borderColors,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        borderSide: BorderSide(
                          color: ColorsValue.borderColors,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                        borderSide: BorderSide(
                          color: ColorsValue.appColor,
                          width: 1.5,
                        ),
                      ),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          controller.useCurrentLocationAndFillCity();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: ColorsValue.appColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: ColorsValue.appColor,
                                ),
                                Dimens.boxWidth6,
                                Text(
                                  "current_location".tr,
                                  style: Styles.appColorw50014,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    style: Styles.txtBlackColorW40014,
                  ),
                ] else ...[
                  // One Way or Round Trip: show "To" area (single or multiple)
                  Dimens.boxHeight8,
                  if (controller.tripMode == 1) ...[
                    // Round Trip: multiple destination fields + add/remove
                    Column(
                      children: [
                        ...List.generate(controller.toControllers.length, (
                          index,
                        ) {
                          final tc = controller.toControllers[index];

                          return Padding(
                            padding: EdgeInsets.only(bottom: Dimens.ten),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  " To ${controller.toControllers.length > 1 ? (index + 1) : ""}".tr,
                                  style: Styles.txtBlackColorW50014,
                                ),
                                Dimens.boxHeight5,
                                Container(
                                  decoration: BoxDecoration(
                                    color: ColorsValue.whiteColor,
                                    borderRadius: BorderRadius.circular(
                                      Dimens.twelve,
                                    ),
                                    border: Border.all(
                                      color: ColorsValue.borderColors,
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: CityAutocompleteField(
                                          controller: tc,
                                          isDense: true,
                                          showPoweredByGoogle: true,
                                          optionsBuilder: (textEditingValue) async {
                                            if (textEditingValue.text.trim().isEmpty) {
                                              return const Iterable<String>.empty();
                                            }
                                            return await GooglePlacesHelper.searchAddress(
                                              textEditingValue.text,
                                              StringConstants.gpooglePlaceKey,
                                            );
                                          },
                                          onChanged: (_) => controller.update(),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: "Enter Location".tr,
                                            hintStyle: Styles.txtG7Colors40014,
                                            border: InputBorder.none,
                                          ),
                                          style: Styles.txtBlackColorW40014,
                                        ),
                                      ),

                                      // spacing between text and buttons
                                      Dimens.boxWidth8,

                                      // Right-side buttons group (minus and plus)
                                      Row(
                                        children: [
                                          // remove button (only show when more than 1 destination)
                                          if (controller.toControllers.length > 1)
                                            GestureDetector(
                                              onTap: () =>
                                                  controller.removeToAt(index),
                                              child: Container(
                                                height: Dimens.thirtySix,
                                                width: Dimens.thirtySix,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: ColorsValue.whiteColor,
                                                  border: Border.all(
                                                    color: ColorsValue.borderColors,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.03),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: Dimens.fifteen,
                                                    color: ColorsValue.txtRedColor,
                                                  ),
                                                ),
                                              ),
                                            ),

                                          if (controller.toControllers.length > 1)
                                            Dimens.boxWidth8,

                                          // add button (only on last row and if < 5)
                                          if (index ==
                                                  controller.toControllers.length - 1 &&
                                              controller.toControllers.length < 5)
                                            GestureDetector(
                                              onTap: () =>
                                                  controller.addNewTo(),
                                              child: Container(
                                                height: Dimens.thirtySix,
                                                width: Dimens.thirtySix,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: ColorsValue.whiteColor,
                                                  border: Border.all(
                                                    color: ColorsValue.borderColors,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.03),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.add,
                                                    size: Dimens.fifteen,
                                                    color: ColorsValue.appColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ] else ...[
                    // One Way or Airport - single to input
                    Text(
                      (controller.tripMode == 3)
                          ? (controller.pickupType == 'drop'
                                ? "To Airport"
                                : "To Location")
                          : "To".tr,
                      style: Styles.txtBlackColorW50014,
                    ),
                    Dimens.boxHeight8,
                    CityAutocompleteField(
                      controller: controller.toController,
                      showPoweredByGoogle: !(controller.tripMode == 3 && controller.pickupType == 'drop'),
                      optionsBuilder: (textEditingValue) async {
                        if (textEditingValue.text.trim().isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        if (controller.tripMode == 3 &&
                            controller.pickupType == 'drop') {
                          return AirportsList.allAirports.where(
                            (airport) => airport.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        }
                        return await GooglePlacesHelper.searchAddress(
                          textEditingValue.text,
                          StringConstants.gpooglePlaceKey,
                        );
                      },
                      onChanged: (_) => controller.update(),
                      decoration: InputDecoration(
                        hintText: (controller.tripMode == 3 &&
                                controller.pickupType == 'drop')
                            ? "Select To Airport"
                            : (controller.tripMode == 3 &&
                                    controller.pickupType == 'pickup')
                                ? "Enter Drop Address"
                                : "Enter Location".tr,
                        hintStyle: Styles.txtG7Colors40014,
                        filled: true,
                        fillColor: ColorsValue.whiteColor,
                        contentPadding: Dimens.edgeInsets16,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          borderSide: BorderSide(
                            color: ColorsValue.borderColors,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          borderSide: BorderSide(
                            color: ColorsValue.borderColors,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          borderSide: BorderSide(
                            color: ColorsValue.appColor,
                            width: 1.5,
                          ),
                        ),
                        suffixIcon: Icon(
                          Icons.location_on_outlined,
                          color: ColorsValue.borderColors,
                        ),
                      ),
                      style: Styles.txtBlackColorW40014,
                    ),
                  ],
                ],


                Dimens.boxHeight25,

                // --- Date / Time inputs ---
                if (controller.tripMode == 2) ...[
                  // LOCAL RENTAL
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          textEditingController: controller.fromDateController,
                          style: Styles.txtBlackColorW40014,
                          isBorder: true,
                          filled: true,
                          fillColor: ColorsValue.whiteColor,
                          hintText: "select".tr,
                          hintStyle: Styles.txtG7Colors40014,
                          isTitle: true,
                          readOnly: true,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                controller.openPickupDatePicker(context),
                            icon: Icon(
                              Icons.calendar_month_outlined,
                              color: ColorsValue.appColor,
                            ),
                          ),
                          title: 'p_d'.tr,
                          titleStyle: Styles.black50014,
                        ),
                      ),
                      Dimens.boxWidth15,
                      Expanded(
                        child: CustomTextFormField(
                          textEditingController: controller.toDateController,
                          isBorder: true,
                          filled: true,
                          fillColor: ColorsValue.whiteColor,
                          style: Styles.txtBlackColorW40014,
                          hintText: "select".tr,
                          hintStyle: Styles.txtG7Colors40014,
                          isTitle: true,
                          readOnly: true,
                          suffixIcon: IconButton(
                            icon: Icon(
                              Icons.access_time,
                              color: ColorsValue.appColor,
                            ),
                            onPressed: () =>
                                controller.openPickupTimePicker(context),
                          ),
                          title: 'p_c'.tr,
                          titleStyle: Styles.black50014,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          textEditingController: controller.fromDateController,
                          style: Styles.txtBlackColorW40014,
                          isBorder: true,
                          filled: true,
                          fillColor: ColorsValue.whiteColor,
                          hintText: "select".tr,
                          hintStyle: Styles.txtG7Colors40014,
                          isTitle: true,
                          readOnly: true,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                controller.openPickupDatePicker(context),
                            icon: Icon(
                              Icons.calendar_month_outlined,
                              color: ColorsValue.appColor,
                            ),
                          ),
                          title: 'p_d'.tr,
                          titleStyle: Styles.black50014,
                        ),
                      ),
                      Dimens.boxWidth15,
                      if (controller.tripMode == 1)
                        Expanded(
                          child: CustomTextFormField(
                            textEditingController:
                                controller.returnDateController,
                            style: Styles.txtBlackColorW40014,
                            isBorder: true,
                            filled: true,
                            fillColor: ColorsValue.whiteColor,
                            hintText: "select".tr,
                            hintStyle: Styles.txtG7Colors40014,
                            isTitle: true,
                            readOnly: true,
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  controller.openReturnDatePicker(context),
                              icon: Icon(
                                Icons.calendar_month_outlined,
                                color: ColorsValue.appColor,
                              ),
                            ),
                            title: 'Return Date',
                            titleStyle: Styles.black50014,
                          ),
                        )
                      else
                        Expanded(
                          child: CustomTextFormField(
                            textEditingController: controller.toDateController,
                            isBorder: true,
                            filled: true,
                            fillColor: ColorsValue.whiteColor,
                            style: Styles.txtBlackColorW40014,
                            hintText: "select".tr,
                            hintStyle: Styles.txtG7Colors40014,
                            isTitle: true,
                            readOnly: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.access_time,
                                color: ColorsValue.appColor,
                              ),
                              onPressed: () =>
                                  controller.openPickupTimePicker(context),
                            ),
                            title: 'p_c'.tr,
                            titleStyle: Styles.black50014,
                          ),
                        ),
                    ],
                  ),
                  if (controller.tripMode == 1) ...[
                    Dimens.boxHeight15,
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextFormField(
                            textEditingController:
                                controller.pickupTimeRtController,
                            isBorder: true,
                            filled: true,
                            fillColor: ColorsValue.whiteColor,
                            style: Styles.txtBlackColorW40014,
                            hintText: "select".tr,
                            hintStyle: Styles.txtG7Colors40014,
                            isTitle: true,
                            readOnly: true,
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.access_time,
                                color: ColorsValue.appColor,
                              ),
                              onPressed: () =>
                                  controller.openPickupTimePicker(context),
                            ),
                            title: 'p_c'.tr,
                            titleStyle: Styles.black50014,
                          ),
                        ),
                        Dimens.boxWidth15,
                        Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ],

                Dimens.boxHeight50,

                // Explore button - calls controller.exploreCabs()
                CustomButton(
                  onPressed: () async {
                    await controller.exploreCabs();
                  },
                  leading: const Icon(
                    Icons.search,
                    color: Colors.white,
                    size: 20,
                  ),
                  text: "exlpore_cabs".tr,
                  textStyle: Styles.whiteColorW70014,
                  isBorder: false,
                  isColor: true,
                  radius: 50, // Premium rounded pill shape
                  backgroundColor: ColorsValue.appColor,
                  boxShadows: [
                    BoxShadow(
                      color: ColorsValue.appColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripModeTab(
    HomeController controller,
    int mode,
    String label,
    IconData iconData,
  ) {
    bool isActive = controller.tripMode == mode;
    return GestureDetector(
      onTap: () {
        controller.setTripMode(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        padding: Dimens.edgeInsets12_14_12_14,
        decoration: BoxDecoration(
          color: isActive ? ColorsValue.appColor : ColorsValue.whiteColor,
          borderRadius: BorderRadius.circular(Dimens.sixteen),
          border: isActive
              ? Border.all(color: ColorsValue.appColor, width: 1)
              : Border.all(color: ColorsValue.borderColors, width: 1),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ColorsValue.appColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 18,
              color: isActive
                  ? ColorsValue.whiteColor
                  : ColorsValue.txtG5Colors,
            ),
            Dimens.boxWidth8,
            Flexible(
              child: Text(
                label,
                style: isActive
                    ? Styles.whiteColorW70014
                    : Styles.txtG5ColorsW40014.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
