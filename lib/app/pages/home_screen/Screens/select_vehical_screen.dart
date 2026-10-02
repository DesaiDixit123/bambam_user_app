import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SelectVehicalScreen extends StatelessWidget {
  const SelectVehicalScreen({super.key});

  Widget _smallIconTextNetwork(dynamic logo, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FacilityIconWidget(
          logo: logo,
          text: text,
          type: 'feature',
          size: 16,
        ),
        Dimens.boxWidth6,
        Text(text, style: Styles.txtG5ColorsW40012),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      builder: (controller) {
        final trips = controller.exploreTrips ?? [];
        final rawVehicles = controller.exploreVehicles ?? [];
        final List<dynamic> vehicles = controller.tripMode == 2
            ? rawVehicles.where((v) {
                if (v is! Map) return false;
                final vtId = (v['vehicle_type'] is Map)
                    ? (v['vehicle_type']['_id']?.toString() ?? '')
                    : (v['vehicle_type']?.toString() ?? '');
                final vId = v['_id']?.toString() ?? '';
                final price = controller.getLocalRentalPrice(
                  vtId.isNotEmpty ? vtId : vId,
                );
                return price != null && price > 0;
              }).toList()
            : rawVehicles;
        final toList = controller.toControllers
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        final headerFrom = controller.formController.text.isNotEmpty
            ? controller.formController.text
            : ((trips.isNotEmpty && trips.first['from'] != null)
                  ? trips.first['from'].toString()
                  : '');
        final headerCity = '';
        final headerTo = controller.toController.text.isNotEmpty
            ? controller.toController.text
            : ((trips.isNotEmpty && trips.first['to'] != null)
                  ? (trips.first['to'] is List
                        ? (trips.first['to'] as List).join(', ')
                        : trips.first['to'].toString())
                  : '');
        final pickupDateRaw =
            (trips.isNotEmpty && trips.first['pickup_date'] != null)
            ? trips.first['pickup_date'].toString()
            : controller.fromDateController.text;
        final pickupTimeRaw =
            (trips.isNotEmpty && trips.first['pickup_time'] != null)
            ? trips.first['pickup_time'].toString()
            : '';
        final pickupTime = pickupTimeRaw.isNotEmpty
            ? pickupTimeRaw
            : (controller.tripMode == 1
                  ? controller.pickupTimeRtController.text
                  : controller.toDateController.text);
        final headerDate = pickupDateRaw.isNotEmpty
            ? '${pickupDateRaw.split('T').first} | $pickupTime'
            : '';

        final returnDateRaw =
            (trips.isNotEmpty && trips.first['return_date'] != null)
            ? trips.first['return_date'].toString()
            : controller.returnDateController.text;
        final returnTime =
            (trips.isNotEmpty && trips.first['return_time'] != null)
            ? trips.first['return_time'].toString()
            : controller.pickupTimeRtController.text;

        // ensure vehicleExpanded length matches vehicles
        if (controller.vehicleExpanded.length != vehicles.length) {
          controller.vehicleExpanded = List<bool>.filled(
            vehicles.length,
            false,
          );
        }

        return Scaffold(
          backgroundColor: ColorsValue.appBg,
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "",
          ),
          body: SafeArea(
            child: PullToRefreshWrapper(
              onRefresh: () => controller.refreshVehicleListScreen(),
              child: ListView(
                physics: kPullToRefreshScrollPhysics,
                padding: Dimens.edgeInsets20_00_20_00,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: Get.width,
                        decoration: BoxDecoration(
                          color: ColorsValue.l4CB,
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: Dimens.edgeInsets15,
                          child: controller.tripMode == 1
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Trip Type: Round Trip",
                                      style: Styles.txtG5ColorsW40014.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Dimens.boxHeight8,
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "From",
                                                style: Styles.txtG5ColorsW40014
                                                    .copyWith(fontSize: 11),
                                              ),
                                              Text(
                                                "$headerFrom$headerCity",
                                                style: Styles
                                                    .txtBlackColorW60016
                                                    .copyWith(fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Dimens.boxWidth8,
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "To",
                                                style: Styles.txtG5ColorsW40014
                                                    .copyWith(fontSize: 11),
                                              ),
                                              Text(
                                                toList.join(" → "),
                                                style: Styles
                                                    .txtBlackColorW60016
                                                    .copyWith(fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Dimens.boxHeight12,
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Pickup Date",
                                                style: Styles.txtG5ColorsW40014
                                                    .copyWith(fontSize: 11),
                                              ),
                                              Text(
                                                pickupDateRaw.isNotEmpty
                                                    ? pickupDateRaw
                                                          .split('T')
                                                          .first
                                                    : '',
                                                style: Styles
                                                    .txtBlackColorW60016
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Return Date",
                                                style: Styles.txtG5ColorsW40014
                                                    .copyWith(fontSize: 11),
                                              ),
                                              Text(
                                                returnDateRaw.isNotEmpty
                                                    ? returnDateRaw
                                                          .split('T')
                                                          .first
                                                    : '',
                                                style: Styles
                                                    .txtBlackColorW60016
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Pickup Time",
                                                style: Styles.txtG5ColorsW40014
                                                    .copyWith(fontSize: 11),
                                              ),
                                              Text(
                                                pickupTime,
                                                style: Styles
                                                    .txtBlackColorW60016
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Dimens.boxHeight15,
                                  ],
                                )
                              : controller.tripMode == 2
                              ? Column(
                                  children: [
                                    Text(
                                      "Trip Type: Local Rental",
                                      style: Styles.txtG5ColorsW40014.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Dimens.boxHeight4,
                                    Text(
                                      headerFrom.isNotEmpty
                                          ? headerFrom
                                          : controller.localCityController.text,
                                      style: Styles.txtBlackColorW60016,
                                      textAlign: TextAlign.center,
                                    ),
                                    Dimens.boxHeight4,
                                    Text(
                                      headerDate,
                                      style: Styles.txtG5ColorsW40014,
                                      textAlign: TextAlign.center,
                                    ),
                                    Dimens.boxHeight15,
                                  ],
                                )
                              : Column(
                                  children: [
                                    Text(
                                      '$headerFrom$headerCity → ${(controller.tripMode == 0 || controller.tripMode == 3) ? headerTo : toList.join("→")}',
                                      style: Styles.txtBlackColorW60016,
                                      textAlign: TextAlign.center,
                                    ),
                                    Dimens.boxHeight4,
                                    Text(
                                      headerDate,
                                      style: Styles.txtG5ColorsW40014,
                                      textAlign: TextAlign.center,
                                    ),
                                    Dimens.boxHeight15,
                                  ],
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: Dimens.twelveNG,
                        right: Dimens.hundredTen,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(Dimens.twelve),
                          onTap: () {
                            Get.back();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                Dimens.twelve,
                              ),
                              color: ColorsValue.appColor,
                            ),
                            padding: Dimens.edgeInsets16_6_16_6,
                            child: Text(
                              "modify_booking".tr,
                              style: Styles.whiteColorW50014,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (controller.tripMode == 2 &&
                      controller.rentalBlocks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: ColorsValue.borderColors.withOpacity(0.2),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(
                              controller.rentalBlocks.length,
                              (i) {
                                final block = controller.rentalBlocks[i];
                                if (block == null) return SizedBox();

                                final isSelected =
                                    controller.selectedRentalIndex == i;

                                return Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () {
                                      controller.selectRentalPackage(i);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "${block['hours']} hrs | ${block['km']} km",
                                        style: TextStyle(
                                          color: isSelected
                                              ? ColorsValue.appColor
                                              : Colors.grey,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    Dimens.boxHeight20,
                  ],
                  Dimens.boxHeight35,
                  Text(
                    "choess_you_vehical".tr,
                    style: Styles.txtBlackColorW70018,
                  ),
                  Dimens.boxHeight16,

                  if (vehicles.isEmpty) ...[
                    Container(
                      margin: EdgeInsets.only(bottom: Dimens.twenty),
                      decoration: BoxDecoration(
                        color: ColorsValue.bulycolorsCB,
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                      ),
                      child: Padding(
                        padding: Dimens.edgeInsets20,
                        child: Center(
                          child: Text(
                            'No vehicles available',
                            style: Styles.txtG7Colors40014,
                          ),
                        ),
                      ),
                    ),
                  ],

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vehicles.length,
                    itemBuilder: (context, idx) {
                      final vehicle = vehicles[idx] as Map<String, dynamic>;
                      final vehicleType = (vehicle['vehicle_type'] is Map)
                          ? vehicle['vehicle_type'] as Map<String, dynamic>
                          : <String, dynamic>{};
                      final brand =
                          vehicle['brand_name']?.toString() ??
                          vehicleType['name']?.toString() ??
                          'Vehicle';
                      final typeName = vehicleType['name']?.toString() ?? '';
                      final carPhoto =
                          vehicle['vehicle_type']['vehicle_photo']
                              ?.toString() ??
                          '';
                      String priceText = "";
                      String uptoKmText = "";
                      int gstAmount = 0;

                      // Vehicle TYPE id
                      final String vehicleTypeId =
                          vehicle['vehicle_type']?['_id']?.toString() ?? "";

                      // Extract exploreCab fields
                      final exploreCab = (vehicle['exploreCab'] is Map)
                          ? vehicle['exploreCab'] as Map<String, dynamic>
                          : <String, dynamic>{};
                      final double gstPercent =
                          (exploreCab['gst_percent'] as num?)?.toDouble() ??
                          0.0;
                      final int exploreGstAmount =
                          (exploreCab['gst_amount'] as num?)?.toInt() ?? 0;
                      final double fullPrice =
                          (exploreCab['final_price'] as num?)?.toDouble() ??
                          0.0;
                      final double baseFare =
                          (exploreCab['base_price_before_tax'] as num?)
                              ?.toDouble() ??
                          0.0;
                      final int finalPrice =
                          (baseFare > 0 ? baseFare : fullPrice).round();

                      // Find price calculation from trip (for outstations/airport)
                      Map<String, dynamic>? pc;
                      if (controller.exploreTrips != null &&
                          controller.exploreTrips!.isNotEmpty) {
                        final trip = controller.exploreTrips!.first;
                        final List priceList =
                            trip['priceCalculation'] as List? ?? [];
                        final matched = priceList.firstWhere(
                          (e) => e['vehicleId']?.toString() == vehicleTypeId,
                          orElse: () => null,
                        );
                        if (matched != null) {
                          pc = Map<String, dynamic>.from(matched as Map);
                        }
                      }

                      // ---------------- LOCAL RENTAL (tripMode == 2) ----------------
                      if (controller.tripMode == 2) {
                        final vId = vehicle['_id']?.toString() ?? '';
                        final localPrice = controller.getLocalRentalPrice(
                          vehicleTypeId.isNotEmpty ? vehicleTypeId : vId,
                        );

                        if (localPrice != null && localPrice > 0) {
                          priceText = "₹ ${localPrice.round()}";
                          if (gstPercent > 0) {
                            gstAmount = (localPrice * gstPercent / 100).round();
                          }
                        } else {
                          priceText = "";
                          gstAmount = 0;
                        }

                        // No upto km for local rental
                        uptoKmText = "";
                      }
                      // ---------------- ROUND TRIP (tripMode == 1) ------------------
                      else if (controller.tripMode == 1) {
                        priceText = "₹ $finalPrice";
                        gstAmount = exploreGstAmount;

                        if (pc != null) {
                          final int uptoKmLimit =
                              (pc['upto_km_limit'] as num?)?.toInt() ?? 0;
                          final double perKm =
                              (pc['perKm'] as num?)?.toDouble() ?? 0.0;
                          if (uptoKmLimit > 0) {
                            uptoKmText = "Up to $uptoKmLimit KM Included";
                          } else if (perKm > 0) {
                            uptoKmText =
                                "₹${perKm.toStringAsFixed(perKm % 1 == 0 ? 0 : 1)} /KM";
                          }
                        }
                      }
                      // ---------------- AIRPORT (tripMode == 3) ---------------------
                      else if (controller.tripMode == 3 &&
                          controller.airportSlabPrice != null) {
                        final slabPriceData = controller.airportSlabPrice!;
                        final List slabResults =
                            slabPriceData['slab_results'] as List? ?? [];
                        final matchedSlab = slabResults.firstWhere(
                          (r) => r['vehicleId']?.toString() == vehicleTypeId,
                          orElse: () => null,
                        );

                        if (matchedSlab != null) {
                          final double price =
                              (matchedSlab['slab_price'] is num)
                              ? (matchedSlab['slab_price'] as num).toDouble()
                              : 0.0;
                          priceText = "₹ ${price.round()}";
                          gstAmount = gstPercent > 0
                              ? (price * gstPercent / 100).round()
                              : 0;
                        } else {
                          priceText = "₹ $finalPrice";
                          gstAmount = exploreGstAmount;
                        }

                        final double distance =
                            (slabPriceData['distance_km'] is num)
                            ? (slabPriceData['distance_km'] as num).toDouble()
                            : 0.0;
                        if (distance > 0) {
                          uptoKmText =
                              "Exact fare for ${distance.toStringAsFixed(1)} km";
                        } else {
                          uptoKmText = "";
                        }
                      }
                      // ---------------- ONEWAY (tripMode == 0) ----------------------
                      else {
                        priceText = "₹ $finalPrice";
                        gstAmount = exploreGstAmount;

                        // For Oneway/Airport: show actual route distance (totalKm) not the package limit (upto_km)
                        // This matches the Fare Summary which shows "Total KMs: 287" and "Included KMs: 287"
                        final int actualTotalKm =
                            (exploreCab['totalKm'] as num?)?.toInt() ?? 0;
                        final int exploreUptoKm =
                            (exploreCab['upto_km'] as num?)?.toInt() ?? 0;
                        final int pcUptoKmLimit = pc != null
                            ? ((pc['upto_km_limit'] as num?)?.toInt() ?? 0)
                            : 0;

                        // Priority: actual route distance → upto_km from explore → upto_km_limit from priceCalc
                        final int displayKm = actualTotalKm > 0
                            ? actualTotalKm
                            : (exploreUptoKm > 0
                                  ? exploreUptoKm
                                  : pcUptoKmLimit);

                        if (displayKm > 0) {
                          uptoKmText = "Up to $displayKm KM";
                        } else if (pc != null) {
                          final double perKm =
                              (pc['perKm'] as num?)?.toDouble() ?? 0.0;
                          if (perKm > 0) {
                            uptoKmText =
                                "₹${perKm.toStringAsFixed(perKm % 1 == 0 ? 0 : 1)} /KM";
                          }
                        }
                      }

                      // Extract states list
                      final statesList =
                          vehicle['vehicle_type']['states'] as List? ?? [];
                      final state = statesList.isNotEmpty ? statesList[0] : {};
                      final vehicleFeatures =
                          state['vehicleFeatures'] as List? ?? [];

                      return Column(
                        children: [
                          Container(
                            margin: EdgeInsets.only(bottom: Dimens.twenty),
                            decoration: BoxDecoration(
                              color: ColorsValue.whiteColor,
                              borderRadius: BorderRadius.circular(
                                Dimens.twelve,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // LEFT SIDE: Image
                                      carPhoto.isNotEmpty
                                          ? Image.network(
                                              carPhoto,
                                              height: Dimens.eighty,
                                              width: 80.0,
                                              fit: BoxFit.contain,
                                              errorBuilder: (_, __, ___) =>
                                                  Image.asset(
                                                    AssetConstants.CarImge,
                                                    height: Dimens.eighty,
                                                    width: 80.0,
                                                  ),
                                            )
                                          : Image.asset(
                                              AssetConstants.CarImge,
                                              height: Dimens.eighty,
                                              width: 80.0,
                                            ),
                                      Dimens.boxWidth12,

                                      // MIDDLE: Brand, Type, Capacities
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              brand,
                                              style: Styles.txtBlackColorW70018
                                                  .copyWith(
                                                    color: const Color(
                                                      0xFF0B1727,
                                                    ),
                                                  ),
                                            ),
                                            Dimens.boxHeight2,
                                            Text(
                                              typeName.isNotEmpty
                                                  ? typeName
                                                  : 'SUV',
                                              style: Styles.txtG7Colors40014
                                                  .copyWith(
                                                    color: const Color(
                                                      0xFF748194,
                                                    ),
                                                  ),
                                            ),
                                            Dimens.boxHeight8,
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.work_outline,
                                                  size: 14,
                                                  color: const Color(
                                                    0xFF0B1727,
                                                  ),
                                                ),
                                                Dimens.boxWidth4,
                                                Expanded(
                                                  child: Text(
                                                    '${vehicleType['luggage_capacity'] ?? 2} luggage capacity',
                                                    style: Styles
                                                        .txtG7Colors40014
                                                        .copyWith(
                                                          fontSize: 11,
                                                          color: const Color(
                                                            0xFF748194,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Dimens.boxHeight4,
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.directions_car_outlined,
                                                  size: 14,
                                                  color: const Color(
                                                    0xFF0B1727,
                                                  ),
                                                ),
                                                Dimens.boxWidth4,
                                                Expanded(
                                                  child: Text(
                                                    '${vehicleType['seats'] ?? 4} SEAT',
                                                    style: Styles
                                                        .txtG7Colors40014
                                                        .copyWith(
                                                          fontSize: 11,
                                                          color: const Color(
                                                            0xFF748194,
                                                          ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // RIGHT SIDE: Price, GST, KM Limit
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              priceText,
                                              style: Styles.txtBlackColorW70018
                                                  .copyWith(
                                                    fontSize: 18,
                                                    color: const Color(
                                                      0xFF0B1727,
                                                    ),
                                                  ),
                                            ),
                                            if (gstAmount > 0)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                  bottom: 2,
                                                ),
                                                child: Text(
                                                  '+ ₹$gstAmount Charges and Taxes',
                                                  textAlign: TextAlign.right,
                                                  style: Styles.txtG7Colors40014
                                                      .copyWith(
                                                        fontSize: 10,
                                                        color: const Color(
                                                          0xFF748194,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            if (uptoKmText.isNotEmpty)
                                              Text(
                                                uptoKmText,
                                                textAlign: TextAlign.right,
                                                style: Styles.txtG7Colors40014
                                                    .copyWith(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          uptoKmText.startsWith(
                                                            'Exact fare',
                                                          )
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      color:
                                                          uptoKmText.startsWith(
                                                            'Exact fare',
                                                          )
                                                          ? ColorsValue.appColor
                                                          : const Color(
                                                              0xFF748194,
                                                            ),
                                                    ),
                                              ),
                                            if (controller.tripMode == 1)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 2,
                                                ),
                                                child: Text(
                                                  'Toll Tax, Parking & State Tax Extra',
                                                  textAlign: TextAlign.right,
                                                  style: Styles.txtG7Colors40014
                                                      .copyWith(
                                                        fontSize: 10,
                                                        color: const Color(
                                                          0xFFE45325,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            Dimens.boxHeight12,
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Dimens.boxHeight12,

                                  // BOTTOM ROW: More Details (Left) + Select Button (Right)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          controller.vehicleExpanded[idx] =
                                              !controller.vehicleExpanded[idx];
                                          controller.update();
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "More Details",
                                              style: Styles.appColorw50014,
                                            ),
                                            Dimens.boxWidth4,
                                            controller.vehicleExpanded[idx]
                                                ? Icon(
                                                    Icons
                                                        .keyboard_arrow_up_sharp,
                                                    color: ColorsValue.appColor,
                                                    size: 18,
                                                  )
                                                : Icon(
                                                    Icons
                                                        .keyboard_arrow_down_sharp,
                                                    color: ColorsValue.appColor,
                                                    size: 18,
                                                  ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(25),
                                        onTap: () {
                                          final vid =
                                              vehicle['_id']?.toString() ?? '';
                                          if (vid.isNotEmpty) {
                                            controller.selectVehicle(
                                              vehicleId: vid,
                                            );
                                          } else {
                                            Utility.showMessage(
                                              "vehicle id missing",
                                              MessageType.error,
                                              null,
                                              "OK",
                                            );
                                          }
                                        },
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Image.asset(
                                              AssetConstants.btn_bg,
                                              height: 40,
                                              fit: BoxFit.contain,
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 20.0,
                                              ), // perfectly offsets the tire graphic
                                              child: Text(
                                                "Select",
                                                style: Styles.whiteColorW70014,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Expanded Tabs Area
                                  if (controller.vehicleExpanded[idx]) ...[
                                    Dimens.boxHeight16,
                                    Container(
                                      width: Get.width,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          Dimens.twelve,
                                        ),
                                        color: const Color(
                                          0xFFF3F7FA,
                                        ), // Very light blue/grey bg similar to React
                                      ),
                                      padding: Dimens.edgeInsets12,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Tabs in exact 2x2 layout
                                          Builder(
                                            builder: (context) {
                                              Widget buildTab(int i) {
                                                if (i >=
                                                    controller
                                                        .vehicalDetiles
                                                        .length)
                                                  return const SizedBox();
                                                final item = controller
                                                    .vehicalDetiles[i];
                                                final isSelected =
                                                    controller
                                                        .selectedVehicalIndex ==
                                                    i;
                                                return InkWell(
                                                  onTap: () {
                                                    controller
                                                            .selectedVehicalIndex =
                                                        i;
                                                    controller.update();
                                                  },
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 2,
                                                          vertical: 8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      color: isSelected
                                                          ? ColorsValue
                                                                .whiteColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Text(
                                                      item,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: isSelected
                                                          ? Styles
                                                                .appColorw50014
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 13,
                                                                )
                                                          : Styles
                                                                .txtG7Colors40014
                                                                .copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 13,
                                                                ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              return Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: buildTab(0),
                                                      ),
                                                      Dimens.boxWidth8,
                                                      Expanded(
                                                        child: buildTab(1),
                                                      ),
                                                    ],
                                                  ),
                                                  Dimens.boxHeight8,
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: buildTab(2),
                                                      ),
                                                      Dimens.boxWidth8,
                                                      Expanded(
                                                        child: buildTab(3),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          Dimens.boxHeight16,

                                          Builder(
                                            builder: (_) {
                                              final sel = controller
                                                  .selectedVehicalIndex;

                                              // ---------------- INCLUSIONS ----------------
                                              if (sel == 0) {
                                                final incl =
                                                    state['includeFacilities']
                                                        as List? ??
                                                    [];
                                                if (incl.isEmpty) {
                                                  return Padding(
                                                    padding: Dimens.edgeInsets8,
                                                    child: Text(
                                                      "No inclusions found",
                                                      style: Styles
                                                          .txtG7Colors40014,
                                                    ),
                                                  );
                                                }
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: incl.map((f) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          FacilityIconWidget(
                                                            logo: f['logo'],
                                                            text: f['facility_description'] ?? "",
                                                            type: 'inclusion',
                                                            size: 20,
                                                          ),
                                                          Dimens.boxWidth12,
                                                          Expanded(
                                                            child: Text(
                                                              f['facility_description'] ??
                                                                  "",
                                                              style: Styles
                                                                  .txtBlackColorW50014
                                                                  .copyWith(
                                                                    color: const Color(
                                                                      0xFF0B1727,
                                                                    ),
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              }
                                              // ---------------- EXCLUSIONS ----------------
                                              else if (sel == 1) {
                                                final excl =
                                                    state['excludeFacilities']
                                                        as List? ??
                                                    [];
                                                if (excl.isEmpty) {
                                                  return Padding(
                                                    padding: Dimens.edgeInsets8,
                                                    child: Text(
                                                      "No exclusions found",
                                                      style: Styles
                                                          .txtG7Colors40014,
                                                    ),
                                                  );
                                                }
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: excl.map((f) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          FacilityIconWidget(
                                                            logo: f['logo'],
                                                            text: f['facility_description'] ?? "",
                                                            type: 'exclusion',
                                                            size: 20,
                                                          ),
                                                          Dimens.boxWidth12,
                                                          Expanded(
                                                            child: Text(
                                                              f['facility_description'] ??
                                                                  "",
                                                              style: Styles
                                                                  .txtBlackColorW50014
                                                                  .copyWith(
                                                                    color: const Color(
                                                                      0xFF0B1727,
                                                                    ),
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              }
                                              // ---------------- FACILITY ----------------
                                              else if (sel == 2) {
                                                final feats =
                                                    state['vehicleFeatures']
                                                        as List? ??
                                                    [];
                                                if (feats.isEmpty) {
                                                  return Padding(
                                                    padding: Dimens.edgeInsets8,
                                                    child: Text(
                                                      "No facilities found",
                                                      style: Styles
                                                          .txtG7Colors40014,
                                                    ),
                                                  );
                                                }
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: feats.map((f) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          FacilityIconWidget(
                                                            logo: f['logo'],
                                                            text: f['feature_description'] ?? "",
                                                            type: 'feature',
                                                            size: 20,
                                                          ),
                                                          Dimens.boxWidth12,
                                                          Expanded(
                                                            child: Text(
                                                              f['feature_description'] ??
                                                                  "",
                                                              style: Styles
                                                                  .txtBlackColorW50014
                                                                  .copyWith(
                                                                    color: const Color(
                                                                      0xFF0B1727,
                                                                    ),
                                                                    fontSize:
                                                                        13,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              }
                                              // ---------------- TERMS & CONDITION ----------------
                                              else {
                                                final String tcRaw =
                                                    state['terms_conditions'] ??
                                                    "No T&C found";
                                                // Split by html tags or just strip them roughly to make bullet points
                                                final plainText =
                                                    Utility.removeAllHtmlTags(
                                                      tcRaw,
                                                    );
                                                final tcList = plainText
                                                    .split(RegExp(r'\n+'))
                                                    .where(
                                                      (s) =>
                                                          s.trim().isNotEmpty,
                                                    )
                                                    .toList();

                                                if (tcList.isEmpty) {
                                                  return Padding(
                                                    padding: Dimens.edgeInsets8,
                                                    child: Text(
                                                      plainText,
                                                      style: Styles
                                                          .txtG7Colors40014,
                                                    ),
                                                  );
                                                }

                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: tcList.map((t) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 4,
                                                            horizontal: 8,
                                                          ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  top: 6,
                                                                ),
                                                            child: Icon(
                                                              Icons.circle,
                                                              size: 6,
                                                              color: ColorsValue
                                                                  .appColor,
                                                            ),
                                                          ),
                                                          Dimens.boxWidth10,
                                                          Expanded(
                                                            child: Text(
                                                              t.trim(),
                                                              style: Styles
                                                                  .txtBlackColorW50014
                                                                  .copyWith(
                                                                    color: const Color(
                                                                      0xFF0B1727,
                                                                    ),
                                                                    fontSize:
                                                                        13,
                                                                    height: 1.4,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                );
                                              }
                                            },
                                          ),
                                          Dimens.boxHeight8,
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
