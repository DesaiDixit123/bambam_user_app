import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';
import 'package:bam_bam_user/app/utils/airports_list.dart';
import 'package:bam_bam_user/app/utils/citys_list.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:bam_bam_user/app/widgets/custom_time_picker.dart';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentOption {
  final String id;
  final String name;
  final int advancePercentage;
  final List<String> applicableOn;
  final bool status;

  PaymentOption({
    required this.id,
    required this.name,
    required this.advancePercentage,
    required this.applicableOn,
    required this.status,
  });

  factory PaymentOption.fromJson(Map<String, dynamic> json) {
    return PaymentOption(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['payment_name'] ?? '').toString(),
      advancePercentage: (json['advance_payment_percentage'] is num)
          ? (json['advance_payment_percentage'] as num).toInt()
          : int.tryParse(
                  (json['advance_payment_percentage'] ?? '0').toString(),
                ) ??
                0,
      applicableOn: (json['applicable_on'] is List)
          ? List<String>.from(json['applicable_on'].map((e) => e.toString()))
          : <String>[],
      status: (json['status'] == true),
    );
  }
}

class HomeController extends GetxController {
  HomeController(this.homePresenter);
  final HomePresenter homePresenter;

  final isBookingForAnother = false.obs;

  // add these controller fields
  late Razorpay _razorpay;
  bool isProcessingBooking = false; // shows spinner while API call active
  bool bookingProcessed = false; // true after createBooking success
  Map<String, dynamic>? bookingResponse; // store booking result

  bool hasGst = false; // existing toggle
  TextEditingController companyNameController = TextEditingController();
  TextEditingController gstNoController = TextEditingController();
  ScrollController? scrollController; // already present
  var datta;
  // computed amounts
  double get advanceAmount => ((selectedAdvancePercent / 100.0) * totalFare);
  double get laterAmount => (totalFare - advanceAmount);
  List<String> cityList = []; // fill from your source
  String selectedCity = '';

  // UX flags
  bool isFetchingLocation = false;
  // init razorpay in onInit
  int selectedRentalIndex = 0;
  List<Map<String, dynamic>> rentalBlocks = [];
  bool isRefreshingRentalPrice = false;

  void selectRentalPackage(int index) {
    if (index >= 0 && index < rentalBlocks.length) {
      selectedRentalIndex = index;
      update();
    }
  }

