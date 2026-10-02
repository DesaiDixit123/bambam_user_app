import 'dart:async';
import 'dart:convert';
import 'package:bam_bam_user/app/widgets/droup_down_widgets.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/utils/address_search_field.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class BookingHistoryController extends GetxController {
  BookingHistoryController(this.bookingHistoryPresenter);
  final BookingHistoryPresenter bookingHistoryPresenter;
late Razorpay _razorpay;
  bool isLoading = true;
  bool _isFetchingBookings = false;
  String? error;
  List<Map<String, dynamic>> bookings = [];
  String _selectedStatus = 'All'; // Default tab: All
  String get selectedStatus => _selectedStatus; // Public getter for UI

  bool matchesStatus(Map<String, dynamic> b, String targetStatus) {
    final status = (b['booking_status'] ?? '').toString().toLowerCase();
    final target = targetStatus.toLowerCase();
    if (target.isEmpty || target == 'all') return true;

    if (target == 'completed') {
      return status.contains('complete');
    } else if (target == 'pending') {
      return status.contains('pending');
    } else if (target == 'confirmed') {
      return status.contains('confirm') || status.contains('arrived') || status.contains('ongoing');
    } else if (target == 'd & v allocated') {
      return status.contains('alloc');
    } else if (target == 'cancelled') {
      return status.contains('cancel');
    } else if (target == 'expired') {
      return status.contains('expire');
    }
    return status.contains(target);
  }

  int getStatusCount(String status) {
    if (status == 'All') return _allBookings.length;
    return _allBookings.where((b) => matchesStatus(b, status)).length;
  }
  
@override
void onInit() {
  super.onInit();
  _razorpay = Razorpay();
  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
}


  // grouped lists (displayed)
  List<Map<String, dynamic>> confirmed = [];
  List<Map<String, dynamic>> cancelled = [];
  List<Map<String, dynamic>> completed = [];

  // --- master copies to restore after clearing search ---
  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _allConfirmed = [];
  List<Map<String, dynamic>> _allCancelled = [];
  List<Map<String, dynamic>> _allCompleted = [];

  // search state
  Timer? _debounce;
  String _currentSearch = '';

String? _currentBookingId;

void payFullPayment({
  required String bookingId,
  required int amount,
}) {
  _currentBookingId = bookingId;

  var options = {
    'key':  StringConstants.razorPayKey,
    'amount': amount * 100, // ₹ → paise
    'name': 'BamBam Cabs',
    'description': 'Full Payment',
    'prefill': {
      'contact': '',
      'email': '',
    },
  };

  try {
    _razorpay.open(options);
  } catch (e) {
    Utility.showMessage(e.toString(), MessageType.error, null, "OK");
  }
}
void _onPaymentError(PaymentFailureResponse response) {
  Utility.showMessage(
    response.message ?? "Payment cancelled",
    MessageType.error,
    null,
    "OK",
  );
}

