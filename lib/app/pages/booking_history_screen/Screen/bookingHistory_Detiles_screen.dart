import 'dart:io';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';
import 'package:bam_bam_user/data/helpers/helpers.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_native_html_to_pdf/flutter_native_html_to_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'dart:convert';

import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:bam_bam_user/app/widgets/facility_icon_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BookinghistoryDetilesScreen extends StatefulWidget {
  const BookinghistoryDetilesScreen({super.key});

  @override
  State<BookinghistoryDetilesScreen> createState() =>
      _BookinghistoryDetilesScreenState();
}

class _BookinghistoryDetilesScreenState
    extends State<BookinghistoryDetilesScreen> {
  int _selectedFacilityTab = 0;

  String _cleanHtml(String htmlString) {
    return htmlString
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BookingHistoryController>(
      initState: (state) {
        var controller = Get.find<BookingHistoryController>();
        final args = Get.arguments as Map<String, dynamic>? ?? {};
        controller.isCancel = args["isCancel"] ?? false;
        controller.isAgainBooking = args["isAgainBooking"] ?? false;
        controller.isReview = args["isReview"] ?? false;

        final bookingId = args["id"];
        if (bookingId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.fetchBookingDetails(bookingId);
          });
        }
      },
      builder: (controller) {
        final data = controller.bookingDetails;

        // ⛔ If data is still loading → show loader
        if (data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Now safe to use data
        final driver = data["driverDetails"] ?? {};

        final driverName = driver["driver_name"] ?? "—";
        final driverMobile = driver["driver_mobile"] ?? "—";
        final driverPhoto = driver["driver_photo"] != null
            ? "${ApiWrapper.imageUrl}${driver["driver_photo"]}"
            : null;
        final driverLanguages = (driver["language_known"] as List? ?? [])
            .map((e) => e["name"] ?? "")
            .join(", ");

        if (data == null || data.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("No booking details found")),
          );
        }
        final vehicleNumber = data["vehiclesDetails"]?["vehicle_number"] ?? "—";
        final rawFuel = data["vehiclesDetails"]?["fuel_type"];
        final fuelType = (rawFuel is List)
            ? rawFuel
                .map((item) =>
                    item is Map ? (item["name"] ?? "") : item.toString())
                .where((s) => s.isNotEmpty)
                .join(", ")
            : (rawFuel?.toString() ?? "—");
        final modelYear =
            data["vehiclesDetails"]?["vehicle_make_year"]?.toString() ?? "—";

        final travel = data["travelDetails"] ?? {};
        final travell = data["exploreCabsDetails"] ?? {};

        final vehicle = data["vehiclesDetails"] ?? {};
        final services = (data["specialServicesDetails"] ?? data["SpecialServicesDetails"]) as List<dynamic>? ?? [];

        // booking info
        final bookingId = data["booking_id"] ?? "";
        final bookingIdforPayment = data["_id"] ?? "";
        final bookingStatus = data["booking_status"] ?? "";
        final totalPayment = data["total_payment"]?.toString() ?? "";
        final paymentMode = data["payment_mode"]?.toString() ?? "";
        final paidAmount = data["sub_total_payment"]?.toString() ?? "";
        final review = data["review"];
        final bool isReview =
            review == null || (review["comments"]?.toString().isEmpty ?? true);

        final pendingPayment = data["pending_payment"]?.toString() ?? "0";
        // travel info
        final tripType = travel["trip_type"] ?? "";
        final from = travell["from"] ?? travel["city"] ?? "";
        final toList =
            (travell["to"] as List?)?.whereType<String>().toList() ?? [];
        final toDisplay = toList.isNotEmpty ? toList.join(", ") : "—";
        final pickupAddress = travel["pickup_address"] ?? "—";
        final dropAddress =
            (travel["drop_address"] as List?)?.join(", ") ?? "—";
        final date = (travel["date"] ?? "").toString().split("T").first;
        final returnDate = (travel["return_date"] ?? travell["return_date"] ?? "").toString().split("T").first;
        final pickupTime = travel["pickup_time"] ?? "";
        final travelerName = travel["traveler_name"] ?? "";
        final travelerEmail = travel["traveler_email"] ?? "";
        final travelerMobile = travel["traveler_mobile"] ?? "";

        // vehicle info
        final brandName = vehicle["brand_name"] ?? "—";

        final carPhoto =
            vehicle["vehicle_type"] != null &&
                vehicle["vehicle_type"]["vehicle_photo"] != null
            ? "${vehicle["vehicle_type"]["vehicle_photo"]}"
            : null;
        final vehicleName =
            vehicle["vehicle_type"] != null &&
                vehicle["vehicle_type"]["name"] != null
            ? "${vehicle["vehicle_type"]["name"]}"
            : null;

        final vehicleTypeObj = (data["vehiclesDetails"]?["vehicle_type"] is Map)
            ? (data["vehiclesDetails"]["vehicle_type"] as Map)
            : (data["vehicleDetails"]?["vehicle_type"] is Map)
                ? (data["vehicleDetails"]["vehicle_type"] as Map)
                : (data["exploreCabsDetails"]?["vehicle_type"] is Map)
                    ? (data["exploreCabsDetails"]["vehicle_type"] as Map)
                    : (data["travelDetails"]?["vehicle_type"] is Map)
                        ? (data["travelDetails"]["vehicle_type"] as Map)
                        : (vehicle["vehicle_type"] is Map
                            ? (vehicle["vehicle_type"] as Map)
                            : {});

        final statesList = (vehicleTypeObj["states"] as List?) ?? [];
        final state = statesList.isNotEmpty && statesList[0] is Map
            ? (statesList[0] as Map)
            : {};
        final includeFacilities = (state["includeFacilities"] as List?) ?? [];
        final excludeFacilities = (state["excludeFacilities"] as List?) ?? [];
        final vehicleFeatures = (state["vehicleFeatures"] as List?) ?? [];
        final termsConditions = state["terms_conditions"]?.toString() ?? '';

        final features = vehicleFeatures.isNotEmpty
            ? vehicleFeatures
            : (statesList.isNotEmpty && statesList[0] is Map
                ? (statesList[0]["vehicleFeatures"] as List<dynamic>? ?? [])
                : []);
        final tripTrackingOtp = data["trip_tracking_otp"].toString();
        final statusLower = bookingStatus.toLowerCase();
        final bool showAllocatedVehicleDetails = statusLower == "d & v allocated" ||
            statusLower.contains("alloc") ||
            statusLower == "driver arrived" ||
            statusLower == "ongoing" ||
            statusLower.contains("complete") ||
            (statusLower == "confirmed" && (data['driverDetails'] != null || data['driver_id'] != null));
        final bool isEditable = !statusLower.contains("complete") &&
                                !statusLower.contains("ongoing") &&
                                !statusLower.contains("cancel") &&
                                !statusLower.contains("expire");
        // pendingAmountForPay moved below displayWaitingCharge calculation
        String badgeImage;
        Color textColor;
        String displayStatusText = 'Booking Completed';

        if (statusLower == "confirmed") {
          badgeImage = AssetConstants.Green_CN;
          textColor = const Color(0xFFFF5A00); // Orange-red matching #ff5a00
          displayStatusText = "Booking Confirmed";
        } else if (statusLower == "pending") {
          badgeImage = AssetConstants.Green_CN;
          textColor = const Color(0xFFF59E0B); // Amber
          displayStatusText = "Booking Pending";
        } else if (statusLower == "cancelled") {
          badgeImage = AssetConstants.Red_CN;
          textColor = ColorsValue.txtRedColor;
          displayStatusText = "Booking Cancelled";
        } else if (statusLower == "expired") {
          badgeImage = AssetConstants.Red_CN;
          textColor = ColorsValue.txtRedColor;
          displayStatusText = "Booking Expired";
        } else if (statusLower == "d & v allocated" || statusLower.contains("alloc")) {
          badgeImage = AssetConstants.Green_CN;
          textColor = const Color(0xFF00C0E8); // Cyan
          displayStatusText = "Driver & Vehicle Allocated";
        } else if (statusLower.contains("complete")) {
          badgeImage = AssetConstants.Green_CN;
          textColor = const Color(0xFF12724A); // Green
          displayStatusText = "Booking Completed";
        } else if (statusLower == "driver arrived") {
          badgeImage = AssetConstants.Green_CN;
          textColor = const Color(0xFFF59E0B); // Amber
          displayStatusText = "Driver Arrived";
        } else {
          badgeImage = AssetConstants.Green_CN;
          textColor = ColorsValue.appColor;
          displayStatusText = bookingStatus;
        }
        String formatDate(String apiDate) {
          try {
            final parsed = DateTime.parse(apiDate); // e.g. 2025-11-25
            return DateFormat('dd-MM-yyyy').format(parsed); // → 25-11-2025
          } catch (_) {
            return apiDate; // fallback if parse fails
          }
        }

        final fareSummary = travel["fare_summary"] ?? {};
        final bf = fareSummary["base_fare"]?.toString() ?? data['amount']?['baseFare']?.toString() ?? "0";
        final baseFare = double.tryParse(bf) ?? 0.0;
        
        final discount = fareSummary["coupon_discount"]?.toString() ?? 
                         fareSummary["discount_amount"]?.toString() ?? 
                         data['amount']?['discount']?.toString() ?? 
                         travel["offer_discount"]?.toString() ?? "0";
        final discountAmount = double.tryParse(discount) ?? 0.0;
        
        final incKms = travel["total_limit_km"]?.toString() ?? travel["km_included"]?.toString() ?? fareSummary["included_km"]?.toString() ?? "0";
        final couponCode = data["offersDetails"]?["offer_code"]?.toString() ?? "";
        final ssPriceRaw = fareSummary["special_services"]?.toString() ?? data['amount']?['specialServicesPrice']?.toString() ?? "0";
        final specialServicesPrice = double.tryParse(ssPriceRaw) ?? 0.0;

        final double totalPayNum = double.tryParse(totalPayment) ?? 0.0;
        final gstPctRaw = fareSummary["gst_percent"]?.toString() ?? "5";
        final double gstPercent = double.tryParse(gstPctRaw) ?? 5.0;

        final double waitingCharge = double.tryParse((data["waiting_charge"] ?? 0).toString()) ?? 0.0;
        final int waitingMins = int.tryParse((data["total_waiting_minutes"] ?? 0).toString()) ?? 0;
        final double displayWaitingCharge = statusLower == "driver arrived" 
            ? controller.accumulatedWaitingCharge 
            : waitingCharge;
        final int displayWaitingMins = statusLower == "driver arrived" 
            ? (controller.elapsedSeconds ~/ 60)
            : waitingMins;

        double displayBaseFare = baseFare;
        double gstAmount = double.tryParse((fareSummary["gst_amount"] ?? fareSummary["gst_included"])?.toString() ?? "0") ?? 0.0;
        if (gstAmount == 0 && data['amount'] != null) {
          final c = double.tryParse(data['amount']['cgst']?.toString() ?? '0') ?? 0.0;
          final s = double.tryParse(data['amount']['sgst']?.toString() ?? '0') ?? 0.0;
          gstAmount = c + s;
        }
        if (displayBaseFare == 0 && totalPayNum > 0) {
          final double taxableSubtotal = (gstPercent > 0)
              ? (totalPayNum / (1 + gstPercent / 100)).roundToDouble()
              : totalPayNum;
          if (gstAmount == 0) gstAmount = totalPayNum - taxableSubtotal;
          displayBaseFare = taxableSubtotal - specialServicesPrice + discountAmount;
        }

        final fbMap = data['vendorRequestDetails']?['fare_breakdown'] ?? data['fare_breakdown'] ?? travel['fare_breakdown'];
        final bool isCompletedTrip = statusLower.contains("complete") || statusLower == "payment pending";
        final bool hasFbData = isCompletedTrip && fbMap != null && (fbMap['base_fare'] != null || fbMap['final_payable_amount'] != null);

        final double rawFbBaseFare = double.tryParse((data['vendorRequestDetails']?['fare_breakdown']?['base_fare'] ?? fbMap?['base_fare'] ?? data['vendorRequestDetails']?['base_collect_amount'] ?? data['base_collect_amount'])?.toString() ?? "0") ?? 0.0;
        final double fbBaseFare = rawFbBaseFare > 0 ? rawFbBaseFare : (displayBaseFare > 0 ? displayBaseFare : baseFare);
        final double fbWaitingCharge = double.tryParse(fbMap?['waiting_charge']?.toString() ?? "0") ?? 0.0;
        final double fbExtraKm = double.tryParse(fbMap?['extra_km']?.toString() ?? "0") ?? 0.0;
        final double fbPerKmPrice = double.tryParse(fbMap?['per_km_price']?.toString() ?? "0") ?? 0.0;
        final double fbExtraKmCharge = double.tryParse(fbMap?['extra_km_charge']?.toString() ?? "0") ?? 0.0;
        final double fbDiscountAmount = double.tryParse(fbMap?['discount_amount']?.toString() ?? "0") ?? 0.0;
        final double fbGstAmount = double.tryParse(fbMap?['gst_amount']?.toString() ?? "0") ?? 0.0;
        final double fbGstPercent = double.tryParse(fbMap?['gst_percent']?.toString() ?? "5") ?? 5.0;
        final double fbFinalPayable = double.tryParse(fbMap?['final_payable_amount']?.toString() ?? "0") ?? 0.0;
        final double actualDistKm = double.tryParse((data['actual_distance_km'] ?? data['vendorRequestDetails']?['actual_distance_km'] ?? "0").toString()) ?? 0.0;

        // Unified values matching Website BookingDetail.jsx
        final double effectiveBaseFare = hasFbData
            ? (fbBaseFare > 0 ? fbBaseFare : displayBaseFare)
            : (displayBaseFare > 0 ? displayBaseFare : baseFare);

        final double effectiveCalculatedKm = controller.calculatedDistanceKm ?? 0.0;
        final double rawTotalDistanceKm = hasFbData
            ? (double.tryParse((fbMap?['total_distance_km'] ?? fbMap?['actual_distance_km'] ?? data['vendorRequestDetails']?['actual_distance_km'] ?? actualDistKm).toString()) ?? 0.0)
            : (double.tryParse((travel['actual_distance_km'] ?? fareSummary['actual_km'] ?? fareSummary['total_distance_km'] ?? data['exploreCabsDetails']?['totalKm'] ?? travel['distance_km'] ?? travel['distance'] ?? "0").toString()) ?? 0.0);

        final double totalDistanceKm = rawTotalDistanceKm > 0
            ? rawTotalDistanceKm
            : (effectiveCalculatedKm > 0 ? effectiveCalculatedKm : 0.0);

        final double includedKm = hasFbData
            ? (double.tryParse((fbMap?['included_km'] ?? fareSummary['included_km'] ?? travel['km_included'] ?? travel['total_limit_km'] ?? "0").toString()) ?? 0.0)
            : (double.tryParse((fareSummary['included_km'] ?? travel['km_included'] ?? travel['total_limit_km'] ?? data['exploreCabsDetails']?['totalKm'] ?? incKms).toString()) ?? 0.0);

        final double perKmPrice = hasFbData
            ? (fbPerKmPrice > 0 ? fbPerKmPrice : (double.tryParse((fareSummary['per_km_price'] ?? "0").toString()) ?? 0.0))
            : (double.tryParse((fareSummary['per_km_price'] ?? data['exploreCabsDetails']?['per_km_price'] ?? data['exploreCabsDetails']?['perKm'] ?? data['vehicleDetails']?['vehicle_type']?['states']?[0]?['cities']?[0]?['per_km_price'] ?? "11").toString()) ?? 11.0);

        // extraKm: use saved values from database if available!
        final double savedExtraKm = double.tryParse((fareSummary['extra_km'] ?? travel['extra_km'] ?? "0").toString()) ?? 0.0;
        final double computedExtraKm = (totalDistanceKm > includedKm && includedKm > 0) ? (totalDistanceKm - includedKm) : 0.0;
        final double extraKm = hasFbData
            ? fbExtraKm
            : (savedExtraKm > 0 ? savedExtraKm : computedExtraKm);

        final double savedExtraKmCharge = double.tryParse((fareSummary['extra_km_charge'] ?? travel['extra_km_charge'] ?? "0").toString()) ?? 0.0;
        final double extraKmCharge = hasFbData
            ? fbExtraKmCharge
            : (savedExtraKmCharge > 0 ? savedExtraKmCharge : (extraKm * perKmPrice).roundToDouble());

        final double startKm = double.tryParse((data['vendorRequestDetails']?['start_km'] ?? fbMap?['start_km'] ?? "0").toString()) ?? 0.0;
        final double endKm = double.tryParse((data['vendorRequestDetails']?['end_km'] ?? fbMap?['end_km'] ?? "0").toString()) ?? 0.0;

        final double effectiveWaitingCharge = hasFbData ? fbWaitingCharge : displayWaitingCharge;
        final double effectiveDiscount = hasFbData && fbDiscountAmount > 0 ? fbDiscountAmount : discountAmount;

        final double savedTotalBeforeTax = double.tryParse((fareSummary['total_fare_before_tax'] ?? travel['total_fare_before_tax'] ?? "0").toString()) ?? 0.0;
        final double totalFareBeforeTax = (hasFbData && fbMap?['total_fare_before_tax'] != null)
            ? (double.tryParse(fbMap!['total_fare_before_tax'].toString()) ?? 0.0)
            : (savedTotalBeforeTax > 0
                ? savedTotalBeforeTax
                : ((effectiveBaseFare + extraKmCharge + specialServicesPrice + effectiveWaitingCharge - effectiveDiscount).clamp(0.0, double.infinity)));

        final double effectiveGstPercent = hasFbData ? fbGstPercent : gstPercent;
        final double savedGstAmount = double.tryParse((fareSummary['gst_amount'] ?? travel['gst_amount'] ?? "0").toString()) ?? 0.0;
        final double effectiveGstAmount = (hasFbData && fbGstAmount > 0)
            ? fbGstAmount
            : (savedGstAmount > 0
                ? savedGstAmount
                : (effectiveGstPercent > 0 ? ((totalFareBeforeTax * effectiveGstPercent) / 100).roundToDouble() : gstAmount));

        final List additionalChargesList = (fbMap?['additional_charges_details'] is List)
            ? (fbMap!['additional_charges_details'] as List)
            : [];
        final double additionalChargesTotal = hasFbData
            ? ((double.tryParse(fbMap?['additional_service_charges']?.toString() ?? "0") ?? 0.0) +
                additionalChargesList.fold<double>(0.0, (sum, item) => sum + (double.tryParse(item?['amount']?.toString() ?? "0") ?? 0.0)))
            : 0.0;

        final double savedTotalFare = double.tryParse((fareSummary['total_fare'] ?? data['total_payment'] ?? travel['total_fare'] ?? "0").toString()) ?? 0.0;
        final double calculatedTotalPayment = (hasFbData && fbFinalPayable > 0)
            ? fbFinalPayable
            : (savedTotalFare > 0
                ? (savedTotalFare + additionalChargesTotal)
                : (totalFareBeforeTax + effectiveGstAmount + additionalChargesTotal));

        final double paidAmountVal = double.tryParse((data['sub_total_payment'] ?? paidAmount ?? "0").toString()) ?? 0.0;
        final double displayPendingPaymentVal = (calculatedTotalPayment - paidAmountVal).clamp(0.0, double.infinity);
        final int livePendingAmountForPay = displayPendingPaymentVal.round();

        String formatAmt(double val) {
          if (val % 1 == 0) {
            return val.toInt().toString();
          }
          return val.toStringAsFixed(2);
        }


        return Scaffold(
          appBar: AppBarWidget(
            onTapBack: () => Get.back(),
            title: "Booking history",
          ),
          backgroundColor: ColorsValue.appBg,
          body: PullToRefreshWrapper(
            onRefresh: () => controller.fetchBookingDetails((Get.arguments as Map<String, dynamic>?)?["id"] ?? ""),
            child: ListView(
              key: ValueKey(data["_id"] ?? data["id"] ?? "booking_details_list"),
              physics: kPullToRefreshScrollPhysics,
              padding: Dimens.edgeInsets20,
              children: [
              // 🟨 Notice Bar (Hidden if status is cancelled, completed, pending, expired, allocated, ongoing, or driver arrived)
              if (!statusLower.contains("cancel") &&
                  !statusLower.contains("complete") &&
                  !statusLower.contains("pending") &&
                  !statusLower.contains("expire") &&
                  !statusLower.contains("alloc") &&
                  !statusLower.contains("ongoing") &&
                  statusLower != "driver arrived") ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimens.twenty),
                    color: ColorsValue.yellocolors2CB,
                  ),
                  padding: Dimens.edgeInsets20,
                  child: Text(
                    "Driver details will be shared 1 hour and 30 mins before ride.",
                    textAlign: TextAlign.center,
                    style: Styles.appColorw50014.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Dimens.boxHeight12,
              ],

              if (statusLower == "driver arrived" || statusLower == "d & v allocated" || statusLower.contains("alloc")) ...[
                // Custom Arrival Banner
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                    color: ColorsValue.appColor.withOpacity(0.12),
                    border: Border.all(color: ColorsValue.appColor, width: 1),
                  ),
                  padding: Dimens.edgeInsets16,
                  child: Row(
                    children: [
                      Icon(
                        statusLower == "driver arrived" ? Icons.check_circle_outline : Icons.info_outline,
                        color: ColorsValue.appColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusLower == "driver arrived"
                              ? "Your driver has arrived at the pickup location. Please share the OTP: $tripTrackingOtp"
                              : "Your driver is waiting at the pickup location. Please meet the driver and share the OTP to start the trip.",
                          style: Styles.txtBlackColorW60016.copyWith(
                            fontSize: 14,
                            color: ColorsValue.appColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Dimens.boxHeight12,
              ],

              if (statusLower == "driver arrived") ...[
                // Waiting Timer Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ColorsValue.l4CB,
                    borderRadius: BorderRadius.circular(Dimens.twelve),
                    border: Border.all(color: ColorsValue.borderColors),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: Dimens.edgeInsets20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Waiting Timer",
                        style: Styles.txtG7Colors40014.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (controller.elapsedSeconds <= controller.freeWaitingSeconds) ...[
                        // Free waiting time remaining countdown
                        (() {
                          final remainingSeconds = controller.freeWaitingSeconds - controller.elapsedSeconds;
                          final mins = remainingSeconds ~/ 60;
                          final secs = remainingSeconds % 60;
                          final timeString = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
                          return Column(
                            children: [
                              Text(
                                timeString,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Free waiting time remaining",
                                style: Styles.txtG7Colors40014.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          );
                        }()),
                      ] else ...[
                        // Exceeded waiting time count-up
                        (() {
                          final mins = controller.chargeableSeconds ~/ 60;
                          final secs = controller.chargeableSeconds % 60;
                          final timeString = "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
                          return Column(
                            children: [
                              Text(
                                timeString,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Additional waiting time",
                                style: Styles.txtG7Colors40014.copyWith(
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Waiting Charge: ₹${controller.accumulatedWaitingCharge.toStringAsFixed(2)}",
                                style: Styles.txtBlackColorW60016.copyWith(
                                  color: ColorsValue.appColor,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          );
                        }()),
                      ],
                    ],
                  ),
                ),
                Dimens.boxHeight12,
              ],

              // 🟩 Booking ID + Status
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                ),
                padding: Dimens.edgeInsets20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Booking ID", style: Styles.txtG7Colors40014),
                        Text(bookingId, style: Styles.txtBlackColorW60016),
                      ],
                    ),
                    Dimens.boxWidth8,
                    Flexible(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.fill,
                            image: AssetImage(badgeImage),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            displayStatusText,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: Styles.txtGreenColorW60014.copyWith(
                              color: textColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Dimens.boxHeight12,

              // 🟦 Trip Info
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                ),
                padding: Dimens.edgeInsets20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tripType == "Round Trip") ...[
                      Text(tripType, style: Styles.txtG7Colors40014),
                      Dimens.boxHeight3,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("From", style: Styles.txtG5ColorsW40014.copyWith(fontSize: 11)),
                            Text(from, style: Styles.txtBlackColorW60016.copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ])),
                          Dimens.boxWidth8,
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("To", style: Styles.txtG5ColorsW40014.copyWith(fontSize: 11)),
                            Text(toList.isNotEmpty ? toList.join(" → ") : "—", style: Styles.txtBlackColorW60016.copyWith(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ])),
                        ],
                      ),
                      Dimens.boxHeight12,
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Pickup Date", style: Styles.txtG5ColorsW40014.copyWith(fontSize: 11)),
                            Text(formatDate(date), style: Styles.txtBlackColorW60016.copyWith(fontSize: 13)),
                          ])),
                          if (tripType.toLowerCase().contains("round") || (returnDate.isNotEmpty && returnDate != "null"))
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("Return Date", style: Styles.txtG5ColorsW40014.copyWith(fontSize: 11)),
                              Text(formatDate(returnDate), style: Styles.txtBlackColorW60016.copyWith(fontSize: 13)),
                            ])),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Pickup Time", style: Styles.txtG5ColorsW40014.copyWith(fontSize: 11)),
                            Text(pickupTime, style: Styles.txtBlackColorW60016.copyWith(fontSize: 13)),
                          ])),
                        ],
                      ),
                    ] else ...[
                      Text(tripType, style: Styles.txtG7Colors40014),
                      Text(
                        tripType.toLowerCase().contains("local") ? from : "$from → $toDisplay",
                        style: Styles.txtBlackColorW60016,
                      ),
                      Dimens.boxHeight8,
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: Colors.blue,
                          ),
                          Dimens.boxWidth8,
                          Text(formatDate(date), style: Styles.txtG5ColorsW40014),
                          Dimens.boxWidth24,
                          tripType != "Round Trip"
                              ? SvgPicture.asset(
                                  AssetConstants.ic_clcok,
                                  color: Colors.blue,
                                  height: Dimens.twenty,
                                )
                              : const Icon(
                                  Icons.calendar_month_outlined,
                                  color: Colors.blue,
                                ),
                          Dimens.boxWidth8,
                          Text(pickupTime, style: Styles.txtG5ColorsW40014),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              Dimens.boxHeight15,

              // 🚗 Vehicle Info
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                ),
                padding: Dimens.edgeInsets20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Vehicle", style: Styles.txtG7Colors40014),
                              Text(brandName, style: Styles.txtBlackColorW60016),
                              Text(
                                vehicleName.toString(),
                                style: Styles.txtG7Colors40014,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        if (carPhoto != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(Dimens.eight),
                            child: Image.network(
                              carPhoto,
                              height: 50,
                              width: 90,
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                      ],
                    ),
                    Dimens.boxHeight8,
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: features.map((item) {
                        final rawLogo = item["logo"];
                        final desc = item["feature_description"] ?? item["description"] ?? "";
                        final logo = rawLogo != null
                            ? "${ApiWrapper.imageUrl}$rawLogo"
                            : null;

                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: logo != null
                                  ? Image.network(
                                      logo,
                                      fit: BoxFit.cover,
                                      width: 32,
                                      height: 32,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          AssetConstants
                                              .CarImge, // 🧩 your fallback asset
                                          width: 28,
                                          height: 28,
                                          fit: BoxFit.contain,
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      AssetConstants
                                          .CarImge, // 🧩 fallback if logo is null
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                          label: Text(desc, style: Styles.txtG7Colors40014),
                          backgroundColor: ColorsValue.whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: ColorsValue.borderColors),
                          ),
                        );
                      }).toList(),
                    ),
                    if (showAllocatedVehicleDetails && vehicleNumber != "—" && vehicleNumber.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(height: 1, color: Colors.grey),
                      ),
                      Text(
                        "Vehicle Number: $vehicleNumber",
                        style: Styles.txtBlackColorW60016.copyWith(
                          color: ColorsValue.appColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Fuel Type: $fuelType",
                        style: Styles.txtG7Colors40014.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Model Year: $modelYear",
                        style: Styles.txtG7Colors40014.copyWith(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),

              Dimens.boxHeight16,

              if (includeFacilities.isNotEmpty ||
                  excludeFacilities.isNotEmpty ||
                  vehicleFeatures.isNotEmpty ||
                  termsConditions.trim().isNotEmpty) ...[
                _buildFacilitiesCard(
                  includeFacilities: includeFacilities,
                  excludeFacilities: excludeFacilities,
                  vehicleFeatures: vehicleFeatures,
                  termsConditions: termsConditions,
                ),
                Dimens.boxHeight16,
              ],

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Traveler Details",
                          style: Styles.txtBlackColorW70018,
                        ),
                        if (isEditable)
                          IconButton(
                            icon: Icon(Icons.edit, color: ColorsValue.appColor, size: 20),
                            onPressed: () {
                              _showEditAddressDialog(
                                context,
                                controller,
                                bookingIdforPayment,
                                tripType,
                                pickupAddress,
                                dropAddress,
                                from,
                                toDisplay,
                              );
                            },
                          ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Pickup
                    if (pickupAddress.trim().isNotEmpty && pickupAddress != "—") ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Pickup: $pickupAddress",
                              style: Styles.txtBlackColorW40014,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],

                    // Drop
                    if (dropAddress.trim().isNotEmpty && dropAddress != "—") ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.flag, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Drop: $dropAddress",
                              style: Styles.txtBlackColorW40014,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],

                    Divider(color: ColorsValue.borderColors, height: 1),
                    SizedBox(height: 16),

                    // Traveler info section
                    if (travelerName.trim().isNotEmpty && travelerName != "—") ...[
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: ColorsValue.appColor,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              travelerName,
                              style: Styles.txtBlackColorW60016,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],

                    if (travelerEmail.trim().isNotEmpty && travelerEmail != "—") ...[
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              travelerEmail,
                              style: Styles.txtG7Colors40014,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],

                    if (travelerMobile.trim().isNotEmpty && travelerMobile != "—") ...[
                      Row(
                        children: [
                          Icon(Icons.phone_android, color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              travelerMobile,
                              style: Styles.txtG7Colors40014,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              Dimens.boxHeight12,

              ((statusLower == "d & v allocated" || statusLower == "driver arrived" || statusLower == "ongoing" || statusLower == "completed" || (driverName != "—" || driverMobile != "—")) && (driverName != "—" || driverMobile != "—"))
                  ? Container(
                      decoration: BoxDecoration(
                        color: ColorsValue.l4CB,
                        borderRadius: BorderRadius.circular(Dimens.twelve),
                      ),
                      padding: Dimens.edgeInsets20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Driver Details", style: Styles.txtBlackColorW70018),
                          Dimens.boxHeight12,

                          Row(
                            children: [
                              // Driver Photo
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: driverPhoto != null
                                    ? Image.network(
                                        driverPhoto,
                                        height: 60,
                                        width: 60,
                                        fit: BoxFit.cover,
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                              ),

                              Dimens.boxWidth16,

                              // Driver Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Driver Name
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person,
                                          color: ColorsValue.appColor,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            driverName,
                                            style: Styles.txtBlackColorW60016,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),

                                    // Driver mobile number (normal text)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_android,
                                          color: Colors.teal,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            driverMobile,
                                            style: Styles.txtBlackColorW40014,
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 8),

                                    // Languages Known
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.language,
                                          color: Colors.orange,
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            driverLanguages,
                                            style: Styles.txtG7Colors40014,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // 📞 SEPARATE CALL BUTTON
                              driverMobile != "—"
                                  ? InkWell(
                                      onTap: () async {
                                        final uri = Uri(
                                          scheme: 'tel',
                                          path: driverMobile,
                                        );
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(
                                            0.12,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.call,
                                          color: Colors.orange,
                                          size: 24,
                                        ),
                                      ),
                                    )
                                  : SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),
              Dimens.boxHeight16,

              (tripTrackingOtp != "null" && tripTrackingOtp.isNotEmpty && !statusLower.contains("complete") && !statusLower.contains("cancel") && !statusLower.contains("expire"))
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(0.2),
                                ),
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.orange,
                                  size: 22,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Trip Tracking OTP",
                                style: Styles.txtBlackColorW60016.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          // OTP CODE
                          Center(
                            child: Text(
                              tripTrackingOtp,
                              style: Styles.txtBlackColorW60016.copyWith(
                                fontSize: 32,
                                letterSpacing: 4,
                                color: ColorsValue.appColor,
                              ),
                            ),
                          ),

                          SizedBox(height: 12),

                          // Instruction text
                          Text(
                            "Share this OTP with the driver to start your trip.",
                            style: Styles.txtG7Colors40014.copyWith(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox.shrink(),



              Dimens.boxHeight12,

              // 💰 Fare Summary
              Container(
                decoration: BoxDecoration(
                  color: ColorsValue.l4CB,
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                ),
                padding: Dimens.edgeInsets20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Fare Summary", style: Styles.txtBlackColorW60016),
                    Dimens.boxHeight12,

                    // 1. Base Fare
                    if (effectiveBaseFare > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Base Fare", style: Styles.txtG7Colors40014),
                          Text("₹${formatAmt(effectiveBaseFare)}", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 2. Total Distance
                    if (totalDistanceKm > 0 || controller.isCalculatingDistance) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Distance", style: Styles.txtG7Colors40014),
                          controller.isCalculatingDistance
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text("${formatAmt(totalDistanceKm)} km", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 3. Start Meter / End Meter
                    if (isCompletedTrip && startKm > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Start Meter", style: Styles.txtG7Colors40014),
                          Text("${formatAmt(startKm)} km", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],
                    if (isCompletedTrip && endKm > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("End Meter", style: Styles.txtG7Colors40014),
                          Text("${formatAmt(endKm)} km", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 4. Included KM
                    if (includedKm > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Included KM", style: Styles.txtG7Colors40014),
                          Text("${formatAmt(includedKm)} km", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 5. Extra KM
                    if (extraKm > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Extra KM", style: Styles.txtG7Colors40014),
                          Text("${formatAmt(extraKm)} km", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 6. Per KM Rate
                    if (perKmPrice > 0 && extraKm > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Per KM Rate", style: Styles.txtG7Colors40014),
                          Text("₹${formatAmt(perKmPrice)}/km", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 7. Extra KM Charges
                    if (extraKmCharge > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Extra KM Charges", style: Styles.txtG7Colors40014),
                          Text("₹${formatAmt(extraKmCharge)}", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 8. Special Services
                    if (specialServicesPrice > 0 || services.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Special Services", style: Styles.txtG7Colors40014.copyWith(fontWeight: FontWeight.w600)),
                          Text("₹${formatAmt(specialServicesPrice)}", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight6,
                      for (var s in services) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("   ➔ ${s["description"] ?? "Service"}", style: Styles.txtG7Colors40014.copyWith(fontSize: 13, color: Colors.grey[600])),
                            Text("₹${s["amount"] ?? 0}", style: Styles.txtBlackColorW40014.copyWith(fontSize: 13, color: Colors.grey[600])),
                          ],
                        ),
                        Dimens.boxHeight6,
                      ],
                      Dimens.boxHeight4,
                    ],

                    // 9. Coupon Discount
                    if (effectiveDiscount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            couponCode.isNotEmpty ? "Coupon Discount ($couponCode)" : "Coupon Discount",
                            style: Styles.txtG7Colors40014.copyWith(color: Colors.green),
                          ),
                          Text("- ₹${formatAmt(effectiveDiscount)}", style: Styles.txtBlackColorW60016.copyWith(color: Colors.green)),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 10. Waiting Charges
                    if (effectiveWaitingCharge > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusLower == "driver arrived"
                                ? "Waiting Charges (Live)"
                                : (displayWaitingMins > 0 ? "Waiting Charges ($displayWaitingMins min)" : "Waiting Charges"),
                            style: Styles.txtG7Colors40014.copyWith(color: Colors.red[700]),
                          ),
                          Text("₹${formatAmt(effectiveWaitingCharge)}", style: Styles.txtBlackColorW60016.copyWith(color: Colors.red[700])),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 11. Total Fare (Before Tax) with dashed border above
                    if (effectiveGstAmount > 0 && totalFareBeforeTax > 0) ...[
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final boxWidth = constraints.constrainWidth();
                          const dashWidth = 5.0;
                          const dashSpace = 4.0;
                          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Flex(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              direction: Axis.horizontal,
                              children: List.generate(dashCount, (_) {
                                return const SizedBox(
                                  width: dashWidth,
                                  height: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(color: Color(0xFFBDBDBD)),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total Fare (Before Tax)", style: Styles.txtBlackColorW60016),
                          Text(
                            "₹${formatAmt(totalFareBeforeTax)}",
                            style: Styles.txtBlackColorW60016.copyWith(
                              color: ColorsValue.appColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 12. GST
                    if (effectiveGstAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("GST (${effectiveGstPercent.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%)", style: Styles.txtG7Colors40014),
                          Text("₹${formatAmt(effectiveGstAmount)}", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    // 13. Additional Charges (AFTER GST, exactly matching Website)
                    if (additionalChargesList.isNotEmpty) ...[
                      for (final ch in additionalChargesList)
                        if (ch is Map && ch['amount'] != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(ch['title']?.toString() ?? "Additional Charge", style: Styles.txtG7Colors40014),
                              Text("₹${formatAmt(double.tryParse(ch['amount'].toString()) ?? 0.0)}", style: Styles.txtBlackColorW60016),
                            ],
                          ),
                          Dimens.boxHeight10,
                        ],
                    ] else if (additionalChargesTotal > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Additional Charges", style: Styles.txtG7Colors40014),
                          Text("₹${formatAmt(additionalChargesTotal)}", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                      Dimens.boxHeight10,
                    ],

                    Divider(color: ColorsValue.borderColors),

                    // 14. Total Fare (After Tax)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          effectiveGstAmount > 0 ? "Total Fare (After Tax)" : "Total Fare",
                          style: Styles.txtBlackColorW60016,
                        ),
                        Text(
                          "₹${formatAmt(calculatedTotalPayment)}",
                          style: Styles.txtBlackColorW60016.copyWith(
                            color: ColorsValue.appColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Dimens.boxHeight10,

                    // 15. Payment Mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Payment Mode", style: Styles.txtG7Colors40014),
                        Text(paymentMode, style: Styles.txtBlackColorW60016),
                      ],
                    ),
                    Dimens.boxHeight10,

                    // 16. Paid Amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Paid Amount", style: Styles.txtG7Colors40014),
                        Text("₹${formatAmt(paidAmountVal)}", style: Styles.txtBlackColorW60016),
                      ],
                    ),

                    // 17. Pending Payment (if any)
                    if (displayPendingPaymentVal > 0) ...[
                      Dimens.boxHeight10,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Pending Payment", style: Styles.txtG7Colors40014),
                          Text("₹${formatAmt(displayPendingPaymentVal)}", style: Styles.txtBlackColorW60016),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              if (livePendingAmountForPay > 0 && !statusLower.contains("cancel") && !statusLower.contains("expire")) ...[
                Dimens.boxHeight16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsValue.appColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      controller.payFullPayment(
                        bookingId: bookingIdforPayment,
                        amount: livePendingAmountForPay, // ✅ int
                      );
                    },
                    child: Text(
                      "Pay Full Payment ₹$livePendingAmountForPay",
                      style: Styles.whiteColorW60016,
                    ),
                  ),
                ),
              ],
              Dimens.boxHeight30,
              _buildFooterButton(context, controller, bookingStatus, isReview),
              Dimens.boxHeight20,

              // 🎯 Footer Buttons (based on status)
            ],
            ),
          ),
        );
      },
    );
  }

  // 🎯 Footer Buttons (based on booking_status)
  Widget _buildFooterButton(
    BuildContext context,
    BookingHistoryController controller,
    String bookingStatus,
    bool isReview,
  ) {
    switch (bookingStatus.toLowerCase()) {
      case 'confirmed':
        return CustomButton(
          onPressed: () => controller.showBokigCancelDelog(context),
          text: "Cancel Booking",
          isColor: true,
          backgroundColor: ColorsValue.txtRedColor,
          textStyle: Styles.whiteColorW60016,
        );

      case 'completed':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            !isReview
                ? reviewCard(
                    comment:
                        controller.bookingDetails!["review"]["comments"] ?? "",
                    rating: getDouble(
                      controller.bookingDetails!["review"]["overall_rating"],
                    ),
                  )
                : const SizedBox.shrink(),
            Dimens.boxHeight20,
            InkWell(
              onTap: () async {
                await downloadInvoice(context, controller.bookingDetails!);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimens.twelve),
                  border: Border.all(color: ColorsValue.borderColors),
                ),
                padding: Dimens.edgeInsets11,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(AssetConstants.ic_invice),
                    Dimens.boxWidth8,
                    Text("Download Invoice", style: Styles.txtBlackColorW40014),
                  ],
                ),
              ),
            ),
            Dimens.boxHeight16,
            CustomButton(
              onPressed: () => controller.showReviewDialog(context, isReview),
              text: isReview ? "Write Review" : "Update Review",
              isColor: true,
              backgroundColor: ColorsValue.appColor,
              textStyle: Styles.txtBlackColorW40014,
            ),
          ],
        );

      // case 'cancelled':
      //   return CustomButton(
      //     onPressed: () {
      //       // Rebook action
      //     },
      //     text: "Book Again",
      //     isColor: true,
      //     backgroundColor: ColorsValue.appColor,
      //     textStyle: Styles.txtBlackColorW40014,
      //   );

      default:
        return const SizedBox.shrink(); // No button for unknown status
    }
  }

  Widget reviewCard({required String comment, required double rating}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review Text
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),

          //const SizedBox(height: 18),

          // Rating Label (like Excellent)
          Text(
            getRatingLabel(rating),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 10),

          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.orange,
                size: 24,
              );
            }),
          ),
        ],
      ),
    );
  }

  String getRatingLabel(double rating) {
    if (rating >= 4.5) return "Excellent";
    if (rating >= 3.5) return "Good";
    if (rating >= 2.5) return "Neutral";
    if (rating >= 1.5) return "Poor";
    return "Bad";
  }

  double getDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is int) return v.toDouble();
    if (v is double) return v;
    return double.tryParse(v.toString()) ?? 0.0;
  }

  Future<String> loadInvoiceHtml(
    String fileName,
    Map<String, dynamic> booking,
  ) async {
    String html = await rootBundle.loadString("assets/invoice/$fileName");

    final travel = booking["travelDetails"];
    String formatDate(String apiDate) {
      try {
        final parsed = DateTime.parse(apiDate); // e.g. 2025-11-25
        return DateFormat('dd-MM-yyyy').format(parsed); // → 25-11-2025
      } catch (_) {
        return apiDate; // fallback if parse fails
      }
    }

    Map<String, dynamic> values = {
      "customer_name": travel["traveler_name"] ?? "",
      "customer_email": travel["traveler_email"] ?? "",
      "customer_mobile": travel["traveler_mobile"] ?? "",
      "booking_id": booking["booking_id"] ?? "",
      "invoice_id": "INV-${booking["booking_id"]}",
      "invoice_date": formatDate(booking["createdAt"]),
      "trip_type": travel["trip_type"] ?? "",
      "pickup_address": travel["pickup_address"] ?? "",
      "drop_address": (travel["drop_address"] as List).join(", "),
      "trip_datetime": "${formatDate(travel["date"])} ${travel["pickup_time"]}",
      "base_fare": (double.tryParse(travel["fare_summary"]["base_fare"]?.toString() ?? '0') ?? 0).toStringAsFixed(0),
      "special_services": travel["total_service_price"].toString(),
      "cgst": ((travel["fare_summary"]["gst_amount"] ?? travel["fare_summary"]["gst_included"] ?? 0) / 2).toString(),
      "sgst": ((travel["fare_summary"]["gst_amount"] ?? travel["fare_summary"]["gst_included"] ?? 0) / 2).toString(),
      "total_amount": travel["final_price"].toString(),
    };

    // ---------- ADD THESE ----------
    double specialAmount =
        double.tryParse(values["special_services"] ?? "0") ?? 0;

    String specialServicesRow = "";
    if (specialAmount > 0) {
      specialServicesRow =
          """
    <tr>
      <td style="font-size: 14px; padding: 8px 10px; display:flex; justify-content:space-between;">
        <span>Special Services :</span>
        <span style="font-weight:600;">₹$specialAmount</span>
      </td>
    </tr>
    """;
    }

    double offerDiscount = 0;

    try {
      offerDiscount = (travel["offer_discount"] ?? 0).toDouble();
    } catch (_) {
      offerDiscount = 0;
    }

    String offerRow = "";

    if (offerDiscount >= 0) {
      offerRow =
          """
  <tr>
    <td style="font-size: 14px; padding:8px 10px; display:flex; justify-content:space-between; color:green;">
      <span>Offer Discount :</span>
      <span style="font-weight:600;">-₹${offerDiscount.toStringAsFixed(0)}</span>
    </td>
  </tr>
  """;
    }
    double pendingPayment = 0;

    try {
      pendingPayment = (travel["pending_payment"] ?? 0).toDouble();
    } catch (_) {
      pendingPayment = 0;
    }
    String pendingRow = "";

    if (pendingPayment >= 0) {
      pendingRow =
          '<tr><td style="font-size:14px;padding:8px 10px;display:flex;justify-content:space-between;color:#E67E22;">'
          '<span>Pending Payment :</span>'
          '<span style="font-weight:600;">₹${pendingPayment.toStringAsFixed(0)}</span>'
          '</td></tr>';
    }
    values["pending_row"] = pendingRow;

    values["offer_row"] = offerRow;

    values["special_services_row"] = specialServicesRow;

    // -------------------------------

    // Images
    values["logo"] = await assetToBase64("assets/images/logo.png");
    values["bg"] = await assetToBase64("assets/images/bg.png");

    // Replace placeholders
    values.forEach((key, value) {
      html = html.replaceAll("{{${key}}}", value.toString());
    });

    return html;
  }

  Future<Uint8List> generateInvoicePdf(String htmlContent) async {
    return await Printing.convertHtml(html: htmlContent);
  }

  Future<Uint8List> _loadAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }

  Future<void> generateAndOpenInvoicePdf(Map<String, dynamic> booking) async {
    final pw.Document doc = pw.Document();

    // Load images as bytes
    Uint8List logoBytes = await _loadAsset('assets/images/logo.png');
    Uint8List bgBytes = await _loadAsset('assets/images/bg.png'); // optional

    // Create pdf images
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);
    final pw.ImageProvider bgImage = pw.MemoryImage(bgBytes);

    // Read values safely
    final customerName = booking['customerName'] ?? '';
    final bookingId = booking['_id'] ?? '';
    final invoiceId = booking['invoiceId'] ?? '';
    final invoiceDate = booking['invoiceDate'] ?? '';
    final mobile = booking['customerMobile'] ?? '';
    final email = booking['customerEmail'] ?? '';

    final rawBaseFare = double.tryParse(booking['amount']?['baseFare']?.toString() ?? '0') ?? 0.0;
    final displayInvoiceBaseFare = rawBaseFare.toStringAsFixed(0);
    final baseFare = displayInvoiceBaseFare;
    final cgst = booking['amount']?['cgst']?.toString() ?? '0';
    final sgst = booking['amount']?['sgst']?.toString() ?? '0';
    final total = booking['amount']?['total']?.toString() ?? '0';
    final waitingCharge = double.tryParse((booking['waiting_charge'] ?? 0).toString()) ?? 0.0;

    // Add a page (you can add multiple)
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Optional background image (low opacity)
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Opacity(
                  opacity: 0.08,
                  child: pw.Image(bgImage, width: PdfPageFormat.a4.width),
                ),
              ),

              // Main content
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header row: logo + company info
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 160,
                        child: pw.Image(logoImage, width: 140),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Bambam Cab booking',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              '3rd Floor, Shree Complex, Ashram Road, Ahmedabad - 380009',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Mobile: +91 98765 43210 | GST: 29XAQCS9916CIZT',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 16),

                  // Big Invoice title centered
                  pw.Center(
                    child: pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Divider(),

                  pw.SizedBox(height: 8),

                  // Customer & invoice details in table-like rows
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Customer Name: ${customerName}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              'Email: ${email}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              'Mobile: ${mobile}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Container(
                        width: 200,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Booking ID: ${bookingId}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              'Invoice ID: ${invoiceId}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                            pw.Text(
                              'Invoice Date: ${invoiceDate}',
                              style: pw.TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 18),

                  // Amount box (right aligned)
                  pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      children: [
                        _amountRow('Base Fare', '₹$baseFare'),
                        if (waitingCharge > 0)
                          _amountRow('Waiting Charges', '₹${waitingCharge.toStringAsFixed(0)}'),
                        _amountRow('CGST', '₹$cgst'),
                        _amountRow('SGST', '₹$sgst'),
                        pw.Divider(),
                        _amountRow(
                          'Total Amount Paid',
                          '₹$total',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  pw.Spacer(),

                  // Terms
                  pw.Text(
                    'Terms & Conditions',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Bullet(
                    text:
                        'The cost includes driver allowance, fuel charge and service tax.',
                  ),
                  pw.Bullet(
                    text:
                        'Charges for additional kms over the specified limit will be paid directly to the driver.',
                  ),
                  pw.SizedBox(height: 20),

                  // Footer / signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Please retain this invoice for future reference.',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Column(
                        children: [
                          pw.Text(
                            'For Bambam Cab booking',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                          pw.SizedBox(height: 30),
                          pw.Text(
                            'Authorized Sign',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save
    final Uint8List pdfData = await doc.save();

    // Save to filesystem and open
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/invoice_${bookingId}.pdf");
    await file.writeAsBytes(pdfData);

    await OpenFilex.open(file.path);
  }

  // helper for amount row
  pw.Widget _amountRow(String label, String value, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> assetToBase64(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final base64 = base64Encode(bytes.buffer.asUint8List());
    final ext = assetPath.split(".").last.toLowerCase();
    final mime = (ext == "jpg" || ext == "jpeg") ? "image/jpeg" : "image/png";
    return "data:$mime;base64,$base64";
  }

  Future<String> loadInvoiceHtmlWithAssets(
    String fileName,
    Map<String, dynamic> data,
  ) async {
    String html = await rootBundle.loadString("assets/invoice/$fileName");

    // Convert images to Base64
    String logo = await assetToBase64("assets/images/logo.png");
    String bg = await assetToBase64("assets/images/bg.png");

    data["logo"] = logo;
    data["bg"] = bg;

    // Replace placeholders
    data.forEach((key, value) {
      html = html.replaceAll("{{$key}}", value.toString());
    });

    return html;
  }

  Future<void> downloadInvoice(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final html = await loadInvoiceHtml("OneWay.html", booking);

    final converter = FlutterNativeHtmlToPdf();
    final pdf = await converter.convertHtmlToPdf(
      html: html,
      targetDirectory: (await getApplicationDocumentsDirectory()).path,
      targetName: "invoice_${booking["booking_id"]}",
    );

    if (pdf != null) {
      OpenFilex.open(pdf.path);
    } else {
      Utility.showMessage(
        "Failed to generate PDF",
        MessageType.error,
        null,
        "OK",
      );
    }
  }

  void _showEditAddressDialog(
    BuildContext context,
    BookingHistoryController controller,
    String bookingId,
    String tripType,
    String currentPickup,
    String currentDrop,
    String pickupCity,
    String dropCity,
  ) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController pickupController = TextEditingController(
      text: currentPickup == "—" ? "" : currentPickup,
    );
    final TextEditingController dropController = TextEditingController(
      text: currentDrop == "—" ? "" : currentDrop,
    );
    final bool isLocalRental = tripType == "Local Rental Trip";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.twenty),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Container(
                padding: Dimens.edgeInsets20,
                width: Get.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimens.twenty),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: () => Get.back(),
                        child: SvgPicture.asset(
                          AssetConstants.ic_cancel,
                          height: Dimens.twentyFive,
                        ),
                      ),
                    ),

                    Dimens.boxHeight10,
                    Text(
                      "Edit Booking Address",
                      style: Styles.txtBlackColorW70020,
                      textAlign: TextAlign.center,
                    ),
                    Dimens.boxHeight24,

                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceSearchPage(
                              city: pickupCity,
                              isPickup: true,
                              apiKey: StringConstants.gpooglePlaceKey,
                            ),
                          ),
                        );
                        if (result != null) {
                          pickupController.text = result["display_name"];
                        }
                      },
                      child: AbsorbPointer(
                        child: CustomTextFormField(
                          style: Styles.txtBlackColorW40014,
                          hintText: "Search pickup address",
                          isBorder: true,
                          isTitle: true,
                          textEditingController: pickupController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? "Pickup address is required" : null,
                          isCompulsory: true,
                          title: "Pickup Address",
                          maxLines: 2,
                          hintStyle: Styles.txtG7Colors40014,
                          titleStyle: Styles.black50014,
                        ),
                      ),
                    ),

                    if (!isLocalRental) ...[
                      Dimens.boxHeight20,
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceSearchPage(
                                city: dropCity,
                                isPickup: false,
                                apiKey: StringConstants.gpooglePlaceKey,
                              ),
                            ),
                          );
                          if (result != null) {
                            dropController.text = result["display_name"];
                          }
                        },
                        child: AbsorbPointer(
                          child: CustomTextFormField(
                            style: Styles.txtBlackColorW40014,
                            hintText: "Search drop address",
                            isBorder: true,
                            isTitle: true,
                            textEditingController: dropController,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty) ? "Drop address is required" : null,
                            isCompulsory: true,
                            title: "Drop Address",
                            maxLines: 2,
                            hintStyle: Styles.txtG7Colors40014,
                            titleStyle: Styles.black50014,
                          ),
                        ),
                      ),
                    ],

                    Dimens.boxHeight30,

                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          Get.back();
                          final success = await controller.updateBookingAddress(
                            bookingId: bookingId,
                            pickupAddress: pickupController.text.trim(),
                            dropAddress: isLocalRental ? null : dropController.text.trim(),
                          );
                          if (success) {
                            await controller.fetchBookingDetails(bookingId);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsValue.appColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimens.twenty),
                        ),
                      ),
                      child: Padding(
                        padding: Dimens.edgeInsets24_10_24_10,
                        child: Text(
                          "Update Address",
                          style: Styles.txtBlackColorW40014.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    Dimens.boxHeight24,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
