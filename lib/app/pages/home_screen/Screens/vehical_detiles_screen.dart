import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class VehicalDetilesScreen extends StatefulWidget {
  const VehicalDetilesScreen({super.key});

  @override
  State<VehicalDetilesScreen> createState() => _VehicalDetilesScreenState();
}

class _VehicalDetilesScreenState extends State<VehicalDetilesScreen> {
  bool _showFareBreakup = true;
  bool _showPaymentFareBreakup = true;
  int _selectedFacilityTab = 0; // 0: Inclusion, 1: Exclusion, 2: Facility, 3: Terms & Condition

  String _cleanCityName(String raw) {
    if (raw.isEmpty) return '';
    final parts = raw.split(',');
    return parts.first.trim();
  }

  String _formatDisplayDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      String d = rawDate;
      if (d.contains('T')) d = d.split('T').first;
      if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(d)) return d;
      final parsed = DateTime.parse(d);
      return DateFormat('dd-MM-yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  String _cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    return htmlString
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<li>', caseSensitive: false), '• ')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  Widget _buildFacilitiesCard({
    required List<dynamic> includeFacilities,
    required List<dynamic> excludeFacilities,
    required List<dynamic> vehicleFeatures,
    required String termsConditions,
  }) {
    final tabTitles = [
      "Inclusion",
      "Exclusion",
      "Facility",
      "Terms & Condition"
    ];

    Widget buildTabButton(int index) {
      final isSelected = _selectedFacilityTab == index;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedFacilityTab = index;
          });
        },
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            tabTitles[index],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? ColorsValue.appColor
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorsValue.l4CB,
        borderRadius: BorderRadius.circular(Dimens.twelve),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2x2 Tab bar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5EDF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: buildTabButton(0)),
                    const SizedBox(width: 6),
                    Expanded(child: buildTabButton(1)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: buildTabButton(2)),
                    const SizedBox(width: 6),
                    Expanded(child: buildTabButton(3)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Builder(
            builder: (_) {
              if (_selectedFacilityTab == 0) {
                // Inclusion
                if (includeFacilities.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No inclusions specified",
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: includeFacilities.map((item) {
                    final text = item is Map
                        ? (item['facility_description'] ?? '')
                        : item.toString();
                    final logo = item is Map ? item['logo'] : null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FacilityIconWidget(
                          logo: logo,
                          text: text,
                          type: 'inclusion',
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              } else if (_selectedFacilityTab == 1) {
                // Exclusion
                if (excludeFacilities.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No exclusions specified",
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: excludeFacilities.map((item) {
                    final text = item is Map
                        ? (item['facility_description'] ?? '')
                        : item.toString();
                    final logo = item is Map ? item['logo'] : null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FacilityIconWidget(
                          logo: logo,
                          text: text,
                          type: 'exclusion',
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              } else if (_selectedFacilityTab == 2) {
                // Facility
                if (vehicleFeatures.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No facilities specified",
                      style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    ),
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: vehicleFeatures.map((item) {
                    final text = item is Map
                        ? (item['feature_description'] ?? '')
                        : item.toString();
                    final logo = item is Map ? item['logo'] : null;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FacilityIconWidget(
                          logo: logo,
                          text: text,
                          type: 'feature',
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              } else {
                // Terms & Condition
                final cleanTerms = _cleanHtml(termsConditions);
                if (cleanTerms.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "Standard terms and conditions apply.",
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  );
                }
                return Text(
                  cleanTerms,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF374151),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _iconText(String asset, String text) {
    return Row(
      children: [
        SvgPicture.asset(asset, height: Dimens.sixteen),
        Dimens.boxWidth8,
        Text(text, style: Styles.txtG5ColorsW40012),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.find<ProfileController>();
    return GetBuilder<HomeController>(
      initState: (state) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final c = Get.find<HomeController>();
          c.markUnprocessed();
          c.updateTotalFare(); // 🔸 VERY IMPORTANT: Fix 0 values on load
          c.update();
          try {
            await Future.wait([
              c.fetchSpecialServicesWithoutLoader(),
              c.fetchCouponOfferWithoutLoader(
                c.selectedVehicle?['_id'] ?? '',
                c.selectedExploreCab?['from'] ?? '',
                (c.selectedExploreCab?['to'] is List)
                    ? (c.selectedExploreCab?['to'][0] ?? '')
                    : (c.selectedExploreCab?['to'] ?? ''),
              ),
              if (c.tripMode == 3) c.calculateAirportSlabPrice(),
              // Only auto-recalculate if user already has specific coordinates
              // (i.e. user previously selected a specific address, not just city names)
              if (c.tripMode != 3 &&
                  ((c.modifiedPickupLat != null && c.modifiedDropLat != null) ||
                   (c.pickupController.text.trim().isNotEmpty &&
                    c.dropController.text.trim().isNotEmpty &&
                    (c.pickupController.text.trim() != c.formController.text.trim() ||
                     c.dropController.text.trim() != c.toController.text.trim()))))
                c.recalculateRouteDistance(),
            ]);
            c.updateTotalFare(); // Recalculate if special services changed
            c.update();
          } catch (e) {
            debugPrint('vehical details init error: $e');
          }
        });
      },

      builder: (controller) {
        final explore = controller.selectedExploreCab;
        final vehicle = controller.selectedVehicleWrapper;

        // header info (from / to / trip type / date/time)
        final tripType = explore?['trip_type']?.toString() ?? 'Oneway';
        
        final displayFrom = controller.formController.text.trim().isNotEmpty
            ? controller.formController.text.trim()
            : (explore?['from']?.toString() ?? '');
            
        final displayTo = controller.toController.text.trim().isNotEmpty
            ? controller.toController.text.trim()
            : (explore?['to'] is List
                ? (explore?['to'] as List).whereType<String>().join(', ')
                : (explore?['to']?.toString() ?? ''));

        final toRaw = explore?['to'];
        String to = '';
        final safeList = toRaw is List ? toRaw.whereType<String>().toList() : <String>[];
        if (toRaw is List) {
          to = safeList.isNotEmpty
              ? safeList.join(', ')
              : controller.toController.text;
        } else if (toRaw is String) {
          to = toRaw;
        } else {
          to = explore?['city']?.toString() ?? controller.toController.text;
        }

        String pickupDateRaw = '';
        String pickupTimeRaw = '';
        String returnDateRaw = '';
        if (explore != null) {
          pickupDateRaw = explore['pickup_date']?.toString() ?? '';
          pickupTimeRaw = explore['pickup_time']?.toString() ?? '';
          returnDateRaw = explore['return_date']?.toString() ?? '';
        }
        if (pickupDateRaw.isEmpty)
          pickupDateRaw = controller.fromDateController.text;
        if (pickupTimeRaw.isEmpty)
          pickupTimeRaw = controller.tripMode == 1
              ? controller.pickupTimeRtController.text
              : controller.toDateController.text;
        if (returnDateRaw.isEmpty)
          returnDateRaw = controller.returnDateController.text;

        String dateText = '';
        if (pickupDateRaw.isNotEmpty) {
          String pd = pickupDateRaw;
          try {
            if (pd.contains('T')) pd = pd.split('T').first;
            // pd = DateFormat('dd-MM-yyyy').format(DateTime.parse(pd));
          } catch (_) {}
          dateText = '$pd | $pickupTimeRaw';
        }

        // Resolve vehicle_type Map safely across all trip modes
        Map<String, dynamic> vehicleTypeMap = {};
        final rawVt = vehicle?['vehicle_type'] ??
            controller.selectedVehicle?['vehicle_type'];
        if (rawVt is Map) {
          vehicleTypeMap = Map<String, dynamic>.from(rawVt);
        }

        // If states list is empty or vehicleTypeMap is empty, search exploreVehicles
        if ((vehicleTypeMap['states'] as List? ?? []).isEmpty) {
          final targetId = vehicle?['_id']?.toString() ??
              controller.selectedVehicle?['_id']?.toString() ??
              '';
          final matchedVehicle = controller.exploreVehicles.firstWhere(
            (v) =>
                v is Map &&
                (v['_id']?.toString() == targetId ||
                    (v['vehicle_type'] is Map &&
                        v['vehicle_type']['_id']?.toString() == targetId)),
            orElse: () => null,
          );
          if (matchedVehicle != null && matchedVehicle['vehicle_type'] is Map) {
            vehicleTypeMap =
                Map<String, dynamic>.from(matchedVehicle['vehicle_type'] as Map);
          }
        }

        // vehicle display fields
        String vehicleTypeName = vehicleTypeMap['name']?.toString() ?? '';
        final brand = vehicle?['brand_name']?.toString() ??
            controller.selectedVehicle?['brand_name']?.toString() ??
            '';
        final displayName = brand.isNotEmpty
            ? brand
            : (vehicleTypeName.isNotEmpty ? vehicleTypeName : 'Vehicle');
        final carPhotoPath = vehicleTypeMap['vehicle_photo']?.toString() ?? '';
        print("car photo path: $carPhotoPath");
        final carPhotoUrl = carPhotoPath.isNotEmpty ? carPhotoPath : '';

        // Extract states list
        final statesList = vehicleTypeMap['states'] as List? ?? [];
        final state = statesList.isNotEmpty && statesList[0] is Map
            ? (statesList[0] as Map)
            : {};
        final includeFacilities = state['includeFacilities'] as List? ?? [];
        final excludeFacilities = state['excludeFacilities'] as List? ?? [];
        final vehicleFeatures = state['vehicleFeatures'] as List? ?? [];
        final termsConditions = state['terms_conditions']?.toString() ?? '';

        // price: try selectedExploreCab.final_price or explore.final_price
        String priceTxt = '₹0';
        if (controller.tripMode == 3 && controller.airportSlabPrice != null) {
          final slabPriceData = controller.airportSlabPrice!;
          final List slabResults = slabPriceData['slab_results'] as List? ?? [];
          final matchedSlab = slabResults.firstWhere(
            (r) =>
                r['vehicleId']?.toString() ==
                    (vehicleTypeMap['_id']?.toString() ?? rawVt?.toString()) ||
                r['vehicleId']?.toString() == vehicle?['_id']?.toString(),
            orElse: () => null,
          );
          if (matchedSlab != null) {
            final double price = (matchedSlab['slab_price'] is num)
                ? (matchedSlab['slab_price'] as num).toDouble()
                : 0.0;
            priceTxt = '₹${price.round()}';
          } else if (explore != null) {
            final p =
                explore['final_price'] ??
                explore['fix_price_per_day'] ??
                explore['per_km_price'];
            if (p != null) priceTxt = '₹$p';
          }
        } else if (explore != null) {
          final p =
              explore['final_price'] ??
              explore['fix_price_per_day'] ??
              explore['per_km_price'];
          if (p != null) priceTxt = '₹$p';
        }

        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () {
              Get.back();
            },
            title: "",
          ),
          backgroundColor: ColorsValue.appBg,
          body: PullToRefreshWrapper(
            onRefresh: () => controller.refreshVehicleDetailsScreen(),
            child: ListView(
              physics: kPullToRefreshScrollPhysics,
              controller: controller.scrollController,
              padding: Dimens.edgeInsets20_10_20_10,
              children: [
                // header
                Container(
                  decoration: BoxDecoration(
                    color: ColorsValue.l4CB,
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: Dimens.edgeInsets20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.tripMode == 1) ...[
                          Text(
                            "Trip Type: Round Trip",
                            style: Styles.txtG5ColorsW40014.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Dimens.boxHeight8,
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "From",
                                      style: Styles.txtG5ColorsW40014.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      _cleanCityName(displayFrom),
                                      style: Styles.txtBlackColorW60016
                                          .copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Dimens.boxWidth8,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "To",
                                      style: Styles.txtG5ColorsW40014.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      _cleanCityName(displayTo),
                                      style: Styles.txtBlackColorW60016
                                          .copyWith(fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Dimens.boxHeight12,
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: ColorsValue.appColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Pickup Date: ${_formatDisplayDate(pickupDateRaw)}",
                                style: Styles.txtG5ColorsW40014.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Dimens.boxHeight8,
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: ColorsValue.appColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Return Date: ${_formatDisplayDate(returnDateRaw)}",
                                style: Styles.txtG5ColorsW40014.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Dimens.boxHeight8,
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                color: ColorsValue.appColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Pickup Time: $pickupTimeRaw",
                                style: Styles.txtG5ColorsW40014.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(tripType, style: Styles.txtG7Colors40014),
                          Dimens.boxHeight3,
                          if (controller.tripMode != 2) ...[
                            Text(
                              '${_cleanCityName(displayFrom)}  →  ${_cleanCityName(displayTo)}',
                              style: Styles.txtBlackColorW60016.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _cleanCityName(controller.localCityController.text),
                              style: Styles.txtBlackColorW60016.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],

                          Dimens.boxHeight10,
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: ColorsValue.appColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Pickup: ${_formatDisplayDate(pickupDateRaw)}",
                                style: Styles.txtG5ColorsW40014.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Dimens.boxHeight8,
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                color: ColorsValue.appColor,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Pickup Time: $pickupTimeRaw",
                                style: Styles.txtG5ColorsW40014.copyWith(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Dimens.boxHeight16,

                // vehicle summary
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    color: ColorsValue.l4CB,
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                  ),
                  child: Padding(
                    padding: Dimens.edgeInsets20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    () {
                                      final isOneway = controller.tripMode == 0;
                                      final isAirport = controller.tripMode == 3;
                                      String uptoKmText = '';
                                      if (isOneway || isAirport) {
                                        final actualKm = (controller.selectedExploreCab?['totalKm'] is num)
                                            ? (controller.selectedExploreCab!['totalKm'] as num).toDouble()
                                            : controller.totalKm;
                                        if (actualKm > 0) uptoKmText = "Up to ${actualKm.toStringAsFixed(0)} KM";
                                      }
                                      if (uptoKmText.isEmpty) {
                                        final uptoKm = controller.rawUptoKmComputed > 0
                                            ? controller.rawUptoKmComputed
                                            : (controller.selectedExploreCab?['upto_km'] is num
                                                ? (controller.selectedExploreCab!['upto_km'] as num).toDouble()
                                                : controller.totalKm);
                                        uptoKmText = "Up to ${uptoKm.toStringAsFixed(0)} KM";
                                      }
                                      final catName = vehicleTypeName.isNotEmpty
                                          ? vehicleTypeName
                                          : (displayName.contains(' - ')
                                              ? displayName.split(' - ').first.trim()
                                              : (displayName.contains('-')
                                                  ? displayName.split('-').first.trim()
                                                  : displayName));
                                      final titleName = catName.isNotEmpty ? catName : 'Sedan';
                                      return "$titleName ($uptoKmText)";
                                    }(),
                                    style: Styles.txtBlackColorW60016.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: ColorsValue.appColor,
                                    ),
                                  ),
                                  () {
                                    final catName = vehicleTypeName.isNotEmpty
                                        ? vehicleTypeName
                                        : (displayName.contains(' - ')
                                            ? displayName.split(' - ').first.trim()
                                            : (displayName.contains('-')
                                                ? displayName.split('-').first.trim()
                                                : displayName));
                                    final subTitle = (displayName.isNotEmpty && displayName != catName)
                                        ? displayName
                                        : '';
                                    if (subTitle.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          subTitle,
                                          style: Styles.txtG7Colors40014.copyWith(
                                            fontSize: 13,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }(),
                                ],
                              ),
                            ),
                            Dimens.boxWidth12,
                            carPhotoUrl.isNotEmpty
                                ? Image.network(
                                    carPhotoUrl,
                                    height: Dimens.fourtyEight,
                                    width: 70,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Image.asset(
                                      AssetConstants.CarImge,
                                      height: Dimens.fourtyEight,
                                      width: 70,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Image.asset(
                                    AssetConstants.CarImge,
                                    height: Dimens.fourtyEight,
                                    width: 70,
                                    fit: BoxFit.contain,
                                  ),
                          ],
                        ),
                        if (vehicleFeatures.isNotEmpty) ...[
                          Dimens.boxHeight10,
                          Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 12,
                            runSpacing: 8,
                            children: vehicleFeatures.map((feature) {
                              return _smallIconTextNetwork(
                                feature['logo'] ?? "",
                                feature['feature_description'] ?? "",
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                Dimens.boxHeight16,

                // Facilities Tab Card (Inclusion | Exclusion | Facility | Terms & Condition)
                _buildFacilitiesCard(
                  includeFacilities: includeFacilities,
                  excludeFacilities: excludeFacilities,
                  vehicleFeatures: vehicleFeatures,
                  termsConditions: termsConditions,
                ),

                Dimens.boxHeight16,

                // booking form (reuse controller fields)
                Form(
                  key: controller.bookingKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorsValue.whiteColor,
                      borderRadius: BorderRadius.circular(Dimens.twelve),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Obx(
                              () => Checkbox(
                                value: controller.isBookingForAnother.value,
                                onChanged: (val) {
                                  controller.isBookingForAnother.value =
                                      val ?? false;
                                  controller.update();
                                },
                              ),
                            ),
                            Text(
                              'is Booking for another person',
                              style: Styles.black50014,
                            ),
                          ],
                        ),

                        // Only show the Name field if booking for another person
                        Obx(() {
                          if (!controller.isBookingForAnother.value) {
                            controller.nameController =
                                profileController.fullNameController;
                            return const SizedBox.shrink(); // hide field
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Dimens.boxHeight8,
                              CustomTextFormField(
                                style: Styles.txtBlackColorW40014,
                                hintText: "Enter Name".tr,
                                filled: true,
                                isBorder: true,
                                isTitle: true,
                                isCompulsory: false,
                                fillColor: ColorsValue.whiteColor,
                                textEditingController:
                                    controller.nameController,
                                onChanged: (v) {
                                  controller.markUnprocessed();
                                  controller.update();
                                },
                                // validator: (value) {
                                //   if (controller.isBookingForAnother.value && value!.isEmpty) {
                                //     return "Enter Name".tr;
                                //   }
                                //   return null;
                                // },
                                title: "Name".tr,
                                hintStyle: Styles.txtG7Colors40014,
                                titleStyle: Styles.black50014,
                              ),
                              Dimens.boxHeight16,
                            ],
                          );
                        }),
                        //                    AddressSearchField(
                        //   controller: controller.pickupController,
                        //   apiKey: "AIzaSyDzMSluKvGb0AFtFSFphcApmi7tSVsWEuo",
                        //  city: controller.formController.text,
                        //   onSelected: (place) {
                        //     print(place);
                        //     controller.markUnprocessed();
                        //     controller.update();
                        //   },
                        // )
                        // ,
                        //                     Dimens.boxHeight16,
                        //                       AddressSearchField(
                        //   controller: controller.dropController,
                        //   apiKey: "AIzaSyDzMSluKvGb0AFtFSFphcApmi7tSVsWEuo",
                        //   city: controller.toController.text,
                        //  hintText: "Enter Drop Address".tr,
                        //   onSelected: (place) {
                        //     // place['display_name'], place['lat'], place['lon']

                        //     controller.markUnprocessed();
                        //     controller.update();
                        //   },
                        //   // Optional: pass a custom decoration to match your existing UI

                        // ),
                        AddressSearchField(
                          isPickup: true,
                          apiKey: StringConstants.gpooglePlaceKey,
                          controller: controller.pickupController,
                          city: controller.formController.text, // PICKUP
                          onSelected: (place) {
                            controller.pickupController.text =
                                place["display_name"] ?? '';
                            // Only store coords if valid (non-null, non-zero)
                            final lat = double.tryParse(place["lat"]?.toString() ?? '');
                            final lon = double.tryParse(place["lon"]?.toString() ?? '');
                            controller.modifiedPickupLat = (lat != null && lat != 0.0) ? lat : null;
                            controller.modifiedPickupLng = (lon != null && lon != 0.0) ? lon : null;
                            controller.markUnprocessed();
                            if (controller.tripMode == 3) {
                              controller.calculateAirportSlabPrice();
                            } else {
                              controller.recalculateRouteDistance();
                            }
                            controller.update();
                          },
                        ),
                        if (controller.tripMode != 2) ...[
                          Dimens.boxHeight16,
                          AddressSearchField(
                            isPickup: false,
                            apiKey: StringConstants.gpooglePlaceKey,
                            controller: controller.dropController, // DROP
                            city: controller.toController.text,
                            onSelected: (place) {
                              controller.dropController.text =
                                  place["display_name"] ?? '';
                              // Only store coords if valid (non-null, non-zero)
                              final lat = double.tryParse(place["lat"]?.toString() ?? '');
                              final lon = double.tryParse(place["lon"]?.toString() ?? '');
                              controller.modifiedDropLat = (lat != null && lat != 0.0) ? lat : null;
                              controller.modifiedDropLng = (lon != null && lon != 0.0) ? lon : null;
                              controller.markUnprocessed();
                              if (controller.tripMode == 3) {
                                controller.calculateAirportSlabPrice();
                              } else {
                                controller.recalculateRouteDistance();
                              }
                              controller.update();
                            },
                          ),
                        ],

                        //          CustomTextFormField(
                        //     style: Styles.txtBlackColorW40014,
                        //     hintText: "Enter Drop Address".tr,
                        //     filled: true,
                        //     isBorder: true,
                        //     isTitle: true,
                        //     isCompulsory: true,
                        //     fillColor: ColorsValue.whiteColor,
                        //     textEditingController: controller.dropController,
                        //   onChanged: (v) {
                        //   controller.markUnprocessed();
                        //   controller.update();
                        // },
                        //     validator: (value) => value!.isEmpty ? "Enter Drop Address".tr : null,
                        //     title: "Drop address".tr,
                        //     hintStyle: Styles.txtG7Colors40014,
                        //     titleStyle: Styles.black50014,
                        //   ),
                        Dimens.boxHeight16,

                        // Checkbox to choose if booking is for another person
                        CustomTextFormField(
                          style: Styles.txtBlackColorW40014,
                          hintText: "Enter Mobile No".tr,
                          filled: true,
                          isBorder: true,
                          isTitle: true,
                          isCompulsory: true,
                          fillColor: ColorsValue.whiteColor,
                          textEditingController:
                              controller.mobileNumberController =
                                  profileController.phoneNumberController,
                          onChanged: (v) {
                            controller.markUnprocessed();
                            controller.update();
                          },
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              value!.isEmpty ? "Enter Mobile NO".tr : null,
                          title: "mobile_no".tr,
                          hintStyle: Styles.txtG7Colors40014,
                          titleStyle: Styles.black50014,
                        ),
                        Dimens.boxHeight16,
                        CustomTextFormField(
                          style: Styles.txtBlackColorW40014,
                          hintText: "Enter Email (optional)",
                          filled: true,
                          isBorder: true,
                          isTitle: true,
                          isCompulsory: false,
                          fillColor: ColorsValue.whiteColor,
                          textEditingController: controller.emailController,
                          onChanged: (v) {
                            controller.markUnprocessed();
                            controller.update();
                          },

                          title: "email".tr,
                          hintStyle: Styles.txtG7Colors40014,
                          titleStyle: Styles.black50014,
                        ),

                        Dimens.boxHeight16,
                      ],
                    ),
                  ),
                ),

                Dimens.boxHeight16,

                Dimens.boxHeight16,
                InkWell(
                  onTap: () {
                    RouteManagement.gotoCouponoffersScreen();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorsValue.l4CB,
                      borderRadius: BorderRadius.circular(Dimens.twelve),
                    ),
                    child: Padding(
                      padding: Dimens.edgeInsets10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.selectedOffer == null
                                      ? "Apply Coupon & Offers"
                                      : "Coupon Applied: ${controller.selectedOffer?['offer_code'] ?? controller.selectedOffer?['offer_name'] ?? ''}",
                                  style: controller.selectedOffer == null
                                      ? Styles.txtBlackColorW40014
                                      : Styles.txtBlackColorW60016.copyWith(
                                          color: Colors.green.shade700,
                                        ),
                                ),
                                if (controller.selectedOffer != null)
                                  Text(
                                    "Saved ₹${controller.discountAmountComputed.toStringAsFixed(0)} on this ride",
                                    style: Styles.txtG7Colors40014.copyWith(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (controller.selectedOffer == null)
                            const Icon(Icons.arrow_forward_ios_outlined, size: 16)
                          else
                            Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    controller.selectedOffer = null;
                                    controller.discountValue = 0;
                                    controller.updateTotalFare();
                                    controller.update();
                                  },
                                  child: Text(
                                    "Remove",
                                    style: Styles.txtBlackColorW60016.copyWith(
                                      color: Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Dimens.boxWidth12,
                                Text(
                                  "Change",
                                  style: Styles.txtBlackColorW60016.copyWith(
                                    color: ColorsValue.appColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Replace the old Column(...) that maps controller.specialServices with this:
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(1, (index) {
                    return Column(
                      children: [
                        // --- Special Services Section ---
                        Container(
                          decoration: BoxDecoration(
                            color: ColorsValue
                                .whiteColor, // premium card background
                            borderRadius: BorderRadius.circular(Dimens.twelve),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: Dimens.edgeInsets20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔸 Header title
                              Text(
                                "Special Services",
                                style: Styles.txtBlackColorW60016.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: Dimens.sixteen,
                                ),
                              ),
                              Dimens.boxHeight12,

                              // 🔸 List of selectable services
                              if (controller.specialServices.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    "No special services available",
                                    style: Styles.txtG7Colors40014.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...List.generate(
                                  controller.specialServices.length,
                                  (index) {
                                    final s = controller.specialServices[index];
                                    final id = s['_id'];
                                    final description =
                                        s['description']?.toString() ??
                                        s['service_name']?.toString() ??
                                        s['name']?.toString() ??
                                        '';
                                    final amountNum = (s['amount'] is num
                                        ? (s['amount'] as num).toDouble()
                                        : (s['price'] is num
                                            ? (s['price'] as num).toDouble()
                                            : double.tryParse(s['amount']?.toString() ?? s['price']?.toString() ?? '0') ?? 0.0));
                                    final amountText = '₹${amountNum.toStringAsFixed(0)}';
                                    final isSelected = controller
                                        .selectedServiceIds
                                        .contains(id);

                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            controller.markUnprocessed();

                                            if (isSelected) {
                                              controller.selectedServiceIds
                                                  .remove(id);
                                            } else {
                                              controller.selectedServiceIds.add(
                                                id,
                                              );
                                            }
                                            controller.updateTotalFare();
                                          },

                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: Dimens.twelve,
                                            ),
                                            child: Row(
                                              children: [
                                                // ✅ Custom square checkbox
                                                Container(
                                                  height: Dimens.twentyFive,
                                                  width: Dimens.twentyFive,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? ColorsValue.appColor
                                                          : ColorsValue
                                                                .borderColors,
                                                      width: 2,
                                                    ),
                                                    color: isSelected
                                                        ? ColorsValue.appColor
                                                        : Colors.transparent,
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 14,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                                Dimens.boxWidth10,

                                              // 📝 Description
                                              Expanded(
                                                child: Text(
                                                  description,
                                                  style: Styles.txtG7Colors40014
                                                      .copyWith(
                                                        color: ColorsValue
                                                            .txtG5Colors,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                ),
                                              ),

                                              // 💰 Amount
                                              Text(
                                                amountText,
                                                style: Styles
                                                    .txtBlackColorW60016
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Divider line between items
                                      if (index !=
                                          controller.specialServices.length - 1)
                                        Container(
                                          height: 1,
                                          color: ColorsValue.borderColors,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // divider
                        if (index != controller.specialServices.length - 1) ...[
                          Dimens.boxHeight4,
                          //  Container(height: 1, color: ColorsValue.borderColors),
                        ],
                      ],
                    );
                  }),
                ),

                Dimens.boxHeight16,
                // fare summary (basic)
                // Toggle for Fare Breakup
                // Toggle for Fare Breakup
                _buildExpandableFareBreakup(
                  controller: controller,
                  isExpanded: _showFareBreakup,
                  onToggle: () {
                    setState(() {
                      _showFareBreakup = !_showFareBreakup;
                    });
                  },
                  title: "View Fare Break up",
                ),

                // ---------- Replace payment options + pay buttons with this block ----------
                Dimens.boxHeight16,

                // Process Booking / processing indicator / booking processed summary
                GetBuilder<HomeController>(
                  builder: (controller) {
                    // 1) While API call in progress: show a disabled button with a spinner
                    if (controller.isProcessingBooking) {
                      return Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorsValue.appColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimens.twenty,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                Dimens.boxWidth8,
                                Text(
                                  "Processing...",
                                  style: Styles.whiteColorW50014,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // 2) If booking already processed: show fare-summary style card and Proceed button
                    // -------------------- bookingProcessed UI (replace existing processed block) --------------------
                    if (controller.bookingProcessed) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (controller.scrollController!.hasClients) {
                          controller.scrollController!.animateTo(
                            controller
                                .scrollController!
                                .position
                                .maxScrollExtent,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Payment Details title + card grid
                          Dimens.boxHeight20,

                          Container(
                            padding: Dimens.edgeInsets16,
                            decoration: BoxDecoration(
                              color: ColorsValue.l4CB,
                              borderRadius: BorderRadius.circular(
                                Dimens.twelve,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "Payment Details",
                                    style: Styles.txtBlackColorW70018,
                                  ),
                                ),
                                Dimens.boxHeight20,
                                // Grid 2x2 for 0/25/50/100 percent options
                                // Put this where you currently have the GridView.count
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: Dimens.ten,
                                  crossAxisSpacing: Dimens.ten,
                                  // Responsive childAspectRatio: widthOfTile / desiredHeight
                                  // Here we pick desiredHeight = 120 logical pixels (adjust as needed).
                                  childAspectRatio:
                                      (Get.width / 2.5 - (Dimens.ten)) / 120,
                                  children: controller.paymentOptions.map((
                                    option,
                                  ) {
                                    return _paymentOptionCard(
                                      context: context,
                                      controller: controller,
                                      option: option,
                                    );
                                  }).toList(),
                                ),

                                Dimens.boxHeight12,

                                // GST checkbox + fields
                                InkWell(
                                  onTap: () =>
                                      controller.toggleGst(!controller.hasGst),
                                  child: Row(
                                    children: [
                                      Container(
                                        height: Dimens.twentyFive,
                                        width: Dimens.twentyFive,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          color: controller.hasGst
                                              ? ColorsValue.appColor
                                              : Colors.white,
                                          border: Border.all(
                                            color: controller.hasGst
                                                ? ColorsValue.appColor
                                                : ColorsValue.borderColors,
                                          ),
                                        ),
                                        child: controller.hasGst
                                            ? Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      Dimens.boxWidth8,
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: "I have a GST Number",
                                                style:
                                                    Styles.txtBlackColorW50014,
                                              ),
                                              TextSpan(
                                                text: "  (Optional)",
                                                style: Styles.txtG7Colors40014,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Dimens.boxHeight12,

                                if (controller.hasGst) ...[
                                  CustomTextFormField(
                                    style: Styles.txtBlackColorW40014,
                                    hintText: "Enter Company Name",
                                    filled: true,
                                    isBorder: true,
                                    isTitle: true,
                                    fillColor: ColorsValue.whiteColor,
                                    textEditingController:
                                        controller.companyNameController,
                                    title: "Company Name",
                                    hintStyle: Styles.txtG7Colors40014,
                                  ),
                                  Dimens.boxHeight12,
                                  CustomTextFormField(
                                    style: Styles.txtBlackColorW40014,
                                    hintText: "Enter GST no.",
                                    filled: true,
                                    isBorder: true,
                                    isTitle: true,
                                    fillColor: ColorsValue.whiteColor,
                                    textEditingController:
                                        controller.gstNoController,
                                    title: "GST No.",
                                    hintStyle: Styles.txtG7Colors40014,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          Dimens.boxHeight16,

                          // Fare Breakdown card (small)
                          // Fare Breakdown card (small) -> Now dynamic and expandable
                          _buildExpandableFareBreakup(
                            controller: controller,
                            isExpanded: _showPaymentFareBreakup,
                            onToggle: () {
                              setState(() {
                                _showPaymentFareBreakup =
                                    !_showPaymentFareBreakup;
                              });
                            },
                            title: "View Fare Break up",
                          ),

                          Dimens.boxHeight16,

                          // Proceed button
                          CustomButton(
                            backgroundColor: ColorsValue.appColor,
                            isboxsedo: true,
                            onPressed: () =>
                                controller.onProceedPressed(context),
                            text: controller.selectedAdvancePercent == 0
                                ? "Book Now"
                                : "Pay Now ₹ ${controller.advanceAmount.toStringAsFixed(0)}",
                            textStyle: Styles.txtBlackColorW60016.copyWith(
                              color: ColorsValue.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Dimens.boxHeight25,
                        ],
                      );
                    }

                    // 3) Default state - show single Process Booking button
                    return CustomButton(
                      backgroundColor: ColorsValue.appColor,
                      isboxsedo: true,
                      onPressed: () {
                        // call process booking; UI will switch to spinner using flags
                        controller.processBooking();
                      },
                      text: "Process Booking",
                      textStyle: Styles.txtBlackColorW60016.copyWith(
                        color: ColorsValue.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                Dimens.boxHeight25,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpandableFareBreakup({
    required HomeController controller,
    required bool isExpanded,
    required VoidCallback onToggle,
    required String title,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: Dimens.twelve),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Styles.appColorw50014),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: ColorsValue.appColor,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              color: ColorsValue.whiteColor,
              borderRadius: BorderRadius.circular(Dimens.twelve),
            ),
            child: Padding(
              padding: Dimens.edgeInsets20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("fare_summary".tr, style: Styles.txtBlackColorW60016),
                  Dimens.boxHeight20,

                  // Base Fare
                  if (controller.displayBaseFare > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Base Fare${controller.tripMode == 1 && controller.tripDaysNum > 1 ? ' (₹${controller.baseFarePerDay.toStringAsFixed(0)} × ${controller.tripDaysNum} Days)' : ''}",
                          style: Styles.txtG7Colors40014,
                        ),
                        Text(
                          "₹${controller.displayBaseFare.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW40014,
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // Total KMs (dynamic - recalculates when user picks specific pickup/drop)
                  Builder(
                    builder: (context) {
                      final tkm = controller.currentTotalKm;
                      if (tkm > 0) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total KMs",
                                  style: Styles.txtG7Colors40014,
                                ),
                                controller.isCalculatingDistance
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "${tkm.toStringAsFixed(0)} KM",
                                        style: Styles.txtBlackColorW40014,
                                      ),
                              ],
                            ),
                            Dimens.boxHeight10,
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Included KMs
                  Builder(
                    builder: (context) {
                      final ikm = controller.currentIncludedKm;
                      if (ikm > 0) {
                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Included KMs${controller.tripMode == 1 && controller.tripDaysNum > 1 ? ' (${controller.includedKmPerDay.toStringAsFixed(0)}KM × ${controller.tripDaysNum} Days)' : ''}",
                                  style: Styles.txtG7Colors40014,
                                ),
                                Text(
                                  "${ikm.toStringAsFixed(0)} KM",
                                  style: Styles.txtBlackColorW40014,
                                ),
                              ],
                            ),
                            Dimens.boxHeight10,
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Trip Days
                  if (controller.tripMode == 1) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Trip Days", style: Styles.txtG7Colors40014),
                        Text(
                          "${controller.tripDaysNum} Days",
                          style: Styles.txtBlackColorW40014,
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // Extra KMs & Extra KMs Charge (exact match with website ReviewBooking.jsx)
                  if ((controller.tripMode == 0 || controller.tripMode == 1) &&
                      controller.currentExtraKm > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Extra KMs", style: Styles.txtG7Colors40014),
                        Text(
                          "${controller.currentExtraKm.toStringAsFixed(0)} KM",
                          style: Styles.txtBlackColorW40014,
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Extra KMs Charge${controller.perKmRate > 0 ? ' (₹${controller.perKmRate.toStringAsFixed(0)}/KM)' : ''}",
                          style: Styles.txtG7Colors40014,
                        ),
                        Text(
                          "₹${controller.extraKMsCharge.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW40014,
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // Special Services with itemized breakdown
                  if (controller.selectedServiceIds.isNotEmpty && controller.specialServicesTotal > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Special Services",
                          style: Styles.txtG7Colors40014.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "₹${controller.specialServicesTotal.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW60016,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...controller.selectedServiceIds.map((id) {
                      final svc = controller.specialServices.firstWhereOrNull((s) => s['_id'] == id);
                      if (svc == null) return const SizedBox.shrink();
                      final desc = (svc['description'] ?? svc['name'] ?? svc['service_name'] ?? 'Service').toString();
                      final amt = (svc['amount'] is num)
                          ? (svc['amount'] as num).toDouble()
                          : (num.tryParse(svc['amount']?.toString() ?? '0') ?? 0.0);
                      return Padding(
                        padding: const EdgeInsets.only(left: 14.0, bottom: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "➔ $desc",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              "₹${amt.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Dimens.boxHeight10,
                  ],

                  // Coupon Discount
                  if (controller.discountAmountComputed > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Coupon Discount",
                          style: Styles.txtG7Colors40014.copyWith(
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          "- ₹${controller.discountAmountComputed.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW60016.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // Dashed Divider before Total Fare
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final boxWidth = constraints.constrainWidth();
                      const dashWidth = 4.0;
                      const dashHeight = 1.0;
                      final dashCount = (boxWidth / (2 * dashWidth)).floor();
                      return Flex(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        direction: Axis.horizontal,
                        children: List.generate(dashCount, (_) {
                          return SizedBox(
                            width: dashWidth,
                            height: dashHeight,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: ColorsValue.borderColors,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  Dimens.boxHeight12,

                  // Total Fare (Pre-Tax Total - Highlighted in Orange)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Fare",
                        style: Styles.txtBlackColorW60016.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "₹${controller.preTaxFare.toStringAsFixed(0)}",
                        style: Styles.txtBlackColorW60016.copyWith(
                          color: ColorsValue.appColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Dimens.boxHeight10,

                  // GST
                  if (controller.gstAmount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GST (${controller.gstPercent}%)",
                          style: Styles.txtG7Colors40014,
                        ),
                        Text(
                          "₹${controller.gstAmount.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW60016,
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // Pending Payment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pending Payment",
                        style: Styles.txtG7Colors40014,
                      ),
                      Text(
                        "${100 - controller.selectedAdvancePercent}%",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                      Text(
                        "₹${(controller.selectedAdvancePercent > 0 ? controller.laterAmount : controller.totalFare).toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  Dimens.boxHeight10,

                  // Advance Payment
                  if (controller.selectedAdvancePercent > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Advance Payment (${controller.selectedAdvancePercent}%)",
                          style: Styles.txtG7Colors40014.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          "₹${controller.advanceAmount.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW60016.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // To Pay Driver
                  if (controller.selectedAdvancePercent > 0 && controller.selectedAdvancePercent < 100) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "To Pay Driver (${100 - controller.selectedAdvancePercent}%)",
                          style: Styles.txtG7Colors40014.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "₹${controller.laterAmount.toStringAsFixed(0)}",
                          style: Styles.txtBlackColorW60016.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,
                  ],

                  // Final Total Fare (Post-Tax Total matching website)
                  Container(height: 1, color: ColorsValue.borderColors),
                  Dimens.boxHeight10,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Fare",
                        style: Styles.txtG7Colors40014,
                      ),
                      Text(
                        "₹${controller.totalFare.toStringAsFixed(0)}",
                        style: Styles.txtBlackColorW60016,
                      ),
                    ],
                  ),
                  Dimens.boxHeight10,

                  if (controller.tripMode == 1) ...[
                    Dimens.boxHeight10,
                    Text(
                      "Toll Tax, Parking Charges, and State Tax are extra and must be paid by the customer during the trip.",
                      style: Styles.txtBlackColorW60016.copyWith(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ],

                  Dimens.boxHeight21,
                  Container(height: 1, color: ColorsValue.borderColors),
                  Dimens.boxHeight28,
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Card widget - matches screenshot style
Widget _paymentOptionCard({
  required BuildContext context,
  required PaymentOption option,
  required HomeController controller,
}) {
  final bool isSelected = controller.selectedPaymentId == option.id;

  // Example calculation for now vs later amounts (replace with your actual logic)
  // assume `totalFare` is accessible or pass it in
  final double totalFare = controller.totalFare; // fallback for preview
  final double nowAmount = (totalFare * (option.advancePercentage / 100));
  final double laterAmount = (totalFare - nowAmount);

  return InkWell(
    onTap: () {
      controller.selectedPaymentId = option.id;
      controller.selectedAdvancePercent = option.advancePercentage;
      controller.update();
    },
    borderRadius: BorderRadius.circular(Dimens.twelve),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? ColorsValue.l4CB.withOpacity(0.9)
            : ColorsValue.l4CB,
        borderRadius: BorderRadius.circular(Dimens.twelve),
        border: Border.all(
          color: isSelected ? ColorsValue.appColor : ColorsValue.l4CB,
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // left radio circle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? ColorsValue.appColor
                      : ColorsValue.borderColors,
                  width: 2,
                ),
                color: isSelected
                    ? ColorsValue.appColor.withOpacity(0.12)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: ColorsValue.appColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // right content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Big percent or name
                Text(
                  option.advancePercentage == 0
                      ? '0%'
                      : '${option.advancePercentage}%',
                  style: option.advancePercentage == 0
                      ? Styles.txtBlackColorW70018.copyWith(fontSize: 25)
                      : Styles.txtBlackColorW70018.copyWith(fontSize: 25),
                ),

                //
                Row(
                  children: [
                    //  Text('%', style: Styles.txtG7Colors40014.copyWith(fontSize: 14)),
                    const Spacer(),
                  ],
                ),

                Dimens.boxHeight8,

                // sub text: amount now or later
                Text(
                  option.advancePercentage == 0
                      ? '₹${laterAmount.toInt()} later'
                      : '₹${nowAmount.toInt()} now',
                  style: Styles.txtG7Colors40014.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

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