void _onPaymentSuccess(PaymentSuccessResponse response) async {
  if (_currentBookingId == null) return;

  final payload = {
    "booking_id": _currentBookingId,
    "razorpay_payment_id": response.paymentId,
  };

  final res = await bookingHistoryPresenter.payFullPayment(payload);

  if (res.hasError) {
    final body = jsonDecode(res.data ?? '{}');
    Utility.showMessage(
      body['Message'] ?? "Payment failed",
      MessageType.error,
      null,
      "OK",
    );
  } else {
    final body = jsonDecode(res.data ?? '{}');
    Utility.showMessage(
      body['Message'] ?? "Payment successful",
      MessageType.success,
      null,
      "OK",
    );

    // 🔥 Refresh booking data
    await fetchBookingDetails(_currentBookingId!);
    await fetchBookings();
  }
}

  Future<void> fetchBookings({bool showLoader = true, String? status}) async {
    if (_isFetchingBookings) return;
    _isFetchingBookings = true;
    try {
      isLoading = true;
      error = null;
      update();
      // If a status is provided, update the filter
      if (status != null) {
        _selectedStatus = status;
      }

      final res = await bookingHistoryPresenter.getUserBookings(showLoader: showLoader);
      if (res.hasError) {
        try {
          final body = jsonDecode(res.data ?? '{}');
          print(body);
          error = (body['Message'] ?? body['message'] ?? 'Failed to load bookings').toString();
        } catch (_) {
          error = res.data ?? 'Failed to load bookings';
        }
        bookings = [];
        _allBookings = [];
        _allConfirmed = [];
        _allCancelled = [];
        _allCompleted = [];
        isLoading = false;
        update();
        return;
      }

      final json = jsonDecode(res.data ?? '{}') as Map<String, dynamic>;
      final data = json['Data'];
      bookings = [];
      if (data is List) {
        bookings = data.map<Map<String, dynamic>>((e) => (e as Map).cast<String, dynamic>()).toList();
      }

      // initialize master copies and displayed lists
      setBookingsFromApi(bookings);

      isLoading = false;
      update();
    } catch (e) {
      isLoading = false;
      error = 'Error: $e';
      bookings = [];
      _allBookings = [];
      _allConfirmed = [];
      _allCancelled = [];
      _allCompleted = [];
      update();
    } finally {
      _isFetchingBookings = false;
    }
  }

  void onStatusChanged(String? status) {
    if (status == null) {
      _selectedStatus = 'All';
    } else {
      _selectedStatus = status;
    }
    _applyFilter(_currentSearch);
  }

  /// Initialize master lists and compute displayed groups
  void setBookingsFromApi(List<Map<String, dynamic>> fetched) {
    _allBookings = List<Map<String, dynamic>>.from(fetched);
    // Sort by latest booking (newest booking ID / date at the top, oldest at bottom)
    _allBookings.sort((a, b) {
      final dtA = DateTime.tryParse((a['createdAt'] ?? '').toString()) ?? DateTime(1970);
      final dtB = DateTime.tryParse((b['createdAt'] ?? '').toString()) ?? DateTime(1970);

      final dtComp = dtB.compareTo(dtA);
      if (dtComp != 0) return dtComp;

      final idA = (a['booking_id'] ?? a['_id'] ?? '').toString();
      final idB = (b['booking_id'] ?? b['_id'] ?? '').toString();
      return idB.compareTo(idA);
    });
    // compute master categorized lists
 _allConfirmed = _allBookings.where((b) {
  final s = (b['booking_status'] ?? '').toString().toLowerCase();

  // Booking still active
  return s.contains("confirm") ||
         s.contains("allocated") ||     // "D & V Allocated"
         s.contains("accept") ||        // "Accepted"
         s.contains("driver") ||        // Driver allocated
         s.contains("vehicle") ||       // Vehicle allocated
         s.contains("ongoing") ||
         s.contains("pending") ||       // Pending vendor confirmation
         s.contains("progress");
}).toList();

_allCancelled = _allBookings.where((b) {
  final s = (b['booking_status'] ?? '').toString().toLowerCase();
  return s.contains("cancel") || s.contains("expire");          // User cancelled / system cancelled / expired
}).toList();

_allCompleted = _allBookings.where((b) {
  final s = (b['booking_status'] ?? '').toString().toLowerCase();
  return s.contains("complete");        // Completed, Trip Completed
}).toList();


    // set displayed lists to full master copies
    bookings = List<Map<String, dynamic>>.from(_allBookings);
    confirmed = List<Map<String, dynamic>>.from(_allConfirmed);
    cancelled = List<Map<String, dynamic>>.from(_allCancelled);
    completed = List<Map<String, dynamic>>.from(_allCompleted);

    // if there's an active search, re-apply it
    if (_currentSearch.isNotEmpty) {
      _applyFilter(_currentSearch);
    } else {
      update();
    }
  }