  double? getLocalRentalPrice(String vehicleTypeId) {
    if (rentalBlocks.isEmpty || selectedRentalIndex >= rentalBlocks.length) return null;
    final selectedBlock = rentalBlocks[selectedRentalIndex];
    final selectedHours = selectedBlock['hours']?.toString();
    final selectedKm = selectedBlock['km']?.toString();

    // 1. Check if backend provided final_price_local_trip matching this block
    final List localPrices = datta?['final_price_local_trip'] as List? ?? [];
    final matched = localPrices.firstWhereOrNull(
      (e) =>
          (e['vehicle_type_id']?.toString() == vehicleTypeId ||
           e['vehicleId']?.toString() == vehicleTypeId ||
           e['vehicle_type']?.toString() == vehicleTypeId) &&
          e['selected_hours']?.toString() == selectedHours &&
          e['selected_km']?.toString() == selectedKm,
    );
    if (matched != null && matched['selected_price'] != null) {
      final p = (matched['selected_price'] as num).toDouble();
      if (p > 0) return p;
    }

    // 2. Dynamically look up in exploreTrips[0]['vehicle_pricing']
    if (exploreTrips.isNotEmpty) {
      final trip = exploreTrips[0];
      final vehiclePricing = trip['vehicle_pricing'] as List? ?? [];
      final matchedVp = vehiclePricing.firstWhereOrNull(
        (vp) =>
            vp['vehicle_type_id']?.toString() == vehicleTypeId ||
            vp['vehicleId']?.toString() == vehicleTypeId ||
            vp['vehicle_type']?.toString() == vehicleTypeId,
      );
      if (matchedVp != null) {
        final blocks = matchedVp['pricing_blocks'] as List? ?? [];
        final matchedBlock = blocks.firstWhereOrNull(
          (b) =>
              b['hours']?.toString() == selectedHours &&
              b['km']?.toString() == selectedKm &&
              b['set_hour_price'] == true,
        );
        if (matchedBlock != null && matchedBlock['price'] != null) {
          final p = (matchedBlock['price'] as num).toDouble();
          if (p > 0) return p;
        }
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadPopularRoutes();
    final now = DateTime.now();
    final oneHourLater = now.add(const Duration(hours: 1));

    // default date
    fromDateController.text = DateFormat('dd-MM-yyyy').format(now);

    // default time (+1 hour)
    toDateController.text = DateFormat('hh:mm a').format(oneHourLater);
    initController();
    fetchPaymentOptions();
    AirportsList.fetchAirports();

    _initRazorpay();
  }

  void initController() {
    scrollController ??= ScrollController();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  // helper: safely dispose controllers in a list
  void _disposeControllersList(List<TextEditingController> list) {
    for (final c in list) {
      try {
        c.dispose();
      } catch (_) {}
    }
  }

  /// Call this from UI when user taps the tab
  void setTripMode(int mode) {
    // If same mode, ignore
    if (tripMode == mode) return;

    // Dispose/clear old per-mode inputs appropriately
    // We will clear dates/times and reset destination inputs when mode changes
    tripMode = mode;

    // Do NOT clear dates/times! Preserve them if already set, otherwise set defaults
    if (fromDateController.text.isEmpty) {
      final now = DateTime.now();
      fromDateController.text = DateFormat('dd-MM-yyyy').format(now);
    }
    if (toDateController.text.isEmpty) {
      final now = DateTime.now();
      final oneHourLater = now.add(const Duration(hours: 1));
      toDateController.text = DateFormat('hh:mm a').format(oneHourLater);
    }

    // Clear any previously selected offer/services if you want:
    // selectedOffer = null;
    // selectedServiceIds.clear();

    if (mode == 0) {
      // Oneway: ensure single 'to' input
      // dispose all multi toControllers and replace with a single toController
      _disposeControllersList(toControllers);
      toControllers = [TextEditingController()];
      toController.clear();
      // If you also keep separate time controller for one-way, clear it too (if exists)
      // timeController.clear();
    } else if (mode == 1) {
      // RoundTrip: ensure we have at least one destination input and allow multiple
      if (toControllers.isEmpty) {
        toControllers = [TextEditingController()];
      } else {
        // Reset text on existing controllers
        for (final tc in toControllers) {
          tc.clear();
        }
      }
      // clear single toController used by one-way
      toController.clear();
    } else if (mode == 2) {
      // LocalRental: city only — remove round-trip to inputs and clear one-way to
      _disposeControllersList(toControllers);
      toControllers = [
        TextEditingController(),
      ]; // keep a single empty so UI code has a controller
      toController.clear();

      // 🔥 IMPORTANT FIX
      formController.clear(); // remove old "From"
      // remove old "To"
      // fresh city input
    } else if (mode == 3) {
      // Airport: similar to OneWay but simpler UI for from/to
      _disposeControllersList(toControllers);
      toControllers = [TextEditingController()];
      toController.clear();
      formController.clear();
    }

    // If Round Trip (mode == 1), auto set default return date and pickup time
    if (mode == 1) {
      if (returnDateController.text.isEmpty) {
        try {
          final pickupDate = DateFormat(
            'dd-MM-yyyy',
          ).parse(fromDateController.text);
          final returnDate = pickupDate.add(const Duration(days: 1));
          returnDateController.text = DateFormat(
            'dd-MM-yyyy',
          ).format(returnDate);
        } catch (_) {
          final returnDate = DateTime.now().add(const Duration(days: 1));
          returnDateController.text = DateFormat(
            'dd-MM-yyyy',
          ).format(returnDate);
        }
      }
      if (pickupTimeRtController.text.isEmpty) {
        pickupTimeRtController.text = toDateController.text;
      }
    }

    // If you hold selectedExploreCab / selectedVehicle that are specific to a trip mode,
    // you may want to reset them as well so UI fetch flows start fresh:
    // selectedExploreCab = null;
    // selectedVehicle = null;

    update();
  }

  /// call when adding/removing a round-trip destination
  void addNewTo() {
    toControllers.add(TextEditingController());
    update();
  }

  void removeToAt(int index) {
    if (index < 0 || index >= toControllers.length) return;
    final c = toControllers.removeAt(index);
    try {
      c.dispose();
    } catch (_) {}
    // ensure at least one controller remains
    if (toControllers.isEmpty) toControllers.add(TextEditingController());
    update();
  }

  List<String> popularRoutes = [];
  bool isLoadingRoutes = false;

  Future<void> loadPopularRoutes() async {
    try {
      isLoadingRoutes = true;
      update();

      final api = ApiWrapper();
      final headers = Utility.commonHeader(isDefaultAuthorizationKeyAdd: false);

      final res = await api.makeRequest(
        'https://apis.bambamcabs.com/vendor/trips/get-footer-popular-route',
        Request.getApiWithoutBaseURL,
        null,
        false,
        headers,
      );

      if (!res.hasError) {
        final decoded = jsonDecode(res.data);
        popularRoutes = List<String>.from(decoded["Data"] ?? []);
        popularRoutesDetailed = popularRoutes.map((routeStr) {
          final parts = routeStr.split("→");
          if (parts.length == 2) {
            return {
              "from": parts[0].trim(),
              "to": parts[1].trim(),
              "trip_type": "Oneway",
            };
          }
          return {"from": routeStr, "to": "", "trip_type": "Oneway"};
        }).toList();
      } else {
        popularRoutes = [];
        popularRoutesDetailed = [];
      }
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      popularRoutes = [];
      popularRoutesDetailed = [];
      debugPrint("Popular route error: $e");
    }

    isLoadingRoutes = false;
    update();
  }

  void onPopularRouteSelected(dynamic route) {
    try {
      if (route is String) {
        final parts = route.split("→");
        if (parts.length == 2) {
          final from = parts[0].trim();
          final to = parts[1].trim();
          formController.text = from;
          toController.text = to;
          toControllers = [TextEditingController(text: to)];
          tripMode = 0;
          update();
          RouteManagement.gotoSerchScreen();
        }
      } else if (route is Map) {
        formController.text = route["from"]?.toString() ?? "";
        toController.text = route["to"]?.toString() ?? "";
        toControllers = [
          TextEditingController(text: route["to"]?.toString() ?? ""),
        ];
        final type = route["trip_type"]?.toString() ?? "Oneway";
        if (type == "Round Trip")
          tripMode = 1;
        else if (type == "Local Rental Trip")
          tripMode = 2;
        else if (type == "Airport")
          tripMode = 3;
        else
          tripMode = 0;
        update();
        RouteManagement.gotoSerchScreen();
      }
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      debugPrint("Error parsing popular route: $e");
    }
  }

  // Controller fields
  List<PaymentOption> paymentOptions = [];
  String? selectedPaymentId; // store the _id of chosen payment option
  int selectedAdvancePercent =
      0; // legacy numeric percent (keeps existing logic)
  bool isLoadingPaymentOptions = false;

  // Call this in init or before showing payment UI
  Future<void> fetchPaymentOptions() async {
    isLoadingPaymentOptions = true;
    update();

    try {
      // Assumes homePresenter.getPaymentTypes() returns ResponseModel with response.data as raw JSON string
      final res = await homePresenter.getPaymentTypes(showLoader: false);
      isLoadingPaymentOptions = false;
      print("GET-USER-PAYMENT-TYPE DATA: ${res.data}");
      if (res.hasError) {
        print('DEBUG: API Error. res.data = ${res.data}');
        // try parse friendly message
        try {
          final body = jsonDecode(res.data ?? '{}');
          final msg =
              body['Message'] ??
              body['message'] ??
              'Failed to load payment options';
          Utility.showMessage(msg.toString(), MessageType.error, null, 'OK');
        } catch (_) {
          Utility.showMessage(
            'Failed to load payment options',
            MessageType.error,
            null,
            'OK',
          );
        }
        update();
        return;
      }

      final jsonBody = jsonDecode(res.data ?? '{}');
      if (jsonBody is Map && jsonBody.containsKey('Data')) {
        final data = jsonBody['Data'];

        final List payments = (data is Map && data['payments'] is List)
            ? data['payments']
            : [];

        paymentOptions = payments
            .map((e) => PaymentOption.fromJson(Map<String, dynamic>.from(e)))
            .where((e) => e.status == true) // optional: only active ones
            .toList();

        if (paymentOptions.isNotEmpty) {
          selectedPaymentId = paymentOptions.first.id;
          selectedAdvancePercent = paymentOptions.first.advancePercentage;
        }
      } else {
        paymentOptions = [];
      }
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      isLoadingPaymentOptions = false;
      paymentOptions = [];
      Utility.showMessage(
        'Failed to load payment options: $e',
        MessageType.error,
        null,
        'OK',
      );
    } finally {
      update();
    }
  }

  Future<void> _createBookingAfterPayment({
    required String paymentMode, // "Online" or "Offline"
    required int paymentType, // 0 or 1
    required String paymentId,
    Map<String, dynamic>? razorpayPayment,
  }) async {
    final tripType = (selectedExploreCab?['trip_type'] ?? 'Oneway').toString();
    final from = (selectedExploreCab?['from'] ?? formController.text)
        .toString();

    // Build a safe toList: drop nulls and convert to strings
    final dynamic toValue = selectedExploreCab?['to'];
    List<String> toList = [];
    if (toValue is List) {
      toList = toValue.whereType<String>().map((s) => s.toString()).toList();
    } else if (toValue != null) {
      toList = [toValue.toString()];
    } else if (toController.text.trim().isNotEmpty) {
      toList = [toController.text.trim()];
    }

    // date for API (yyyy-MM-dd)
    String dateForApi = '';
    try {
      final pd =
          selectedExploreCab?['pickup_date']?.toString() ??
          controllerDateForApi();
      if (pd.isNotEmpty) {
        final dt = DateTime.parse(pd);
        dateForApi =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      dateForApi = controllerDateForApi();
    }

    // Map special services into objects expected by backend (if backend expects {service_id: id})
    final List<Map<String, dynamic>> specialServicesPayload = selectedServiceIds
        .map((id) => {"service_id": id})
        .toList();

    // Get city fallback: prefer explicit city field, else use from
    final city =
        (selectedExploreCab?['city'] ??
                selectedExploreCab?['from'] ??
                selectedExploreCab?['pickup_city'] ??
                '')
            .toString();

    double? airportCalculatedPrice;
    double? airportDistanceKm;
    if (tripType == 'Airport' && airportSlabPrice != null) {
      final List slabResults = airportSlabPrice!['slab_results'] as List? ?? [];
      final vObj = selectedVehicle;
      final vtVal = vObj != null ? vObj['vehicle_type'] : null;
      final vTypeId = vtVal is Map ? vtVal['_id']?.toString() : vtVal?.toString();
      final vId = vObj != null ? vObj['_id']?.toString() : null;
      final matchedSlab = slabResults.firstWhere(
        (r) {
          final rVid = r['vehicleId']?.toString();
          return rVid != null && (rVid == vTypeId || rVid == vId);
        },
        orElse: () => null,
      );
      if (matchedSlab != null) {
        final p = matchedSlab['slab_price'] ?? matchedSlab['price'];
        airportCalculatedPrice = (p is num) ? p.toDouble() : null;
      }
      airportDistanceKm = (airportSlabPrice!['distance_km'] is num)
          ? (airportSlabPrice!['distance_km'] as num).toDouble()
          : null;
    }

    // Build body. For safety send "to" as array (Round Trip expects array),
    // for Oneway we still provide array (API examples sometimes use string; adjust if your API requires string for oneway).
    final Map<String, dynamic> body = {
      "trip_type": tripType,
      "from": from,
      // Use array for "to" to match Round Trip expectation
      "to": toList,
      "city": city,
      "date": dateForApi,
      "pickup_time":
          selectedExploreCab?['pickup_time'] ?? toDateController.text,
      "vehicleId": selectedVehicle?['_id'] ?? '',
      "pickup_address": pickupController.text.trim(),
      // If API expects drop_address array for round trip, send `toList` else send first
      "drop_address": dropController.text.trim(),
      "traveler_name": nameController.text.trim(),
      "traveler_email": emailController.text.trim(),
      "traveler_mobile": mobileNumberController.text.trim(),
      "special_services": specialServicesPayload,
      "offers_id": selectedOffer?['_id'] ?? null,
      "company_name": hasGst ? companyNameController.text.trim() : null,
      "gst_no": hasGst ? gstNoController.text.trim() : null,
      "payment_mode": paymentMode,
      "is_gst": hasGst ? 1 : 0,
      "payment_percent": selectedPaymentId ?? selectedAdvancePercent.toString(),
      // travelDetailsId should be the id returned from explore/process booking step.
      // Use bookingResponse if available and contains an _id; otherwise omit.
      "travelDetailsId":
          (bookingResponse != null &&
              bookingResponse?['travel_details']['_id'] != null)
          ? bookingResponse!['travel_details']['_id']
          : null,
      "payment_type": paymentType, // 0 or 1
      "payment_id": paymentId.isNotEmpty ? paymentId : null,
      "sub_total_payment": (paymentType == 1) ? advanceAmount.toInt() : 0,
      // "pending_payment": (totalFare - advanceAmount).toInt(),
      "total_payment": totalFare.toInt(),
      "razorpay_payment": razorpayPayment,
      if (airportCalculatedPrice != null)
        "airport_calculated_price": airportCalculatedPrice,
      if (airportDistanceKm != null) "airport_distance_km": airportDistanceKm,
      if (modifiedPickupLat != null && modifiedPickupLng != null)
        "pickup_location": {
          "lat": modifiedPickupLat,
          "lng": modifiedPickupLng,
        },
      if (modifiedDropLat != null && modifiedDropLng != null)
        "drop_location": {
          "lat": modifiedDropLat,
          "lng": modifiedDropLng,
        },
      if (calculatedDistanceKm != null && calculatedDistanceKm! > 0)
        "actual_distance_km": calculatedDistanceKm,
      "extra_km": currentExtraKm,
      "extra_km_charge": extraKMsCharge,
      "km_included": currentIncludedKm,
    };

    // remove null values
    body.removeWhere((k, v) => v == null);

    try {
      Utility.showLoader();
      final res = await homePresenter.createBooking(body);
      Utility.closeLoader();

      if (res.hasError) {
        print('DEBUG: API Error. res.data = ${res.data}');
        try {
          final decoded = jsonDecode(res.data ?? '{}');
          Utility.showMessage(
            decoded['Message'] ?? 'Booking failed',
            MessageType.error,
            null,
            'OK',
          );
        } catch (_) {
          Utility.showMessage('Booking failed', MessageType.error, null, 'OK');
        }
        isProcessingBooking = false;
        update();
        return;
      }

      final json = jsonDecode(res.data);
      bookingResponse = (json['Data'] is Map<String, dynamic>)
          ? json['Data'] as Map<String, dynamic>
          : {'raw': json};
      bookingProcessed = true;
      isProcessingBooking = false;
      Utility.showMessage(
        json['Message'] ?? 'Booking successful',
        MessageType.success,
        null,
        'OK',
      );
      showBookingConfirmationDialog();
      update();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController != null && scrollController!.hasClients) {
          scrollController!.animateTo(
            scrollController!.position.maxScrollExtent,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      Utility.closeDialog();
      isProcessingBooking = false;
      update();
      Utility.showMessage('Booking error: $e', MessageType.error, null, 'OK');
    } finally {
      Utility.closeDialog();
    }
  }

  void onProceedPressed(BuildContext context) async {
    // hide keyboard / unfocus
    FocusScope.of(context).unfocus();

    if (selectedExploreCab == null || selectedVehicle == null) {
      Utility.showMessage(
        "Missing trip or vehicle details",
        MessageType.error,
        null,
        "OK",
      );
      return;
    }

    // mark processing & UI spinner
    isProcessingBooking = true;
    bookingProcessed = false;
    update();

    // if advance percent is 0 -> skip online payment
    if (selectedAdvancePercent == 0) {
      // no payment now, create booking with payment_type 0
      await _createBookingAfterPayment(
        paymentMode: "Offline",
        paymentType: 0,
        paymentId: '',
        razorpayPayment: null,
      );
      return;
    }

    // otherwise open razorpay for advanceAmount
    openRazorpayCheckout();
  }

  // store search input controllers (you already have these)
  TextEditingController formController = TextEditingController(); // from
  TextEditingController toController = TextEditingController(); // to
  TextEditingController fromDateController =
      TextEditingController(); // dd-MM-yyyy
  TextEditingController toDateController =
      TextEditingController(); // hh:mm a (pickup_time)
  TextEditingController localCityController =
      TextEditingController(); // for local rental
  bool oneWay = true;

  // Explore API results
  List<dynamic> exploreTrips = [];
  List<dynamic> exploreVehicles = [];
  List<dynamic> data = [];
  String exploreId = '';
  double totalKm = 0;
  double finalPrice = 0;
  dynamic basePrice = 0;
  dynamic extraKilometer = 0;
  double? calculatedDistanceKm;
  bool isCalculatingDistance = false;
  List<bool> vehicleExpanded = [];

  /// Build the request body depending on trip type and call explore-cab
  List<dynamic> specialServices = [];
  List<String> selectedServiceIds = [];
  Map<String, dynamic>? selectedOffer;
  Map<String, dynamic>? selectedExploreCab;
  Map<String, dynamic>? selectedVehicle;
  Map<String, dynamic>? selectedVehicleWrapper;
  double baseFare = 0;
  double discountValue = 0;
  double totalFare = 0;

  /// Called when the controller is removed from memory by Get.
  /// Dispose native resources here to avoid leaks.

  Future<void> fetchSpecialServicesWithoutLoader() async {
    final res = await homePresenter.getSpecialServices(showLoader: false); // 👈
    if (res.hasError) {
      print('DEBUG: API Error. res.data = ${res.data}');
      Utility.showMessage(
        'Failed to fetch services',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }
    final json = jsonDecode(res.data);
    specialServices = (json['Data'] ?? []) as List<dynamic>;
    update();
  }

  Future<void> fetchCouponOfferWithoutLoader(
    String vehicleId,
    String from,
    String to,
  ) async {
    if (vehicleId.isEmpty) return;

    try {
      final res = await homePresenter.getOffers(
        vehicleId: vehicleId,
        from: from,
        to: to,
        showLoader: false, // 👈
      );

      if (res.hasError) return;

      final json = jsonDecode(res.data);
      final data = json['Data'];

      if (data is List && data.isEmpty) {
        selectedOffer = null;
        discountValue = 0;
      } else if (data is List && data.isNotEmpty) {
        selectedOffer = data.first;
        discountValue = (selectedOffer?['discount_value'] ?? 0).toDouble();
      }

      updateTotalFare();
      update();
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      Utility.showMessage(
        'Error loading offers: $e',
        MessageType.error,
        null,
        'OK',
      );
    }
  }

  /// Fetch Special Services
  Future<void> fetchSpecialServices() async {
    final res = await homePresenter.getSpecialServices();
    if (res.hasError) {
      print('DEBUG: API Error. res.data = ${res.data}');
      Utility.showMessage(
        'Failed to fetch services',
        MessageType.error,
        null,
        'OK',
      );
      return;
    }

    final json = jsonDecode(res.data);
    specialServices = (json['Data'] ?? []) as List<dynamic>;
    update();
  }

  /// Fetch Coupon Offer based on current selection
  Future<void> fetchCouponOffer(
    String vehicleId,
    String from,
    String to,
  ) async {
    if (vehicleId.isEmpty) return;

    try {
      final res = await homePresenter.getOffers(
        vehicleId: vehicleId,
        from: from,
        to: to,
      );

      if (res.hasError) {
        print('DEBUG: API Error. res.data = ${res.data}');
        try {
          final bodyRes = jsonDecode(res.data);
          Utility.showMessage(
            (bodyRes['Message'] ?? bodyRes['message'] ?? res.data).toString(),
            MessageType.error,
            null,
            'OK',
          );
        } catch (_) {
          Utility.showMessage(
            'Failed to fetch offers',
            MessageType.error,
            null,
            'OK',
          );
        }
        return;
      }

      // ✅ Always close dialog manually if presenter didn't
      Utility.closeDialog();

      final json = jsonDecode(res.data);
      final data = json['Data'];

      // If list and empty -> no offers
      if (data is List && data.isEmpty) {
        selectedOffer = null;
        discountValue = 0;
        updateTotalFare();
        update();
        return;
      }

      // If list and has items, take the first one
      if (data is List && data.isNotEmpty) {
        selectedOffer = data.first as Map<String, dynamic>;
        discountValue = (selectedOffer?['discount_value'] ?? 0).toDouble();
      }
      // If map
      else if (data is Map<String, dynamic>) {
        selectedOffer = data;
        discountValue = (selectedOffer?['discount_value'] ?? 0).toDouble();
      }

      updateTotalFare();
      update();
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      // ✅ Make sure loader closes even if parsing fails
      Utility.closeDialog();
      Utility.showMessage(
        'Error loading offers: $e',
        MessageType.error,
        null,
        'OK',
      );
    }
  }

  /// Public method used from UI when user taps "current location".
  Future<void> useCurrentLocationAndFillCity() async {
    try {
      Utility.showLoader(); // 🔹 show loader immediately

      // 1️⃣ Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Utility.closeLoader();
        Utility.showMessage(
          'Location services are disabled. Please enable them.',
          MessageType.error,
          null,
          'OK',
        );
        return;
      }

      // 2️⃣ Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        Utility.closeLoader();
        Utility.showMessage(
          'Location permission denied.',
          MessageType.error,
          null,
          'OK',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        Utility.closeLoader();
        Utility.showMessage(
          'Location permission permanently denied. Please enable it from app settings.',
          MessageType.error,
          null,
          'OK',
        );
        return;
      }

      // 3️⃣ Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4️⃣ Reverse geocode to get city name via Google Maps Geocoding API
      String city = '';
      String state = '';
      String country = 'India';

      try {
        final googleUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${StringConstants.gpooglePlaceKey}',
        );
        final response = await ApiWrapper.client
            .get(googleUrl)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final resData = jsonDecode(response.body);
          if (resData['status'] == 'OK' &&
              resData['results'] is List &&
              (resData['results'] as List).isNotEmpty) {
            final firstResult = resData['results'][0];
            final comps = firstResult['address_components'] as List? ?? [];

            String getComp(List<String> types) {
              final found = comps.firstWhereOrNull(
                (c) =>
                    c is Map &&
                    (c['types'] as List?)?.any((t) => types.contains(t)) == true,
              );
              return found != null ? (found['long_name']?.toString() ?? '') : '';
            }

            city = getComp(['locality']);
            if (city.isEmpty) city = getComp(['administrative_area_level_2']);
            if (city.isEmpty) city = getComp(['administrative_area_level_3']);
            state = getComp(['administrative_area_level_1']);
            country = getComp(['country']);
            if (country.isEmpty) country = 'India';
          }
        }
      } catch (gErr) {
        debugPrint('Google Geocode error: $gErr');
      }

      // Fallback: Placemark from coordinates
      if (city.isEmpty) {
        final List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          city = place.locality?.isNotEmpty == true
              ? place.locality!
              : (place.subAdministrativeArea?.isNotEmpty == true
                  ? place.subAdministrativeArea!
                  : (place.administrativeArea ?? ''));
          state = place.administrativeArea ?? '';
          country = place.country ?? 'India';
        }
      }

      if (city.isEmpty && state.isEmpty) {
        Utility.closeLoader();
        Utility.showMessage(
          'Could not extract city name.',
          MessageType.error,
          null,
          'OK',
        );
        return;
      }

      // Format as "City, State, Country" (e.g. "Ahmedabad, Gujarat, India")
      final List<String> parts = [];
      if (city.isNotEmpty) parts.add(city);
      if (state.isNotEmpty) parts.add(state);
      if (country.isNotEmpty) parts.add(country);
      final String formattedAddress = parts.isNotEmpty ? parts.join(", ") : city;

      // 5️⃣ Autofill text field and store coordinates
      formController.text = formattedAddress;
      localCityController.text = formattedAddress;
      selectedCity = city;
      modifiedPickupLat = position.latitude;
      modifiedPickupLng = position.longitude;
      update();

      Utility.closeLoader();
      Utility.showMessage(
        'Detected location: $formattedAddress',
        MessageType.success,
        null,
        'OK',
      );
    } catch (e, st) {
      Utility.closeLoader();
      debugPrint('useCurrentLocationAndFillCity error: $e\n$st');
      Utility.showMessage(
        'Failed to fetch location: $e',
        MessageType.error,
        null,
        'OK',
      );
    }
  }

  // Call when user changes advance percent or GST toggle to recompute UI
  void setAdvancePercent(int percent) {
    selectedAdvancePercent = percent;
    update();
  }

  void toggleGst(bool value) {
    hasGst = value;
    update();
  }

  /// Update total fare
  void updateTotalFare() {
    double servicesTotal = selectedServiceIds.fold(0.0, (sum, id) {
      final svc = specialServices.firstWhereOrNull((s) => s['_id'] == id);
      final amt = (svc?['amount'] is num)
          ? (svc!['amount'] as num).toDouble()
          : 0.0;
      return sum + amt;
    });

    double baseF = displayBaseFare;
    double extraKmC = (tripMode == 3) ? 0.0 : extraKMsCharge;

    // PRE-DISCOUNT TOTAL
    double preDiscountTotal = baseF + extraKmC + servicesTotal;

    double discountAmount = 0.0;

    if (selectedOffer != null) {
      if (selectedOffer?['discount_type'] == '%') {
        discountAmount = preDiscountTotal * (discountValue / 100);
      } else {
        discountAmount = discountValue;
      }
    }

    double farePostDiscount = preDiscountTotal - discountAmount;
    double gp = gstPercent;
    double calculatedGst = gp > 0
        ? (farePostDiscount * gp / 100).round().toDouble()
        : 0.0;

    totalFare = farePostDiscount + calculatedGst;

    update();
  }

  /// Final booking API
  final GlobalKey<FormState> bookingKey = GlobalKey<FormState>();

  // processBooking validates and then proceeds to create request body
  // ===== add near other controller fields =====
  // in HomeController
  // true after booking success

  // Call this whenever user edits anything to reset processed state
  void markUnprocessed() {
    if (bookingProcessed == true || isProcessingBooking == true) {
      bookingProcessed = false;
      isProcessingBooking = false;
      update();
    }
  }
  // true when backend returned success

  // For round-trip multiple destinations:
  List<TextEditingController> toControllers = [TextEditingController()];
  int tripMode = 0; // 0 = Oneway, 1 = Round Trip, 2 = Local Rental, 3 = Airport
  String pickupType = 'pickup'; // 'pickup' or 'drop' for Airport mode

  void setPickupType(String type) {
    pickupType = type;
    // Clear fields when toggling to avoid confusion
    formController.clear();
    toController.clear();
    update();
  }

  // Flags & booking UI state (you probably already have similar)

  // Convert dd-MM-yyyy to yyyy-MM-dd for API
  String _formatToApiDate(String ddmmyyyy) {
    try {
      final parts = ddmmyyyy.split('-');
      if (parts.length == 3) {
        final d = parts[0].padLeft(2, '0');
        final m = parts[1].padLeft(2, '0');
        final y = parts[2];
        return '$y-$m-$d';
      }
    } catch (_) {}
    return ddmmyyyy;
  }

  // ---------- exploreCabs updated ----------
  Future<void> exploreCabs() async {
    airportSlabPrice = null;
    modifiedPickupLat = null;
    modifiedPickupLng = null;
    modifiedDropLat = null;
    modifiedDropLng = null;
    final rawFrom = formController.text.trim();
    final pickupDateRaw = fromDateController.text.trim();

    // Clean pincodes (6 digit numbers)
    String cleanCity(String val) => val
        .replaceAll(RegExp(r'\b\d{6}\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ,', ',')
        .trim();

    String extractCity(String address) {
      final clean = address.trim();
      if (clean.isEmpty) return "";
      final addressLower = clean.toLowerCase();
      for (final city in CitiesList.cities) {
        if (addressLower.contains(city.toLowerCase())) {
          return city;
        }
      }
      final parts = clean.split(',');
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        return parts[0].trim();
      }
      return clean;
    }

    final fromCity = extractCity(rawFrom);

    if (tripMode == 0) {
      final toCity = extractCity(toController.text.trim());
      if (fromCity.isNotEmpty &&
          toCity.isNotEmpty &&
          fromCity.toLowerCase() == toCity.toLowerCase()) {
        print('DEBUG: From/To same');
        Utility.showMessage(
          "From and To cannot be the same",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    } else if (tripMode == 1) {
      for (var c in toControllers) {
        final toCity = extractCity(c.text.trim());
        if (toCity.isNotEmpty && fromCity.toLowerCase() == toCity.toLowerCase()) {
          print('DEBUG: From/To same');
          Utility.showMessage(
            "From and To cannot be the same",
            MessageType.error,
            null,
            "OK",
          );
          return;
        }
      }
    }

    // Validate depending on tripMode
    if (tripMode == 0) {
      final toCity = extractCity(toController.text.trim());
      if (fromCity.isEmpty || toCity.isEmpty || pickupDateRaw.isEmpty) {
        print('DEBUG: From/To/Date empty');
        Utility.showMessage(
          "Please fill From/To/Pickup date",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
      if (toDateController.text.trim().isEmpty) {
        print('DEBUG: Time empty');
        Utility.showMessage(
          "Please fill Pickup date/time",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    } else if (tripMode == 1) {
      final toList = toControllers
          .map((c) => extractCity(c.text.trim()))
          .where((s) => s.isNotEmpty)
          .toList();
      if (fromCity.isEmpty ||
          toList.isEmpty ||
          pickupDateRaw.isEmpty ||
          returnDateController.text.trim().isEmpty) {
        Utility.showMessage(
          "Please fill From/To/Pickup/Return date",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    } else if (tripMode == 2) {
      final city = extractCity(localCityController.text.trim());
      if (city.isEmpty || pickupDateRaw.isEmpty) {
        Utility.showMessage(
          "Please select City and Pickup date",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    } else if (tripMode == 3) {
      final validationTo = cleanCity(toController.text.trim());
      if (fromCity.isEmpty || validationTo.isEmpty || pickupDateRaw.isEmpty) {
        print('DEBUG: Details empty');
        Utility.showMessage(
          "Please fill all details",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    }

    Map<String, dynamic> body = {};
    if (tripMode == 0) {
      final toCity = extractCity(toController.text.trim());
      body = {
        "trip_type": "Oneway",
        "from": fromCity,
        "to": toCity,
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "pickup_time": toDateController.text.trim().isNotEmpty
            ? toDateController.text.trim()
            : "09:00 AM",
      };
    } else if (tripMode == 1) {
      final toList = toControllers
          .map((c) => extractCity(c.text.trim()))
          .where((s) => s.isNotEmpty)
          .toList();
      final returnDateRaw = returnDateController.text.trim();
      final pTime = pickupTimeRtController.text.trim();
      body = {
        "trip_type": "Round Trip",
        "from": fromCity,
        "to": toList,
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "return_date": _formatToApiDate(returnDateRaw),
        "pickup_time": pTime.isNotEmpty ? pTime : "09:00 AM",
      };
    } else if (tripMode == 2) {
      final city = extractCity(localCityController.text.trim());
      final selectedBlock = rentalBlocks.isNotEmpty
          ? rentalBlocks[selectedRentalIndex]
          : null;
      final pTime = toDateController.text.trim();
      body = {
        "trip_type": "Local Rental Trip",
        "city": city,
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "pickup_time": pTime.isNotEmpty ? pTime : "09:00 AM",
        "selected_hours": selectedBlock?['hours'].toString(),
        "selected_km": selectedBlock?['km'].toString(),
      };
    } else if (tripMode == 3) {
      final pTime = toDateController.text.trim();
      final fromVal = pickupType == "pickup" ? rawFrom : extractCity(rawFrom);
      final toVal = pickupType == "pickup"
          ? extractCity(toController.text.trim())
          : toController.text.trim();
      body = {
        "trip_type": "Airport",
        "pickup_type": pickupType,
        "from": fromVal,
        "to": toVal,
        "pickup_date": _formatToApiDate(pickupDateRaw),
        "pickup_time": pTime.isNotEmpty ? pTime : "09:00 AM",
      };
    }

    final res = await homePresenter.exploreCabs(body, showLoader: true);
    if (res.hasError) {
      print('DEBUG: API Error. res.data = ${res.data}');
      try {
        final bodyRes = jsonDecode(res.data);
        Utility.showMessage(
          (bodyRes['Message'] ?? bodyRes['message'] ?? res.data).toString(),
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(
          res.data ?? 'Failed to search',
          MessageType.error,
          null,
          'OK',
        );
      }
      return;
    }

    try {
      final json = jsonDecode(res.data) as Map<String, dynamic>;
      datta = json['Data'] as Map<String, dynamic>?;
      exploreTrips = datta?['trips'] as List<dynamic>? ?? [];

      if (tripMode == 2) {
        rentalBlocks = [];
        if (exploreTrips.isNotEmpty) {
          final trip = exploreTrips[0];
          final vehiclePricing = trip['vehicle_pricing'] as List? ?? [];
          final Set<String> seen = {};
          for (var vp in vehiclePricing) {
            final blocks = vp['pricing_blocks'] as List? ?? [];
            for (var block in blocks) {
              final b = Map<String, dynamic>.from(block);
              final key = "${b['hours']}_${b['km']}";
              if (seen.add(key)) {
                rentalBlocks.add(b);
              }
            }
          }
          rentalBlocks.sort(
            (a, b) => (a['hours'] as int).compareTo(b['hours'] as int),
          );
        }

        if (rentalBlocks.isNotEmpty &&
            selectedRentalIndex >= rentalBlocks.length) {
          selectedRentalIndex = 0;
        }
      }

      exploreVehicles = datta?['vehicles'] as List<dynamic>? ?? [];
      exploreId = datta?['exploreId']?.toString() ?? '';
      totalKm = (datta?['total_km'] is num)
          ? (datta?['total_km'] as num).toDouble()
          : 0;
      finalPrice = (datta?['final_price'] is num)
          ? (datta?['final_price'] as num).toDouble()
          : 0;
      vehicleExpanded = List<bool>.filled(exploreVehicles.length, false);

      if (tripMode == 3) {
        await calculateAirportSlabPrice();
      }

      update();

      RouteManagement.gotoSelectVehicalScreen();
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      Utility.showMessage(
        'Failed to parse results: $e',
        MessageType.error,
        null,
        'OK',
      );
    }
  }

  // ---------- processBooking updated ----------
  Future<void> processBooking() async {
    if (bookingKey.currentState == null ||
        !(bookingKey.currentState!.validate())) {
      Utility.showMessage(
        "Please fill all required fields",
        MessageType.error,
        null,
        "OK",
      );
      return;
    }
    if (selectedExploreCab == null || selectedVehicle == null) {
      Utility.showMessage(
        "Missing trip or vehicle details",
        MessageType.error,
        null,
        "OK",
      );
      return;
    }

    isProcessingBooking = true;
    bookingProcessed = false;
    update();

    final specialServicesList = selectedServiceIds
        .map((id) => {"service_id": id})
        .toList();

    final tripType = (selectedExploreCab?['trip_type'] ?? 'Oneway').toString();

    final from = (selectedExploreCab?['from'] ?? formController.text)
        .toString();

    // Prepare to list: if round trip, ensure array; if local rental, no 'to' array
    List<String> toList = [];

    // ------------------------------------
    // ------------------------------------
    // 🚫 Pickup and Drop Validation
    // ------------------------------------

    final pickupAddr = pickupController.text.trim();
    if (pickupAddr.isEmpty) {
      isProcessingBooking = false;
      Utility.showMessage(
        "Please select pickup address",
        MessageType.error,
        null,
        "OK",
      );
      return;
    }

    if (tripType != 'Local Rental Trip') {
      final dropAddr = dropController.text.trim();
      if (dropAddr.isEmpty) {
        isProcessingBooking = false;
        Utility.showMessage(
          "Please select drop address",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    }

    // Oneway
    if (tripType == 'Oneway') {
      final dropAddr = dropController.text.trim();
      if (pickupAddr.isNotEmpty &&
          dropAddr.isNotEmpty &&
          pickupAddr.toLowerCase() == dropAddr.toLowerCase()) {
        isProcessingBooking = false;
        Utility.showMessage(
          "Pickup and Drop address cannot be the same",
          MessageType.error,
          null,
          "OK",
        );
        return;
      }
    }

    // Round Trip - toList contains drop addresses
    if (tripType == 'Round Trip') {
      for (var d in toList) {
        if (pickupAddr.isNotEmpty &&
            d.trim().toLowerCase() == pickupAddr.toLowerCase()) {
          isProcessingBooking = false;
          Utility.showMessage(
            "Pickup and Drop addresses cannot be the same",
            MessageType.error,
            null,
            "OK",
          );
          return;
        }
      }
    }

    if (tripType == 'Round Trip') {
      final toVal = selectedExploreCab?['to'];
      if (toVal is List) {
        toList = List<String>.from(toVal.map((e) => e.toString()));
      } else if (toVal != null) {
        toList = [toVal.toString()];
      }
    } else if (tripType == 'Oneway') {
      final t = selectedExploreCab?['to'] ?? toController.text;
      toList = [t.toString()];
    } else if (tripType == 'Local Rental Trip') {
      // local rental uses city instead of 'to'
      final city = selectedExploreCab?['city'] ?? localCityController.text;
      // keep toList empty
      toList = [];
    }

    // date for API (yyyy-MM-dd)
    String dateForApi = '';
    try {
      final pd =
          selectedExploreCab?['pickup_date']?.toString() ??
          fromDateController.text;
      if (pd.isNotEmpty) {
        final dt = DateTime.parse(pd);
        dateForApi =
            '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      // fallback: convert if in dd-MM-yyyy format
      dateForApi = _formatToApiDate(fromDateController.text.trim());
    }

    double? airportCalculatedPrice;
    double? airportDistanceKm;
    if (tripType == 'Airport' && airportSlabPrice != null) {
      final List slabResults = airportSlabPrice!['slab_results'] as List? ?? [];
      final vObj = selectedVehicle;
      final vtVal = vObj != null ? vObj['vehicle_type'] : null;
      final vTypeId = vtVal is Map ? vtVal['_id']?.toString() : vtVal?.toString();
      final vId = vObj != null ? vObj['_id']?.toString() : null;
      final matchedSlab = slabResults.firstWhere(
        (r) {
          final rVid = r['vehicleId']?.toString();
          return rVid != null && (rVid == vTypeId || rVid == vId);
        },
        orElse: () => null,
      );
      if (matchedSlab != null) {
        final p = matchedSlab['slab_price'] ?? matchedSlab['price'];
        airportCalculatedPrice = (p is num) ? p.toDouble() : null;
      }
      airportDistanceKm = (airportSlabPrice!['distance_km'] is num)
          ? (airportSlabPrice!['distance_km'] as num).toDouble()
          : null;
    }

    // Ensure coordinates are resolved for driver assignment
    if (modifiedPickupLat == null || modifiedPickupLng == null) {
      final pAddr = pickupController.text.trim().isNotEmpty
          ? pickupController.text.trim()
          : formController.text.trim();
      if (pAddr.isNotEmpty) {
        final coords = await GooglePlacesHelper.getCoordinates(
          pAddr,
          StringConstants.gpooglePlaceKey,
        );
        if (coords != null) {
          modifiedPickupLat = coords["lat"];
          modifiedPickupLng = coords["lng"];
        }
      }
    }

    if (modifiedDropLat == null || modifiedDropLng == null) {
      final dAddr = dropController.text.trim().isNotEmpty
          ? dropController.text.trim()
          : toController.text.trim();
      if (dAddr.isNotEmpty) {
        final coords = await GooglePlacesHelper.getCoordinates(
          dAddr,
          StringConstants.gpooglePlaceKey,
        );
        if (coords != null) {
          modifiedDropLat = coords["lat"];
          modifiedDropLng = coords["lng"];
        }
      }
    }

    final body = <String, dynamic>{
      "trip_type": tripType,
      // include from only where relevant
      if (tripType != 'Local Rental Trip') "from": from,
      if (tripType == 'Local Rental Trip')
        "city": (selectedExploreCab?['city'] ?? localCityController.text),
      "date": dateForApi,
      if (tripType == 'Round Trip' &&
          (selectedExploreCab?['return_date'] ?? '').toString().isNotEmpty)
        "return_date":
            (selectedExploreCab?['return_date'] ??
            _formatToApiDate(fromDateController.text)),
      "pickup_time":
          selectedExploreCab?['pickup_time'] ?? toDateController.text,
      "pickup_address": pickupController.text.trim(),
      // drop_address differs:
      if (tripType == 'Round Trip')
        "drop_address": (dropController.text.trim()),
      if (tripType == 'Oneway') "drop_address": (dropController.text.trim()),
      if (tripType == 'Airport') "drop_address": (dropController.text.trim()),
      "vehicleId": selectedVehicle?['_id'] ?? '',
      "traveler_name": nameController.text.trim(),
      "traveler_email": emailController.text.trim(),
      "traveler_mobile": mobileNumberController.text.trim(),
      "special_services": specialServicesList,
      "offers_id": selectedOffer?['_id'] ?? null,
      "exploreId": selectedExploreCab?['_id'] ?? exploreId,
      if (airportCalculatedPrice != null)
        "airport_calculated_price": airportCalculatedPrice,
      if (airportDistanceKm != null) "airport_distance_km": airportDistanceKm,
      if (modifiedPickupLat != null && modifiedPickupLng != null)
        "pickup_location": {
          "lat": modifiedPickupLat,
          "lng": modifiedPickupLng,
        },
      if (modifiedDropLat != null && modifiedDropLng != null)
        "drop_location": {
          "lat": modifiedDropLat,
          "lng": modifiedDropLng,
        },
      if (calculatedDistanceKm != null && calculatedDistanceKm! > 0)
        "actual_distance_km": calculatedDistanceKm,
      "extra_km": currentExtraKm,
      "extra_km_charge": extraKMsCharge,
      "km_included": currentIncludedKm,
    };

    body.removeWhere((k, v) => v == null);

    try {
      final res = await homePresenter.processBooking(body);

      isProcessingBooking = false;

      if (res.hasError) {
        print('DEBUG: API Error. res.data = ${res.data}');
        try {
          final decoded = jsonDecode(res.data ?? '{}');
          Utility.showMessage(
            decoded['Message'] ?? 'Booking failed',
            MessageType.error,
            null,
            'OK',
          );
          update();
          return;
        } catch (e, st) {
          print('DEBUG: Exception caught: $e\n$st');
          Utility.showMessage(
            res.data ?? 'Booking failed',
            MessageType.error,
            null,
            'OK',
          );
          update();
          return;
        }
      }

      final json = jsonDecode(res.data);
      bookingResponse = (json['Data'] is Map)
          ? json['Data'] as Map<String, dynamic>
          : {'raw': json};
      bookingProcessed = true;
      Utility.showMessage(
        json['Message'] ?? 'Booking successful',
        MessageType.success,
        null,
        'OK',
      );
      basePrice = (json?["Data"]["final_price"] ?? 0).toDouble();
      extraKilometer = (json?["Data"]["extra_km"] ?? 0).toDouble();

      // ensure totals & UI updated
      updateTotalFare();
      update();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController != null && scrollController!.hasClients) {
          scrollController!.animateTo(
            scrollController!.position.maxScrollExtent,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      isProcessingBooking = false;
      update();
      print('Booing error: $e');
      Utility.showMessage('Booking error: $e', MessageType.error, null, 'OK');
    } finally {
      isProcessingBooking = false;

      update();
    }
  }
  // ===== replace your processBooking implementation with this =====

  // helper to produce yyyy-MM-dd from fromDateController (if already dd-MM-yyyy)
  String controllerDateForApi() {
    final text = fromDateController.text.trim();
    if (text.isEmpty) return '';
    final parts = text.split('-');
    if (parts.length == 3)
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    return text;
  }

  void toggleVehicleDetails(int index) {
    if (index >= 0 && index < vehicleExpanded.length) {
      vehicleExpanded[index] = !vehicleExpanded[index];
      update();
    }
  }

  /// call select-vehicle API and navigate forward on success
  // inside HomeController (add new fields near other state)
  // optional: 'vehicle' object from response

  // replace your existing selectVehicle method with this implementation

  Future<void> selectVehicle({required String vehicleId}) async {
    if (exploreId.isEmpty) {
      Utility.showMessage('Missing explore id', MessageType.error, null, 'OK');
      return;
    }
    Utility.showLoader();
    final selectedBlock = (tripMode == 2 &&
            rentalBlocks.isNotEmpty &&
            selectedRentalIndex < rentalBlocks.length)
        ? rentalBlocks[selectedRentalIndex]
        : null;

    final double? tKm = tripMode == 3
        ? ((airportSlabPrice?['distance_km'] as num?)?.toDouble() ?? totalKm)
        : null;

    final res = await homePresenter.selectVehicle(
      vehicleId: vehicleId,
      exploreCabId: exploreId,
      selectedHours: selectedBlock?['hours']?.toString(),
      selectedKm: selectedBlock?['km']?.toString(),
      totalKm: tKm,
      showLoader: true,
    );

    if (res.hasError) {
      print('DEBUG: API Error. res.data = ${res.data}');
      Utility.closeLoader();
      try {
        final bodyRes = jsonDecode(res.data);
        Utility.showMessage(
          (bodyRes['Message'] ?? bodyRes['message'] ?? res.data).toString(),
          MessageType.error,
          null,
          'OK',
        );
      } catch (_) {
        Utility.showMessage(res.data, MessageType.error, null, 'OK');
      }
      return;
    }

    try {
      Utility.closeLoader();
      final json = jsonDecode(res.data) as Map<String, dynamic>;
      final data = json['Data'] as Map<String, dynamic>?;
      log("ddddddd$data");
      final vMap = (data != null && data['vehicle'] is Map)
          ? data['vehicle'] as Map
          : null;
      final expMap = (data != null && data['exploreCab'] is Map)
          ? data['exploreCab'] as Map
          : null;
      final vTypeVal = vMap?['vehicle_type'];
      final vTypeId = vTypeVal is Map ? vTypeVal['_id']?.toString() : vTypeVal?.toString();

      if (tripMode == 3 && airportSlabPrice != null) {
        final List slabResults =
            airportSlabPrice!['slab_results'] as List? ?? [];
        final matchedSlab = slabResults.firstWhere(
          (r) =>
              r['vehicleId']?.toString() == vehicleId ||
              (vTypeId != null && r['vehicleId']?.toString() == vTypeId),
          orElse: () => null,
        );
        if (matchedSlab != null) {
          final slabP = matchedSlab['slab_price'] ?? matchedSlab['price'];
          basePrice = (slabP is num) ? slabP.toDouble() : 0.0;
        } else {
          basePrice = (expMap?['final_price'] is num)
              ? (expMap!['final_price'] as num).toDouble()
              : 0.0;
        }
      } else if (tripMode == 2) {
        final localP = getLocalRentalPrice(vTypeId ?? vehicleId);
        if (localP != null && localP > 0) {
          basePrice = localP;
        } else {
          basePrice = (expMap?['final_price'] is num)
              ? (expMap!['final_price'] as num).toDouble()
              : 0.0;
        }
      } else {
        basePrice = (expMap?['final_price'] is num)
            ? (expMap!['final_price'] as num).toDouble()
            : 0.0;
      }
      // Save the important parts for VehicalDetilesScreen
      selectedExploreCab = data?['exploreCab'] as Map<String, dynamic>?;

      selectedVehicleWrapper = data?['vehicle'] as Map<String, dynamic>?;
      // some responses embed selected_vehicle inside exploreCab['selected_vehicle']
      if (selectedExploreCab != null &&
          selectedExploreCab!['selected_vehicle'] != null) {
        selectedVehicle = Map<String, dynamic>.from(
          selectedExploreCab!['selected_vehicle'],
        );
      } else if (selectedVehicleWrapper != null) {
        selectedVehicle = Map<String, dynamic>.from(selectedVehicleWrapper!);
      }

      // Resolve vehicle_type Map from exploreVehicles if it is returned as String (ID)
      if (selectedVehicle != null) {
        final vt = selectedVehicle!['vehicle_type'];
        if (vt is! Map) {
          final matchedVehicle = exploreVehicles.firstWhere(
            (v) =>
                v is Map &&
                (v['_id']?.toString() == selectedVehicle!['_id']?.toString() ||
                    v['_id']?.toString() == vehicleId),
            orElse: () => null,
          );
          if (matchedVehicle != null && matchedVehicle['vehicle_type'] is Map) {
            selectedVehicle!['vehicle_type'] = Map<String, dynamic>.from(
              matchedVehicle['vehicle_type'] as Map,
            );
          }
        }
      }

      if (tripMode == 3 && airportSlabPrice != null) {
        final slabDistance = (airportSlabPrice!['distance_km'] is num)
            ? (airportSlabPrice!['distance_km'] as num).toDouble()
            : 0.0;
        if (slabDistance > 0) {
          totalKm = slabDistance;
          if (selectedExploreCab != null) {
            selectedExploreCab!['totalKm'] = slabDistance;
          }
        }
      }

      // Do NOT pre-fill pickup/drop with city names so user explicitly chooses exact addresses
      if (tripMode == 3) {
        // Airport trip
        if (pickupType == 'pickup') {
          pickupController.text = formController.text;
          dropController.text = '';
        } else {
          pickupController.text = '';
          dropController.text = toController.text;
        }
      } else {
        pickupController.text = '';
        dropController.text = '';
      }
      modifiedPickupLat = null;
      modifiedPickupLng = null;
      modifiedDropLat = null;
      modifiedDropLng = null;

      updateTotalFare();
      update();
      Utility.showMessage('Vehicle selected', MessageType.success, null, 'OK');

      // navigate to details screen
      RouteManagement.gotoVehicalDetilesScreen();
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      Utility.closeLoader();
      Utility.showMessage(
        'Failed to parse selection response',
        MessageType.error,
        null,
        'OK',
      );
    }
  }

  /// Swap the From and To values (used by the center swap button)
  void swapFromTo() {
    if (tripMode == 3) {
      final oldFrom = formController.text;
      final oldTo = toController.text;
      pickupType = (pickupType == 'pickup') ? 'drop' : 'pickup';
      formController.text = oldTo;
      toController.text = oldFrom;
      update();
      return;
    }

    final currentFrom = formController.text;

    if (tripMode == 1 && toControllers.isNotEmpty) {
      final currentTo = toControllers.first.text;
      formController.text = currentTo;
      toControllers.first.text = currentFrom;
    } else {
      final currentTo = toController.text;
      formController.text = currentTo;
      toController.text = currentFrom;
    }

    update();
  }

  /// ----------------------------------------------------Select Vehical Screen-----------------------------------

  bool showVehicalDetiles = false;
  bool inclusion = true;
  int selectedPaymentIndex = 1;

  int selectedVehicalIndex = 0; // default selected index

  List vehicalDetiles = [
    "inclusion".tr,
    "exclusion".tr,
    "facility".tr,
    "T & C".tr,
  ];

  TextEditingController pickupController = TextEditingController();
  TextEditingController dropController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileNumberController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController gstController = TextEditingController();

  void showBookingConfirmationDialog([BuildContext? context]) {
    final ctx = context ?? Get.context;
    if (ctx == null) return;

    final travelerName = nameController.text.trim();
    String rawBookingId = '';
    if (bookingResponse != null) {
      rawBookingId = (bookingResponse!['booking']?['booking_id'] ??
              bookingResponse!['booking_id'] ??
              bookingResponse!['booking_no'] ??
              bookingResponse!['bookingId'] ??
              bookingResponse!['id'] ??
              '')
          .toString()
          .trim();
    }
    final formattedBookingId = rawBookingId.isNotEmpty
        ? (rawBookingId.startsWith('#') ? rawBookingId : '#$rawBookingId')
        : '';

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            RouteManagement.gotoBookingHistoryScreen(context);
            return false;
          },
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 18),
            backgroundColor: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---------------- HEADER ----------------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const SizedBox(width: 30), // Spacer for centering
                        const Expanded(
                          child: Text(
                            "Booking Confirmation",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            RouteManagement.gotoBookingHistoryScreen(context);
                          },
                          child: Container(
                            height: 30,
                            width: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),

                  // ---------------- BODY ----------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Car Image
                        Image.asset(
                          AssetConstants.carConfirm,
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),

                        // Thank You
                        Text(
                          "Thank You${travelerName.isNotEmpty ? ', $travelerName' : ''}!",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF96602),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Your Booking is received.
                        const Text(
                          "Your Booking is received.",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),

                        // Reservation details with Booking ID
                        RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF64748B),
                              height: 1.45,
                            ),
                            children: [
                              const TextSpan(text: "You will receive the reservation details with "),
                              TextSpan(
                                text: "Booking ID ${formattedBookingId.isNotEmpty ? formattedBookingId : '—'}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF96602),
                                ),
                              ),
                              const TextSpan(text: " on your email address and mobile soon."),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Driver details note
                        const Text(
                          "You will receive your driver details within 1 hour n 30 mins of your pickup time. We seek your cooperation to avoid enquiring about the driver details before the specific time.",
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 24),

                        // View Booking Button
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            RouteManagement.gotoBookingHistoryScreen(context);
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                AssetConstants.big_btn,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                              const Padding(
                                padding: EdgeInsets.only(right: 20.0),
                                child: Text(
                                  "View Booking",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------------
  // RECONSTRUCTED MISSING METHODS AND GETTERS
  // ------------------------------------------------------------------------

  List<Map<String, dynamic>> popularRoutesDetailed = [];

  final TextEditingController pickupTimeRtController = TextEditingController();
  final TextEditingController returnDateController = TextEditingController();

  void exploreFromQuickAction(int mode) {
    tripMode = mode;
    update();
    RouteManagement.gotoSerchScreen();
  }

  Future<void> refreshBookingFormScreen() async {
    await fetchSpecialServicesWithoutLoader();
    update();
  }

  Future<void> refreshVehicleListScreen() async {
    await exploreCabs();
  }

  Future<void> refreshVehicleDetailsScreen() async {
    update();
  }

  Map<String, dynamic>? airportSlabPrice;
  bool isCalculatingSlabPrice = false;
  double? modifiedPickupLat;
  double? modifiedPickupLng;
  double? modifiedDropLat;
  double? modifiedDropLng;

  Future<void> calculateAirportSlabPrice() async {
    if (exploreTrips.isEmpty) return;

    try {
      isCalculatingSlabPrice = true;
      update();

      final trip = exploreTrips.first;
      final tripId = trip['_id']?.toString() ?? '';
      final pType = trip['pickup_type']?.toString() ?? pickupType;

      String airportAddress = '';
      String userAddress = '';
      double? lat;
      double? lng;

      // Hardcoded fallback for Ahmedabad airport
      const String amdAirport =
          'Sardar Vallabhbhai Patel International Airport, Ahmedabad, Gujarat, India';

      if (pType == "pickup") {
        airportAddress = (trip['pickup_address']?.toString() ?? '').isNotEmpty
            ? trip['pickup_address']!.toString()
            : (formController.text.isNotEmpty
                  ? formController.text.trim()
                  : amdAirport);
        // For airport pickup mode: user is going FROM airport TO their home/location
        // dropController = set in vehicleDetails modify screen
        // toController = what user typed in the airport home search screen
        // trip['drop_address'] = fallback from DB (just city name)
        userAddress = dropController.text.trim().isNotEmpty
            ? dropController.text.trim()
            : (toController.text.trim().isNotEmpty
                  ? toController.text.trim()
                  : (trip['drop_address']?.toString() ?? ''));
        print(
          'DEBUG slab pickup userAddress: $userAddress (dropCtrl="${dropController.text.trim()}" toCtrl="${toController.text.trim()}")',
        );
        if (modifiedDropLat != null && modifiedDropLng != null) {
          lat = modifiedDropLat;
          lng = modifiedDropLng;
        } else {
          final userLoc = trip['drop_location'];
          if (userLoc != null) {
            if (userLoc['coordinates'] is List &&
                (userLoc['coordinates'] as List).length >= 2) {
              lng = (userLoc['coordinates'][0] as num).toDouble();
              lat = (userLoc['coordinates'][1] as num).toDouble();
            } else if (userLoc['lat'] != null && userLoc['lng'] != null) {
              lat = (userLoc['lat'] as num).toDouble();
              lng = (userLoc['lng'] as num).toDouble();
            }
          }
        }
      } else {
        airportAddress = (trip['drop_address']?.toString() ?? '').isNotEmpty
            ? trip['drop_address']!.toString()
            : amdAirport;
        // For airport drop mode: user is going FROM their home TO the airport
        // pickupController = set in vehicleDetails modify screen
        // formController = what user typed in the airport home search screen (their address)
        // trip['pickup_address'] = fallback from DB (just city name)
        userAddress = pickupController.text.trim().isNotEmpty
            ? pickupController.text.trim()
            : (formController.text.trim().isNotEmpty
                  ? formController.text.trim()
                  : (trip['pickup_address']?.toString() ?? ''));
        print(
          'DEBUG slab drop userAddress: $userAddress (pickupCtrl="${pickupController.text.trim()}" formCtrl="${formController.text.trim()}")',
        );
        if (modifiedPickupLat != null && modifiedPickupLng != null) {
          lat = modifiedPickupLat;
          lng = modifiedPickupLng;
        } else {
          final userLoc = trip['pickup_location'];
          if (userLoc != null) {
            if (userLoc['coordinates'] is List &&
                (userLoc['coordinates'] as List).length >= 2) {
              lng = (userLoc['coordinates'][0] as num).toDouble();
              lat = (userLoc['coordinates'][1] as num).toDouble();
            } else if (userLoc['lat'] != null && userLoc['lng'] != null) {
              lat = (userLoc['lat'] as num).toDouble();
              lng = (userLoc['lng'] as num).toDouble();
            }
          }
        }
      }

      if (airportAddress.isEmpty || userAddress.isEmpty) {
        print('DEBUG: airportAddress or userAddress empty – skipping slab API');
        isCalculatingSlabPrice = false;
        update();
        return;
      }

      final body = {
        "airport_full_address": airportAddress,
        "user_address": userAddress,
        "pickup_type": pType,
        "trip_id": tripId,
        if (lat != null && lng != null) "user_lat": lat,
        if (lat != null && lng != null) "user_lng": lng,
      };
      print('DEBUG: calculateAirportSlabPrice request body: $body');

      final res = await homePresenter.airportCalculateSlabPrice(
        body,
        showLoader: false,
      );
      print(
        'DEBUG: calculateAirportSlabPrice response hasError: ${res.hasError}, data: ${res.data}',
      );

      if (!res.hasError) {
        final decoded = jsonDecode(res.data) as Map<String, dynamic>;
        print('DEBUG: calculateAirportSlabPrice decoded: $decoded');
        if (decoded['IsSuccess'] == true) {
          airportSlabPrice = decoded['Data'] as Map<String, dynamic>?;

          if (airportSlabPrice != null &&
              airportSlabPrice!['distance_km'] != null) {
            final double dist = (airportSlabPrice!['distance_km'] is num)
                ? (airportSlabPrice!['distance_km'] as num).toDouble()
                : 0.0;
            if (dist > 0) {
              totalKm = dist;
              if (selectedExploreCab != null) {
                selectedExploreCab!['totalKm'] = dist;
              }
            }
          }

          if (selectedVehicle != null) {
            final List slabResults =
                airportSlabPrice!['slab_results'] as List? ?? [];
            final vObj = selectedVehicle;
            final vtVal = vObj != null ? vObj['vehicle_type'] : null;
            final vTypeId = vtVal is Map ? vtVal['_id']?.toString() : vtVal?.toString();
            final vId = vObj != null ? vObj['_id']?.toString() : null;

            final wrapObj = selectedVehicleWrapper;
            final wrapVtVal = wrapObj != null ? wrapObj['vehicle_type'] : null;
            final wrapTypeId = wrapVtVal is Map ? wrapVtVal['_id']?.toString() : wrapVtVal?.toString();
            final wrapId = wrapObj != null ? wrapObj['_id']?.toString() : null;

            final matchedSlab = slabResults.firstWhere(
              (r) {
                final rVid = r['vehicleId']?.toString();
                return rVid != null &&
                    (rVid == vTypeId ||
                        rVid == vId ||
                        rVid == wrapTypeId ||
                        rVid == wrapId);
              },
              orElse: () => null,
            );
            if (matchedSlab != null) {
              final slabP = matchedSlab['slab_price'] ?? matchedSlab['price'];
              basePrice = (slabP is num) ? slabP.toDouble() : 0.0;
            }
          }

          updateTotalFare();
        }
      }
    } catch (e) {
      debugPrint("Slab price error: $e");
    } finally {
      isCalculatingSlabPrice = false;
      update();
    }
  }

  Future<void> openPickupDatePicker(BuildContext context) async {
    DateTime initial = DateTime.now();
    try {
      if (fromDateController.text.isNotEmpty) {
        final parts = fromDateController.text.split('-');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? initial : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      fromDateController.text = '$d-$m-$y';

      // Auto-set return date to pickup_date + 1 day for Round Trip
      if (tripMode == 1) {
        final nextDay = picked.add(const Duration(days: 1));
        final rd = nextDay.day.toString().padLeft(2, '0');
        final rm = nextDay.month.toString().padLeft(2, '0');
        final ry = nextDay.year.toString();
        returnDateController.text = '$rd-$rm-$ry';
      }
      update();
    }
  }

  Future<void> openReturnDatePicker(BuildContext context) async {
    DateTime minDate = DateTime.now();
    try {
      if (fromDateController.text.isNotEmpty) {
        final parts = fromDateController.text.split('-');
        if (parts.length == 3) {
          minDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}

    DateTime initial = minDate.add(const Duration(days: 1));
    try {
      if (returnDateController.text.isNotEmpty) {
        final parts = returnDateController.text.split('-');
        if (parts.length == 3) {
          final cand = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          if (cand.isAfter(minDate) || cand.isAtSameMomentAs(minDate)) {
            initial = cand;
          }
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(minDate) ? initial : minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final d = picked.day.toString().padLeft(2, '0');
      final m = picked.month.toString().padLeft(2, '0');
      final y = picked.year.toString();
      returnDateController.text = '$d-$m-$y';
      update();
    }
  }


  Future<void> openPickupTimePicker(BuildContext context) async {
    final now = DateTime.now();
    bool isToday = false;
    try {
      if (fromDateController.text.trim().isNotEmpty) {
        final selectedDate = DateFormat('dd-MM-yyyy').parse(fromDateController.text.trim());
        isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;
      }
    } catch (_) {}

    TimeOfDay? minTime;
    TimeOfDay initialTime = TimeOfDay.now();

    if (isToday) {
      final future15 = now.add(const Duration(minutes: 15));
      int roundedMin = ((future15.minute + 4) ~/ 5) * 5;
      int roundedHour = future15.hour;
      if (roundedMin >= 60) {
        roundedMin = 0;
        roundedHour = (roundedHour + 1) % 24;
      }
      minTime = TimeOfDay(hour: future15.hour, minute: future15.minute);
      initialTime = TimeOfDay(hour: roundedHour, minute: roundedMin);
    }

    final picked = await showCustomTimePicker(
      context: context,
      initialTime: initialTime,
      minTime: minTime,
    );

    if (picked != null) {
      final hour12 = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final formattedTime =
          '${hour12.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} ${picked.period == DayPeriod.am ? 'AM' : 'PM'}';
      if (tripMode == 1) {
        pickupTimeRtController.text = formattedTime;
      } else {
        toDateController.text = formattedTime;
      }
      update();
    }
  }

  // --- Computed Properties for Details Screen ---

  int get rawUptoKmComputed {
    if (tripMode == 3) {
      if (airportSlabPrice != null && airportSlabPrice!['distance_km'] != null) {
        final d = (airportSlabPrice!['distance_km'] as num?)?.toInt() ?? 0;
        if (d > 0) return d;
      }
      return (selectedExploreCab?['totalKm'] as num?)?.toInt() ?? totalKm.toInt();
    }
    if (tripMode == 0) {
      final tkm =
          (selectedExploreCab?['totalKm'] as num?)?.toInt() ?? totalKm.toInt();
      return tkm;
    }
    return (selectedExploreCab?['upto_km'] as num?)?.toInt() ?? 0;
  }

  double get displayBaseFare {
    if (tripMode == 3) {
      final slabResults = airportSlabPrice?['slab_results'] as List? ?? [];
      final vObj = selectedVehicle;
      final vtVal = vObj != null ? vObj['vehicle_type'] : null;
      final vTypeId = vtVal is Map ? vtVal['_id']?.toString() : vtVal?.toString();
      final vId = vObj != null ? vObj['_id']?.toString() : null;

      final wrapObj = selectedVehicleWrapper;
      final wrapVtVal = wrapObj != null ? wrapObj['vehicle_type'] : null;
      final wrapTypeId = wrapVtVal is Map ? wrapVtVal['_id']?.toString() : wrapVtVal?.toString();
      final wrapId = wrapObj != null ? wrapObj['_id']?.toString() : null;

      final matchedSlab = slabResults.firstWhereOrNull(
        (r) {
          final rVid = r['vehicleId']?.toString();
          return rVid != null &&
              (rVid == vTypeId ||
                  rVid == vId ||
                  rVid == wrapTypeId ||
                  rVid == wrapId);
        },
      );
      if (matchedSlab != null) {
        final slabPrice = (matchedSlab['slab_price'] is num)
            ? (matchedSlab['slab_price'] as num).toDouble()
            : (matchedSlab['price'] is num)
                ? (matchedSlab['price'] as num).toDouble()
                : 0.0;
        if (slabPrice > 0) return slabPrice;
      }
      return (selectedExploreCab?['base_price_before_tax'] as num?)
              ?.toDouble() ??
          (selectedExploreCab?['fix_price_per_day'] as num?)?.toDouble() ??
          (selectedExploreCab?['final_price'] as num?)?.toDouble() ??
          0.0;
    }
    if (tripMode == 2) {
      final vObj = selectedVehicle;
      final vtVal = vObj != null ? vObj['vehicle_type'] : null;
      final wrapObj = selectedVehicleWrapper;
      final wrapVtVal = wrapObj != null ? wrapObj['vehicle_type'] : null;
      final vTypeId = (vtVal is Map ? vtVal['_id']?.toString() : vtVal?.toString()) ??
                      (wrapVtVal is Map ? wrapVtVal['_id']?.toString() : wrapVtVal?.toString());
      final localP = getLocalRentalPrice(vTypeId ?? '');
      if (localP != null && localP > 0) return localP;
      return (selectedExploreCab?['base_price_before_tax'] as num?)?.toDouble() ??
          (selectedExploreCab?['final_price'] as num?)?.toDouble() ??
          0.0;
    }
    return (selectedExploreCab?['base_price_before_tax'] as num?)?.toDouble() ??
        0.0;
  }

  int get tripDaysNum {
    return 1;
  }

  double get baseFarePerDay {
    return displayBaseFare;
  }

  double get includedKmPerDay {
    return (selectedExploreCab?['upto_km'] as num?)?.toDouble() ?? 0.0;
  }

  double get currentTotalKm {
    if (tripMode == 3) {
      if (airportSlabPrice != null && airportSlabPrice!['distance_km'] != null) {
        final d = (airportSlabPrice!['distance_km'] as num?)?.toDouble() ?? 0.0;
        if (d > 0) return d;
      }
      return (selectedExploreCab?['totalKm'] as num?)?.toDouble() ?? totalKm;
    }
    if (calculatedDistanceKm != null && calculatedDistanceKm! > 0) {
      if (tripMode == 1) {
        return calculatedDistanceKm! * 2;
      }
      return calculatedDistanceKm!;
    }
    return (selectedExploreCab?['totalKm'] as num?)?.toDouble() ?? totalKm;
  }

  double get currentIncludedKm {
    if (tripMode == 3) {
      if (airportSlabPrice != null && airportSlabPrice!['distance_km'] != null) {
        final d = (airportSlabPrice!['distance_km'] as num?)?.toDouble() ?? 0.0;
        if (d > 0) return d;
      }
      return (selectedExploreCab?['totalKm'] as num?)?.toDouble() ?? totalKm;
    }
    if (tripMode == 0) {
      // Oneway: included = the explore totalKm (package distance)
      return (selectedExploreCab?['totalKm'] as num?)?.toDouble() ?? totalKm;
    }
    if (tripMode == 1) {
      // RoundTrip: included = upto_km_limit × tripDays
      final limit = (selectedExploreCab?['upto_km_limit'] as num?)?.toDouble() ??
          (selectedExploreCab?['upto_km'] as num?)?.toDouble() ??
          0.0;
      return limit * tripDaysNum;
    }
    // Airport / Local rental
    final upto = (selectedExploreCab?['upto_km'] as num?)?.toDouble() ?? 0.0;
    if (upto > 0) return upto;
    return (selectedExploreCab?['totalKm'] as num?)?.toDouble() ?? totalKm;
  }


  double get currentExtraKm {
    if (tripMode == 0 || tripMode == 1) {
      final diff = currentTotalKm - currentIncludedKm;
      return diff > 0 ? diff : 0.0;
    }
    return 0.0;
  }

  double get perKmRate {
    double rate = 0.0;
    if (tripMode == 1) {
      final pc =
          (selectedExploreCab?['trips'] as List?)
                  ?.firstOrNull?['priceCalculation']
              as List?;
      final vt = selectedVehicle != null ? selectedVehicle!['vehicle_type'] : null;
      final vtId = vt is Map ? vt['_id']?.toString() : vt?.toString();
      final matchedPc = pc?.firstWhereOrNull(
        (x) =>
            x['vehicleId']?.toString() == vtId ||
            x['vehicle_type_id']?.toString() == vtId,
      );
      rate =
          (matchedPc?['per_km_price'] as num?)?.toDouble() ??
          (matchedPc?['perKm'] as num?)?.toDouble() ??
          0.0;
    }
    if (rate <= 0) {
      rate =
          (selectedExploreCab?['per_km_price'] as num?)?.toDouble() ??
          (selectedExploreCab?['perKm'] as num?)?.toDouble() ??
          0.0;
    }
    return rate;
  }

  double get extraKMsCharge {
    final extraKm = currentExtraKm;
    if (extraKm <= 0) return 0.0;
    return (extraKm * perKmRate).roundToDouble();
  }

  /// Recalculates driving distance using Google Maps when user selects pickup/drop address
  Future<void> recalculateRouteDistance() async {
    if (tripMode == 2) return; // Skip local rental
    final pickupAddress = pickupController.text.trim();
    final dropAddress = dropController.text.trim();

    if (pickupAddress.isEmpty || dropAddress.isEmpty) return;

    isCalculatingDistance = true;
    update();

    try {
      final dist = await GooglePlacesHelper.calculateDrivingDistance(
        origin: pickupAddress,
        destination: dropAddress,
        originLat: modifiedPickupLat,
        originLng: modifiedPickupLng,
        destLat: modifiedDropLat,
        destLng: modifiedDropLng,
        apiKey: StringConstants.gpooglePlaceKey,
      );

      if (dist != null && dist > 0) {
        calculatedDistanceKm = dist;
        print('[RouteDistance] Recalculated distance: $calculatedDistanceKm KM');
      }
    } catch (e) {
      print('[RouteDistance] Error calculating distance: $e');
    } finally {
      isCalculatingDistance = false;
      updateTotalFare();
      update();
    }
  }

  double get specialServicesTotal {
    return selectedServiceIds.fold(0.0, (sum, id) {
      final svc = specialServices.firstWhereOrNull((s) => s['_id'] == id);
      final amt = (svc?['amount'] is num)
          ? (svc!['amount'] as num).toDouble()
          : (num.tryParse(svc?['amount']?.toString() ?? '0') ?? 0.0);
      return sum + amt;
    });
  }

  double get preTaxFare {
    return displayBaseFare + extraKMsCharge + specialServicesTotal;
  }

  double get discountAmountComputed {
    double discountAmount = 0.0;
    if (selectedOffer != null) {
      if (selectedOffer?['discount_type'] == '%') {
        discountAmount = preTaxFare * (discountValue / 100);
      } else {
        discountAmount = discountValue;
      }
    }
    return discountAmount;
  }

  double get gstAmount {
    double farePostDiscount = preTaxFare - discountAmountComputed;
    double gp = gstPercent;
    return gp > 0 ? (farePostDiscount * gp / 100).round().toDouble() : 0.0;
  }

  double get gstPercent {
    return (selectedExploreCab?['gst_percent'] as num?)?.toDouble() ?? 0.0;
  }

  // ------------------------------------------------------------------------
  // RECONSTRUCTED RAZORPAY METHODS
  // ------------------------------------------------------------------------

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    // Typically call backend to verify or confirm booking
    Utility.showMessage("Payment Successful", MessageType.success, null, "OK");
    // e.g. confirmBooking();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("Payment Error: ${response.code} - ${response.message}");
    Utility.showMessage("Payment Failed", MessageType.error, null, "OK");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
    Utility.showMessage(
      "External Wallet selected",
      MessageType.information,
      null,
      "OK",
    );
  }

  void openRazorpayCheckout() {
    // Basic Razorpay options
    final options = {
      'key':
          'rzp_test_YOUR_KEY_HERE', // Replace with actual key or fetch from env
      'amount': 100 * 100, // 100 INR in paise
      'name': 'BAMBAM CABS',
      'description': 'Booking Payment',
      'prefill': {'contact': '9876543210', 'email': 'test@example.com'},
    };
    try {
      _razorpay.open(options);
    } catch (e, st) {
      print('DEBUG: Exception caught: $e\n$st');
      debugPrint("Error opening razorpay: $e");
    }
  }
}