void _groupBookings() {
  confirmed = [];
  cancelled = [];
  completed = [];

  for (final b in bookings) {
    final s = (b['booking_status'] ?? '').toString().toLowerCase();

    if (s.contains("cancel") || s.contains("expire")) {
      cancelled.add(b);
    } 
    else if (s.contains("complete")) {
      completed.add(b);
    } 
    else {
      confirmed.add(b);   // active bookings
    }
  }
}

  // helper extractors (kept as in your original code)
  Map<String, dynamic>? travelDetailsFor(Map<String, dynamic> booking) {
    final td = booking['exploreCabsDetails'] ?? booking['travelDetails'];
    if (td is Map) return td.cast<String, dynamic>();
    return null;
  }
    Map<String, dynamic>? travelDetailssFor(Map<String, dynamic> booking) {
    final td = booking['travelDetails'] ?? booking['travelDetails'];
    if (td is Map) return td.cast<String, dynamic>();
    return null;
  }

  Map<String, dynamic>? vehicleFor(Map<String, dynamic> booking) {
    final v = booking['vehiclesDetails'];
    if (v is Map) return v.cast<String, dynamic>();
    return null;
  }

  // -------------------- SEARCH API --------------------
  /// Called by UI when search text changes (debounced).
  void onSearchChanged(String query) {
    _debounce?.cancel();
    _currentSearch = query;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilter(query);
    });
  }

  void clearSearch() {
    _debounce?.cancel();
    _currentSearch = '';
    // restore from master copies
    bookings = List<Map<String, dynamic>>.from(_allBookings);
    confirmed = List<Map<String, dynamic>>.from(_allConfirmed);
    cancelled = List<Map<String, dynamic>>.from(_allCancelled);
    completed = List<Map<String, dynamic>>.from(_allCompleted);
    update();
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();

    bool matches(Map<String, dynamic> b) {
      try {
        final bookingId = (b['booking_id'] ?? b['_id'] ?? '').toString().toLowerCase();

        final travel = travelDetailsFor(b);
        final tripType = (travel?['trip_type'] ?? '').toString().toLowerCase();
        final from = (travel?['from'] ?? '').toString().toLowerCase();

        String to = '';
        final toRaw = travel?['to'];
        if (toRaw is List) to = toRaw.cast<String>().join(', ').toLowerCase();
        else to = (toRaw ?? '').toString().toLowerCase();

        final dateStr = (travel?['date'] ?? b['createdAt'] ?? '').toString().toLowerCase();
        final pickupTime = (travel?['pickup_time'] ?? '').toString().toLowerCase();

        final vehicle = vehicleFor(b);
        final brand = (vehicle?['brand_name'] ?? '').toString().toLowerCase();
        final vehicleType = vehicle?['vehicle_type'] is Map ? (vehicle!['vehicle_type']['name'] ?? '').toString().toLowerCase() : (vehicle?['vehicle_type'] ?? '').toString().toLowerCase();

        final status = (b['booking_status'] ?? '').toString().toLowerCase();
        final payment = (b['total_payment'] ?? '').toString().toLowerCase();

        final combined = '$bookingId $tripType $from $to $dateStr $pickupTime $brand $vehicleType $status $payment';
        
        final bool matchesQuery = q.isEmpty || combined.contains(q);
        final bool statusMatches = matchesStatus(b, _selectedStatus);

        return matchesQuery && statusMatches;
      } catch (_) {
        return false;
      }
    }

    bookings = _allBookings.where(matches).toList();

    confirmed = bookings.where((b) => matchesStatus(b, 'Confirmed') || matchesStatus(b, 'D & V Allocated') || matchesStatus(b, 'Pending')).toList();
    cancelled = bookings.where((b) => matchesStatus(b, 'Cancelled') || matchesStatus(b, 'Expired')).toList();
    completed = bookings.where((b) => matchesStatus(b, 'Completed') || matchesStatus(b, 'Payment Pending')).toList();

    update();
  }

  // actions (stubbed)
  void onTapViewDetails(Map<String, dynamic> booking) {
    // Navigate to details screen - pass booking via arguments or dedicated route
    // RouteManagement.gotoBookinghistoryDetilesScreen(booking as bool,fa);
  }

  void onTapCancel(Map<String, dynamic> booking) {
    // TODO: show dialog then call cancel endpoint. stub now:
    Utility.showMessage("Cancel tapped", MessageType.information, null, "OK");
  }

  void onTapRebook(Map<String, dynamic> booking) {
    // TODO: Pre-fill booking form and navigate to booking flow
    Utility.showMessage("Book again tapped", MessageType.information, null, "OK");
  }

  void onTapWriteReview(Map<String, dynamic> booking) {
    // show review dialog or route to review screen
    Utility.showMessage("Write review tapped", MessageType.information, null, "OK");
    
  }

  // existing fields...

  // New fields for single booking details screen
  bool bookingLoading = false;
  Map<String, dynamic>? bookingDetails; // parsed Data object after GET
  String? bookingError;
  List<Map<String, dynamic>> cancellationReasons = [];
  String? selectedReasonId;
  String? selectedReasonText;
  double? calculatedDistanceKm;
  bool isCalculatingDistance = false;

  Future<void> _calculateRouteDistanceIfNeeded() async {
    final travel = bookingDetails?['travelDetails'];
    if (travel == null) return;

    // 1. If distance is already saved in database, use it directly!
    final double savedDist = double.tryParse((travel['fare_summary']?['actual_km'] ??
            travel['actual_distance_km'] ??
            travel['fare_summary']?['total_distance_km'] ??
            travel['distance_km'] ??
            travel['distance'] ??
            bookingDetails?['exploreCabsDetails']?['totalKm'] ??
            '')
        .toString()) ?? 0.0;
    if (savedDist > 0) {
      calculatedDistanceKm = savedDist;
      update();
      return;
    }

    final tripType = (travel['trip_type'] ?? '').toString();
    final bool isRoundTrip = tripType.toLowerCase().contains('round');

    final pickup = (travel['pickup_address'] ?? '').toString().trim();
    final dynamic dropRaw = travel['drop_address'];
    String drop = '';
    if (dropRaw is List) {
      drop = dropRaw.where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
    } else if (dropRaw != null) {
      drop = dropRaw.toString().trim();
    }

    if (pickup.isEmpty || drop.isEmpty) return;

    // Check coordinates if available
    double? pLat, pLng, dLat, dLng;
    final pLoc = travel['pickup_location'];
    if (pLoc is Map) {
      pLat = double.tryParse((pLoc['lat'] ?? pLoc['latitude'])?.toString() ?? '');
      pLng = double.tryParse((pLoc['lng'] ?? pLoc['longitude'])?.toString() ?? '');
      if (pLat == null && pLoc['coordinates'] is List && (pLoc['coordinates'] as List).length >= 2) {
        pLng = double.tryParse(pLoc['coordinates'][0].toString());
        pLat = double.tryParse(pLoc['coordinates'][1].toString());
      }
    }
    final dLoc = travel['drop_location'];
    if (dLoc is Map) {
      dLat = double.tryParse((dLoc['lat'] ?? dLoc['latitude'])?.toString() ?? '');
      dLng = double.tryParse((dLoc['lng'] ?? dLoc['longitude'])?.toString() ?? '');
      if (dLat == null && dLoc['coordinates'] is List && (dLoc['coordinates'] as List).length >= 2) {
        dLng = double.tryParse(dLoc['coordinates'][0].toString());
        dLat = double.tryParse(dLoc['coordinates'][1].toString());
      }
    }

    try {
      isCalculatingDistance = true;
      final dist = await GooglePlacesHelper.calculateDrivingDistance(
        origin: pickup,
        destination: drop,
        originLat: (pLat != null && pLat != 0.0) ? pLat : null,
        originLng: (pLng != null && pLng != 0.0) ? pLng : null,
        destLat: (dLat != null && dLat != 0.0) ? dLat : null,
        destLng: (dLng != null && dLng != 0.0) ? dLng : null,
        apiKey: StringConstants.gpooglePlaceKey,
      );
      if (dist != null && dist > 0) {
        calculatedDistanceKm = isRoundTrip ? (dist * 2) : dist;
        update();
      }
    } catch (e) {
      debugPrint("Error calculating booking route distance: $e");
    } finally {
      isCalculatingDistance = false;
      update();
    }
  }

  // ---- Driver Waiting Time Timer ----
  Timer? _waitTimer;
  Timer? _pollTimer;        // Auto-refresh timer for status polling
  String? _pollingBookingId; // Which booking to poll
  int elapsedSeconds = 0;
  int freeWaitingSeconds = 0;
  int chargeableSeconds = 0;
  double accumulatedWaitingCharge = 0.0;

  // Start polling status every 5 seconds when booking is active
  void startStatusPolling(String bookingId) {
    _pollTimer?.cancel();
    _pollingBookingId = bookingId;
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final status = (bookingDetails?['booking_status'] ?? '').toString().toLowerCase();
      // Stop polling if trip is done
      if (status == 'completed' || status.contains('cancel') || status.contains('expire')) {
        stopStatusPolling();
        return;
      }
      fetchBookingDetails(bookingId, isPolling: true);
    });
  }

  void stopStatusPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollingBookingId = null;
  }

  void startWaitingTimer({
    String? overrideStartedAt,
    int? overrideFreeMins,
    double? overrideChargePerMin,
  }) {
    _waitTimer?.cancel();

    // Use override values OR fall back to bookingDetails fields
    final startedAtStr = overrideStartedAt
        ?? bookingDetails?['waiting_timer_started_at']?.toString()
        ?? bookingDetails?['driver_arrived_at']?.toString();

    if (startedAtStr == null || startedAtStr.isEmpty) {
      print('⚠️ startWaitingTimer: no start time, cannot start timer');
      return;
    }

    DateTime startedAt;
    try {
      startedAt = DateTime.parse(startedAtStr).toLocal();
    } catch (e) {
      print('⚠️ startWaitingTimer: parse error $e');
      return;
    }

    final freeMins = overrideFreeMins
        ?? int.tryParse((bookingDetails?['free_waiting_minutes'] ?? 0).toString())
        ?? 0;
    freeWaitingSeconds = freeMins * 60;

    final chargePerMin = overrideChargePerMin
        ?? double.tryParse((bookingDetails?['charge_per_minute'] ?? 0).toString())
        ?? 0.0;

    print('✅ User startWaitingTimer: start=$startedAtStr freeMins=$freeMins charge/min=$chargePerMin');

    _waitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = now.difference(startedAt);
      elapsedSeconds = diff.inSeconds;

      if (elapsedSeconds <= freeWaitingSeconds) {
        chargeableSeconds = 0;
        accumulatedWaitingCharge = 0.0;
      } else {
        chargeableSeconds = elapsedSeconds - freeWaitingSeconds;
        final chargeableMinutes = chargeableSeconds ~/ 60;
        accumulatedWaitingCharge = chargeableMinutes * chargePerMin;
      }
      update();
    });
  }

  void stopWaitingTimer() {
    _waitTimer?.cancel();
    _waitTimer = null;
    elapsedSeconds = 0;
    freeWaitingSeconds = 0;
    chargeableSeconds = 0;
    accumulatedWaitingCharge = 0.0;
    update();
  }

  Future<void> fetchCancellationReasons() async {
    try {
      final res = await bookingHistoryPresenter.getCancellationReasons(showLoader: true);

      if (res.hasError) {
        final body = jsonDecode(res.data ?? '{}');
        Utility.showMessage(
          body['Message'] ?? "Failed to fetch cancellation reasons",
          MessageType.error,
          null,
          "OK",
        );
      } else {
        final body = jsonDecode(res.data ?? '{}');
        cancellationReasons = (body['Data'] as List)
            .map((e) => {
                  '_id': e['_id'],
                  'reason': e['cancellation_reason'],
                })
            .toList();
      }
      update();
    } catch (e) {
      Utility.showMessage("Error: $e", MessageType.error, null, "OK");
    }
  }

  Future<void> fetchBookingDetails(String bookingId, {bool isPolling = false}) async {
    try {
      if (!isPolling && (bookingDetails == null || (bookingDetails?['_id'] != bookingId && bookingDetails?['id'] != bookingId))) {
        bookingLoading = true;
        bookingError = null;
        calculatedDistanceKm = null;
        update();
      }

      final response = await bookingHistoryPresenter.getBookingDetails(
        bookingId,
        showLoader: false,
      );

      bookingLoading = false;

      if (response.hasError) {
        if (!isPolling) {
          final body = jsonDecode(response.data ?? '{}');
          bookingError = body['Message'] ?? 'Failed to fetch booking details';
          bookingDetails = null;
        }
        stopWaitingTimer();
        stopStatusPolling();
      } else {
        final body = jsonDecode(response.data ?? '{}');
        bookingDetails = body['Data'] ?? {};

        final status = (bookingDetails?['booking_status'] ?? '').toString().toLowerCase();

        final fbMap = bookingDetails?['vendorRequestDetails']?['fare_breakdown'] ??
            bookingDetails?['fare_breakdown'];
        final bool hasFbData = status.contains('complete') && fbMap != null;
        if (!hasFbData) {
          _calculateRouteDistanceIfNeeded();
        }

        if (status == 'driver arrived') {
          // Start waiting timer if not already running
          if (_waitTimer == null || !_waitTimer!.isActive) {
            startWaitingTimer();
          }
          // Keep polling so screen stays in sync
          if (_pollTimer == null || !_pollTimer!.isActive) {
            startStatusPolling(bookingId);
          }
        } else if (status == 'completed' || status.contains('cancel') || status.contains('expire')) {
          stopWaitingTimer();
          stopStatusPolling();
        } else {
          stopWaitingTimer();
          // Still poll for active statuses (pending, confirmed, allocated, ongoing)
          if (_pollTimer == null || !_pollTimer!.isActive) {
            startStatusPolling(bookingId);
          }
        }
      }

      update();
    } catch (e) {
      bookingLoading = false;
      if (!isPolling) {
        bookingError = 'Error: $e';
      }
      update();
    }
  }

  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
    required String description,
  }) async {
    try {
      final payload = {
        "bookingId": bookingId,
        "cancellation_reason_id": reason,
        "cancellation_description": description,
      };
 Get.back();
      final res = await bookingHistoryPresenter.cancelBooking(payload);

      if (res.hasError) {
        final body = jsonDecode(res.data ?? '{}');
        Utility.showMessage(
          body['Message'] ?? "Failed to cancel booking",
          MessageType.error,
          null,
          "OK",
        );
      } else {
        final body = jsonDecode(res.data ?? '{}');

        Utility.showMessage(
          body['Message'] ?? "Booking cancelled successfully!",
          MessageType.success,
          null,
          "OK",
        );
        // Reset any status filter to ensure cancelled bookings are visible
        _selectedStatus = '';
        await fetchBookings();
      }
    } catch (e) {
      Utility.showMessage("Error: $e", MessageType.error, null, "OK");
    }
  }


  // convenience getters
  Map<String, dynamic>? get travelDetails => bookingDetails?['travelDetails'] is Map ? (bookingDetails!['travelDetails'] as Map).cast<String, dynamic>() : null;
  Map<String, dynamic>? get vehicleDetails => bookingDetails?['vehiclesDetails'] is Map ? (bookingDetails!['vehiclesDetails'] as Map).cast<String, dynamic>() : null;
  List<dynamic> get specialServicesDetails => (bookingDetails?['specialServicesDetails'] ?? bookingDetails?['SpecialServicesDetails']) is List ? (bookingDetails!['specialServicesDetails'] ?? bookingDetails!['SpecialServicesDetails']) as List<dynamic> : [];

  bool isCancel = false;
  bool isAgainBooking = false;
  bool isReview = false;

  /// ---------------------------------------------------------Booking History Detiles screen ----------------------------------------

  TextEditingController reasonCanacelBooingController = TextEditingController();
  TextEditingController describtionControler = TextEditingController();
  TextEditingController reviewDepControler = TextEditingController();
  GlobalKey<FormState> cancelKey = GlobalKey();

  List<String> reasonCategoryList = [
    "Change of plans",
    "Booked by mistake",
    "Found cheaper option",
    "Other",
    "Delayed travel",
    "Wrong pickup/drop location",
    "Issue with payment",
    "Poor customer reviews",
    "Vehicle not required anymore",
    "Selected wrong date/time",
    "Duplicate booking",
    "Plan postponed",
    "Emergency situation",
    "Personal reasons",
  ];
  List<String> reviewCategoryList = [
    "Very Bad",
    "Bad",
    "Average",
    "Good",
    "Excellent",
  ];

  String? selectdCategory;
  String? selectdRewCategory;





Future<void> submitReview({
  required bool isReview,
  required String bookingId,
  required double tripExp,
  required double driverBehavior,
  required double cleanliness,
  required double punctuality,
  required double comfortSafety,
  required String comment,
}) async {
  try {
    final payload = {
      "bookingId": bookingId,
      "overall_rating": tripExp,
      "driver_behavior": driverBehavior,
      "vehicle_cleanliness": cleanliness,
      "punctuality": punctuality,
      "comfort": comfortSafety,
      "comments": comment,
    };

    final res = await bookingHistoryPresenter.submitReview(isReview,payload);

    if (res.hasError) {
      final body = jsonDecode(res.data ?? '{}');
      Utility.showMessage(
        body['Message'] ?? "Failed to submit review",
        MessageType.error,
        null,
        "OK",
      );
    } else {
      final body = jsonDecode(res.data ?? '{}');
      Utility.showMessage(
        body['Message'] ?? "Review submitted successfully!",
        MessageType.success,
        null,
        "OK",
      );
      Get.back();
    }
  } catch (e) {
    Utility.showMessage("Error: $e", MessageType.error, null, "OK");
  }
}



  void showReviewDialog(BuildContext context, bool isReview) {
  // --------------------------------------------------------
  // FIX 1: Form key MUST be created BEFORE StatefulBuilder
  // --------------------------------------------------------
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --------------------------------------------------------
  // Local rating values
  // --------------------------------------------------------
  double tripExp = (bookingDetails!["review"]["overall_rating"] ?? 0).toDouble();
  double driverBehavior = (bookingDetails!["review"]["driver_behavior"] ?? 0).toDouble();
  double cleanliness = (bookingDetails!["review"]["vehicle_cleanliness"] ?? 0).toDouble();
  double punctuality = (bookingDetails!["review"]["punctuality"] ?? 0).toDouble();
  double comfortSafety = (bookingDetails!["review"]["comfort"] ?? 0).toDouble();

  // Text Controller
  final TextEditingController reviewController = TextEditingController();
reviewController.text = bookingDetails!["review"]["comments"] ?? '';
  // Helper: Rating Label Text
  String getLabel(double rating) {
    if (rating == 0) return "";
    if (rating <= 1) return "Bad";
    if (rating == 2) return "Poor";
    if (rating == 3) return "Neutral";
    if (rating == 4) return "Good";
    return "Excellent";
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Form(
                key: _formKey, // ← FORM KEY WORKS PROPERLY NOW

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --------------------------------------------------------
                      // Close Button
                      // --------------------------------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: SvgPicture.asset(
                              AssetConstants.ic_cancel,
                              height: Dimens.twentyFive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // --------------------------------------------------------
                      // Title
                      // --------------------------------------------------------
                      Center(
                        child: Text(
                          "Give us Rating",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --------------------------------------------------------
                      // Rating Rows
                      // (FIXED: Now stars update correctly)
                      // --------------------------------------------------------
                      buildRatingRow(
                        "How was your trip Experience?",
                        tripExp,
                        (r) => setState(() => tripExp = r),
                        getLabel(tripExp),
                      ),

                      buildRatingRow(
                        "Driver Behavior",
                        driverBehavior,
                        (r) => setState(() => driverBehavior = r),
                        getLabel(driverBehavior),
                      ),

                      buildRatingRow(
                        "Vehicle Cleanliness",
                        cleanliness,
                        (r) => setState(() => cleanliness = r),
                        getLabel(cleanliness),
                      ),

                      buildRatingRow(
                        "Punctuality",
                        punctuality,
                        (r) => setState(() => punctuality = r),
                        getLabel(punctuality),
                      ),

                      buildRatingRow(
                        "Comfort & Safety",
                        comfortSafety,
                        (r) => setState(() => comfortSafety = r),
                        getLabel(comfortSafety),
                      ),

                      const SizedBox(height: 20),

                      // --------------------------------------------------------
                      // Review Text Field (Fixed → Keyboard no longer closes)
                      // --------------------------------------------------------
                      Text(
                        "Share Your Thoughts Below!",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: reviewController,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Review cannot be empty";
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Enter Here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // --------------------------------------------------------
                      // Send Button
                      // --------------------------------------------------------
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            await submitReview(
                              isReview: isReview,
                              bookingId: bookingDetails?['_id'] ?? '',
                              tripExp: tripExp,
                              driverBehavior: driverBehavior,
                              cleanliness: cleanliness,
                              punctuality: punctuality,
                              comfortSafety: comfortSafety,
                              comment: reviewController.text.trim(),
                            );

                            await bookingHistoryPresenter.getBookingDetails(
                              bookingDetails?['_id'] ?? '',
                            );
update();
                            Navigator.pop(context); // close dialog after submit
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 10,
                            ),
                            child: Text(
                              "Send",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  /// Helper Widget for each rating row
  Widget buildRatingRow(
    String title,
    double rating,
    ValueChanged<double> onRatingUpdate,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            RatingBar.builder(
              initialRating: rating,
              minRating: 1,
              glowColor: Colors.orange,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 28,
              itemPadding: const EdgeInsets.symmetric(horizontal: 2),
              itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: onRatingUpdate,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: getLabelColor(label),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void onClose() {
    _waitTimer?.cancel();
    _pollTimer?.cancel();
    _debounce?.cancel();
    reasonCanacelBooingController.dispose();
    describtionControler.dispose();
    reviewDepControler.dispose();
    _razorpay.clear();
    super.onClose();
  }


  /// Color coding for labels
  Color getLabelColor(String label) {
    switch (label) {
      case "Bad":
        return Colors.red;
      case "Poor":
        return Colors.orange;
      case "Neutral":
        return Colors.blue;
      case "Good":
        return Colors.orangeAccent;
      case "Excellent":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

void showBokigCancelDelog(BuildContext context, {String? customBookingId}) async {
  await fetchCancellationReasons(); // ✅ Fetch API list before opening dialog

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
            key: cancelKey,
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
                  // ❌ Close button
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
                    "cancel_booking".tr,
                    style: Styles.txtBlackColorW70020,
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight8,
                  Text(
                    "cancel_dep".tr,
                    style: Styles.txtG5ColorsW40014,
                    textAlign: TextAlign.center,
                  ),
                  Dimens.boxHeight24,

                  // ✅ Dropdown using API data
                  if (cancellationReasons.isNotEmpty)
                    DroupDownButtonWigeat<String>(
                      hintText: "Select reason".tr,
                      items: cancellationReasons.map((r) => r['reason'] as String).toList(),
                      value: selectedReasonText,
                      isTitle: true,
                      borderRadius: BorderRadius.circular(Dimens.twelve),
                      onChanged: (newValue) {
                        selectedReasonText = newValue;
                        selectedReasonId = cancellationReasons
                            .firstWhere((r) => r['reason'] == newValue)['_id'];
                        update();
                      },
                      textStyle: Styles.txtBlackColorW40014,
                      isCompulsory: true,
                      title: "reasonfor_cancllation".tr,
                      hintStyle: Styles.txtG7Colors40014,
                      titleStyle: Styles.black50014,
                      isBorder: true,
                    )
                  else
                    Center(
                      child: Text("No reasons available",
                          style: Styles.txtG5ColorsW40014),
                    ),

                  Dimens.boxHeight20,

                  CustomTextFormField(
                    style: Styles.txtBlackColorW40014,
                    hintText: "enter_here".tr,
                    isBorder: true,
                    isTitle: true,
                    textEditingController: describtionControler,
                    validator: (value) =>
                        value!.isEmpty ? "enter_here".tr : null,
                    isCompulsory: true,
                    title: "description".tr,
                    maxLines: 2,
                    hintStyle: Styles.txtG7Colors40014,
                    titleStyle: Styles.black50014,
                  ),

                  Dimens.boxHeight30,

                  ElevatedButton(
                    onPressed: () async {
                      if (cancelKey.currentState!.validate()) {
                        if (selectedReasonId == null) {
                          Utility.showMessage(
                            "Please select a reason",
                            MessageType.error,
                            null,
                            "OK",
                          );
                          return;
                        }
print(  bookingDetails?['travelDetails']['_id'] ?? '');
  Get.back();
                        await cancelBooking(
                          bookingId:
                              customBookingId ?? bookingDetails?['_id'] ?? '',
                          reason: selectedReasonId!,
                          description: describtionControler.text,
                        );
                      
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
                        "Submit Cancel Request",
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


  void showAgainBookingDelog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevents tap outside to close
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.twenty),
          ),
          child: SingleChildScrollView(
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back();
                          Get.back();
                        },
                        child: SvgPicture.asset(
                          AssetConstants.ic_cancel,
                          height: Dimens.twentyFive,
                        ),
                      ),
                    ],
                  ),
                  Dimens.boxHeight50,
                  SvgPicture.asset(AssetConstants.cancel_imge),
                  Dimens.boxHeight50,

                  Text(
                    "Your Booking is Cancelled!".tr,
                    style: Styles.txtBlackColorW70020,
                    textAlign: TextAlign.center,
                  ),

                  Dimens.boxHeight8,

                  Text(
                    "Your rental booking has been successfully completed. check your rental in booking history."
                        .tr,
                    style: Styles.txtG5ColorsW40014,
                    textAlign: TextAlign.center,
                  ),

                  Dimens.boxHeight30,

                  ElevatedButton(
                    onPressed: () async {
                      RouteManagement.gotoBookinghistoryDetilesScreen(
                        false,
                        true,
                        false,
                      );
                      Get.back();
                      // Get.back();
                      update();
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
                        "Book Again",
                        style: Styles.txtBlackColorW40014,
                      ),
                    ),
                  ),
                  Dimens.boxHeight24,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> updateBookingAddress({
    required String bookingId,
    required String pickupAddress,
    String? dropAddress,
  }) async {
    final payload = {
      "bookingId": bookingId,
      "pickup_address": pickupAddress.trim(),
    };
    if (dropAddress != null && dropAddress.trim().isNotEmpty) {
      payload["drop_address"] = dropAddress.trim();
    }

    final res = await bookingHistoryPresenter.updateBookingAddress(payload);

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data ?? '{}');
        Utility.showMessage(
          body['Message'] ?? "Failed to update address",
          MessageType.error,
          null,
          "OK",
        );
      } catch (_) {
        Utility.showMessage("Failed to update address", MessageType.error, null, "OK");
      }
      return false;
    } else {
      Utility.showMessage("Address updated successfully", MessageType.success, null, "OK");
      return true;
    }
  }

}








  

