import 'dart:async';
import 'dart:convert';
import 'dart:io';


import 'dart:developer';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:bam_bam_user/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_user/domain/repositories/repository.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  ProfileController(this.profilePresenter);

  final ProfilePresenter profilePresenter;

  // controllers already exist...
  GlobalKey<FormState> saveKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();

  String initialPhoneNo = "";
  bool isPhoneAlreadyRegistered = false;
  bool isCheckingPhone = false;
  Timer? _phoneCheckDebounce;

  List<Map<String, dynamic>> stateListMap = [];
  List<String> stateList = [];
  String? selectedState;
  List<String> cityList = [];
  String? selectedCity;
  bool isFetchingStates = false;
  bool isFetchingCities = false;
  bool isDetectingLocation = false;

  // Profile state
  String profileImageUrl = "";
  File? profileImageFile; // local picked image for upload

  String get userName {
    if (fullNameController.text.trim().isNotEmpty) {
      return fullNameController.text.trim();
    }
    try {
      final userJson = Get.find<Repository>().getStringValue(LocalKeys.userDetails);
      if (userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson);
        if (decoded is Map) {
          final name = (decoded['full_name'] ?? decoded['traveler_name'] ?? decoded['name'])?.toString();
          if (name != null && name.trim().isNotEmpty) {
            return name.trim();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  String get userPhone => phoneNumberController.text.trim();

  @override
  void onInit() {
    super.onInit();
    _loadLocalProfile();
    initData();
  }

  void _loadLocalProfile() {
    try {
      final userJson = Get.find<Repository>().getStringValue(LocalKeys.userDetails);
      if (userJson.isNotEmpty) {
        final data = jsonDecode(userJson);
        if (data is Map) {
          final name = (data['full_name'] ?? data['traveler_name'] ?? data['name'])?.toString();
          if (name != null && name.isNotEmpty && fullNameController.text.isEmpty) {
            fullNameController.text = name;
          }
          final img = data['profile_image']?.toString();
          if (img != null && img.isNotEmpty && profileImageUrl.isEmpty) {
            profileImageUrl = img;
          }
          final phone = data['phone_no']?.toString();
          if (phone != null && phone.isNotEmpty) {
            if (phoneNumberController.text.isEmpty) {
              phoneNumberController.text = phone;
            }
            if (initialPhoneNo.isEmpty) {
              initialPhoneNo = phone.trim();
            }
          }
        }
      }
    } catch (_) {}
    update();

  }

  Future<void> initData() async {
    await fetchStates();
    await fetchProfile();
  }

  Future<void> fetchStates() async {
    isFetchingStates = true;
    update();
    try {
      final String baseUrl = ApiWrapper.baseUrl.replaceAll('/user/', '/vendor/common/');
      final uri = Uri.parse('${baseUrl}states/IN');
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        if (body['isSuccess'] == true && body['data'] != null) {
          final List data = body['data'];
          stateListMap = data.map((e) => e as Map<String, dynamic>).toList();
          stateList = stateListMap.map((e) => e['name'].toString().trim()).where((s) => s.isNotEmpty).toSet().toList();
          stateList.sort((a, b) => a.compareTo(b));
        }
      }
    } catch (e) {
      log('Error fetching states: $e');
    }
    isFetchingStates = false;
    update();
  }

  Future<void> fetchCities(String stateName) async {
    selectedState = stateName;
    selectedCity = null;
    cityList = [];
    isFetchingCities = true;
    update();

    String stateCode = "";
    for (var s in stateListMap) {
      if (s['name'].toString().toLowerCase() == stateName.toLowerCase()) {
        stateCode = s['isoCode'].toString();
        break;
      }
    }

    if (stateCode.isNotEmpty) {
      try {
        final String baseUrl = ApiWrapper.baseUrl.replaceAll('/user/', '/vendor/common/');
        final uri = Uri.parse('${baseUrl}cities/IN/$stateCode');
        final response = await ApiWrapper.client
            .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
            .timeout(const Duration(seconds: 30));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final body = jsonDecode(response.body);
          if (body['isSuccess'] == true && body['data'] != null) {
            final List data = body['data'];
            cityList = data
                .map((e) => e['name'].toString().trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();
            cityList.sort((a, b) => a.compareTo(b));
          }
        }
      } catch (e) {
        log('Error fetching cities: $e');
      }
    }

    isFetchingCities = false;
    update();
  }

  Future<void> detectAndFillLocation() async {
    try {
      Utility.showLoader();
      isDetectingLocation = true;
      update();

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Utility.closeLoader();
        isDetectingLocation = false;
        update();
        Utility.showMessage(
          'Location services are disabled. Please enable GPS.',
          MessageType.error,
          null,
          'OK',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        Utility.closeLoader();
        isDetectingLocation = false;
        update();
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
        isDetectingLocation = false;
        update();
        Utility.showMessage(
          'Location permission permanently denied. Please enable it from app settings.',
          MessageType.error,
          null,
          'OK',
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      String detectedState = "";
      String detectedCity = "";
      String detectedPostalCode = "";

      // 1️⃣ Direct Google Maps Geocoding API on UI side
      try {
        final googleUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${StringConstants.gpooglePlaceKey}',
        );
        final gResponse = await ApiWrapper.client
            .get(googleUrl)
            .timeout(const Duration(seconds: 8));

        if (gResponse.statusCode == 200 && gResponse.body.isNotEmpty) {
          final resData = jsonDecode(gResponse.body);
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

            detectedCity = getComp(['locality']).isNotEmpty
                ? getComp(['locality'])
                : getComp(['administrative_area_level_2']);
            detectedState = getComp(['administrative_area_level_1']);
            detectedPostalCode = getComp(['postal_code']);
          }
        }
      } catch (gErr) {
        log("Profile direct Google Geocoding error: $gErr");
      }

      // 2️⃣ Fallback: Placemark from coordinates
      if (detectedState.isEmpty || detectedCity.isEmpty) {
        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            if (detectedState.isEmpty) detectedState = p.administrativeArea ?? "";
            if (detectedCity.isEmpty) detectedCity = p.locality ?? p.subAdministrativeArea ?? "";
            if (detectedPostalCode.isEmpty) detectedPostalCode = p.postalCode ?? "";
          }
        } catch (e) {
          log("Placemark error: $e");
        }
      }

      // 3️⃣ Fallback: Backend reverse-geocode
      if (detectedState.isEmpty || detectedCity.isEmpty) {
        try {
          final uri = Uri.parse('${ApiWrapper.baseUrl}reverse-geocode');
          final response = await ApiWrapper.client
              .post(
                uri,
                body: jsonEncode({
                  'lat': position.latitude,
                  'lng': position.longitude,
                }),
                headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 && response.body.isNotEmpty) {
            final resData = jsonDecode(response.body);
            if (resData is Map && resData['Data'] != null) {
              final data = resData['Data'];
              if (detectedState.isEmpty) detectedState = data['state']?.toString() ?? "";
              if (detectedCity.isEmpty) detectedCity = data['city']?.toString() ?? "";
              if (detectedPostalCode.isEmpty) detectedPostalCode = data['pincode']?.toString() ?? "";
            }
          }
        } catch (e) {
          log("Backend reverse-geocode error: $e");
        }
      }

      if (stateList.isEmpty) {
        await fetchStates();
      }

      if (detectedState.isNotEmpty) {
        String matchedState = detectedState;
        for (var s in stateList) {
          if (s.toLowerCase() == detectedState.toLowerCase() ||
              detectedState.toLowerCase().contains(s.toLowerCase()) ||
              s.toLowerCase().contains(detectedState.toLowerCase())) {
            matchedState = s;
            break;
          }
        }
        selectedState = matchedState;
        await fetchCities(matchedState);
      }

      if (detectedCity.isNotEmpty) {
        selectedCity = detectedCity;
        if (!cityList.contains(detectedCity)) {
          cityList.insert(0, detectedCity);
        }
      }

      if (detectedPostalCode.isNotEmpty) {
        pinCodeController.text = detectedPostalCode;
      }

      Utility.closeLoader();

      if (detectedCity.isNotEmpty || detectedState.isNotEmpty) {
        Utility.showMessage(
          'Location detected: ${detectedCity.isNotEmpty ? detectedCity : detectedState}',
          MessageType.success,
          null,
          'OK',
        );
      } else {
        Utility.showMessage(
          'Unable to detect city/state from current location.',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      Utility.closeLoader();
      Utility.showMessage(
        'Failed to detect location: $e',
        MessageType.error,
        null,
        'OK',
      );
    } finally {
      isDetectingLocation = false;
      update();
    }
  }

  bool _isFetchingProfile = false;
  bool _isFetchingTickets = false;

  /// Fetch profile from server and populate fields
  Future<void> fetchProfile({bool showLoader = true}) async {
    if (_isFetchingProfile) return;
    _isFetchingProfile = true;
    try {
      final res = await profilePresenter.getProfile(showLoader: showLoader);
      if (res.hasError) {
        try {
          final body = jsonDecode(res.data);
          final msg =
              (body is Map && (body['Message'] ?? body['message']) != null)
              ? (body['Message'] ?? body['message']).toString()
              : res.data;
          Utility.showMessage(msg, MessageType.error, null, 'ok');
        } catch (_) {
          Utility.showMessage(res.data, MessageType.error, null, 'ok');
        }
        return;
      }

      final body = jsonDecode(res.data);
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'] as Map<String, dynamic>;

        fullNameController.text = data['full_name']?.toString() ?? '';
        emailController.text = data['email']?.toString() ?? '';
        final fetchedPhone = data['phone_no']?.toString() ?? '';
        phoneNumberController.text = fetchedPhone;
        initialPhoneNo = fetchedPhone.trim();
        isPhoneAlreadyRegistered = false;
        pinCodeController.text = data['zip_code']?.toString() ?? '';

        
        final stateFromApi = data['state']?.toString();
        if (stateFromApi != null && stateFromApi.isNotEmpty) {
           selectedState = stateList.contains(stateFromApi) ? stateFromApi : null;
           if (selectedState != null) {
             await fetchCities(selectedState!);
           }
        }

        final cityFromApi = data['city']?.toString();
        if (cityFromApi != null && cityFromApi.isNotEmpty) {
           selectedCity = cityList.contains(cityFromApi) ? cityFromApi : null;
        }
        
        profileImageUrl = data['profile_image']?.toString() ?? '';

        Get.find<Repository>().saveValue(
          LocalKeys.userDetails,
          jsonEncode(data),
        );
        Get.find<Repository>().saveValue(
          LocalKeys.userId,
          data['_id']?.toString() ?? '',
        );

        if (Get.isRegistered<BottomBarController>()) {
          Get.find<BottomBarController>().refreshUserDetails();
        }

        update();
      }
    } catch (e) {
      Utility.showMessage(
        "Failed to parse profile",
        MessageType.error,
        null,
        'ok',
      );
    } finally {
      _isFetchingProfile = false;
    }
  }

  /// Pick profile image from gallery
  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      profileImageFile = File(picked.path);
      update();
    }
  }

  void onPhoneChanged(String value) {
    update();
    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanInitial = initialPhoneNo.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanPhone.length < 10) {
      if (isPhoneAlreadyRegistered) {
        isPhoneAlreadyRegistered = false;
        update();
      }
      return;
    }

    if (cleanPhone == cleanInitial) {
      if (isPhoneAlreadyRegistered) {
        isPhoneAlreadyRegistered = false;
        update();
      }
      return;
    }

    if (cleanPhone.length == 10) {
      _phoneCheckDebounce?.cancel();
      _phoneCheckDebounce = Timer(const Duration(milliseconds: 350), () async {
        await checkPhoneIfRegistered(cleanPhone);
      });
    }
  }

  Future<void> checkPhoneIfRegistered(String phone) async {
    final cleanInitial = initialPhoneNo.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone == cleanInitial) {
      isPhoneAlreadyRegistered = false;
      update();
      return;
    }

    isCheckingPhone = true;
    update();

    try {
      final response = await profilePresenter.checkPhoneRegistered(phoneNo: phone);
      if (!response.hasError && response.data.isNotEmpty) {
        final body = jsonDecode(response.data);

        if (body is Map && body['Data'] is Map) {
          final isRegistered = body['Data']['is_registered'] == true;
          isPhoneAlreadyRegistered = isRegistered;
        } else if (body is Map && body['is_registered'] == true) {
          isPhoneAlreadyRegistered = true;
        } else {
          isPhoneAlreadyRegistered = false;
        }
      }
    } catch (e) {
      debugPrint("Error checking phone registration: $e");
    } finally {
      isCheckingPhone = false;
      update();
    }
  }

  /// Update profile (calls presenter.updateProfile)
  Future<void> updateProfile() async {
    if (isCheckingPhone) {
      Utility.showMessage("Please wait, checking phone number...", MessageType.information, null, "OK");
      return;
    }

    if (isPhoneAlreadyRegistered) {
      Utility.showMessage(
        "This phone number is already registered with another account.",
        MessageType.error,
        null,
        "OK",
      );
      return;
    }

    if (!saveKey.currentState!.validate()) return;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phoneNo = phoneNumberController.text.trim();
    final country = "India"; // if you have UI field, use it

    final state = selectedState ?? "";
    final city = selectedCity ?? "";
    final zip = pinCodeController.text.trim();

    final res = await profilePresenter.updateProfile(
      fullName: fullName,
      email: email,
      phoneNo: phoneNo,
      country: country,
      state: state,
      city: city,
      zipCode: zip,
      profileImage: profileImageFile,
      showLoader: true,
    );

    if (res.hasError) {
      try {
        final body = jsonDecode(res.data);
        final msg =
            (body is Map && (body['Message'] ?? body['message']) != null)
            ? (body['Message'] ?? body['message']).toString()
            : res.data;
        Utility.showMessage(msg, MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          res.data ?? 'Update failed',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    // success: refresh profile and show message
    try {
      final body = jsonDecode(res.data);
      final msg = (body is Map && (body['Message'] ?? body['message']) != null)
          ? (body['Message'] ?? body['message']).toString()
          : 'Profile updated';
      Utility.showMessage(msg, MessageType.success, null, 'ok');
    } catch (_) {
      Utility.showMessage('Profile updated', MessageType.success, null, 'ok');
    }

    // clear local picked image and refresh server data
    profileImageFile = null;
    await fetchProfile();
    // at end of ProfileController.updateProfile() after await fetchProfile();
    try {
      final bottomBar = Get.find<BottomBarController>();
      bottomBar.refreshUserInfo();
    } catch (_) {}
  }

  void clearController() {
    fullNameController.clear();
    emailController.clear();
    phoneNumberController.clear();
    pinCodeController.clear();
  }

  /// --------------------------------------------------Logout page------------------------------------------------------------------
  void showLogoutDelog(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back(); // close dialog
                        },
                        child: SvgPicture.asset(
                          AssetConstants.ic_cancel,
                          height: Dimens.twentyFive,
                        ),
                      ),
                    ],
                  ),
                  Dimens.boxHeight10,
                  SvgPicture.asset(AssetConstants.logout_bg),
                  Dimens.boxHeight12,
                  Center(
                    child: Text(
                      "Are you sure want to logout?",
                      style: Styles.txtBlackColorW70020,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Dimens.boxHeight30,

                  // ✅ Logout button
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        // Close dialog
                        Get.back();

                        // ✅ Clear saved auth data
                        final repo = Get.find<Repository>();
                        print(
                          'Before delete: ${repo.getStringValue(LocalKeys.authToken)}',
                        );
                        await repo.deleteAllSecuredValues();
                        print(
                          'After delete: ${repo.getStringValue(LocalKeys.authToken)}',
                        );

                        // Optionally clear all secured values (if you want a clean logout)
                        // await repo.deleteAllSecuredValues();

                        // ✅ Navigate to login screen
                        RouteManagement.gotoLoginScreen();

                        // ✅ Optional feedback
                        Utility.showMessage(
                          "You have been logged out successfully.",
                          MessageType.success,
                          null,
                          "OK",
                        );
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
                          "Yes, Logout",
                          style: Styles.whiteColorW40014,
                        ),
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

  /// --------------------------------------------------Support page------------------------------------------------------------------

  TextEditingController ticketsDateController = TextEditingController();
  TextEditingController bookingIDController = TextEditingController();
  TextEditingController ticketDepController = TextEditingController();

  List<String> issueList = [
    "Booking Issue",
    "Payment Issue",
    "Driver Behavior",
    "Vehicle Condition",
    "Cancellation/Refund",
    "App Technical Problem",
    "General Inquiry",
  ];

  String selectedIssue = "Booking Issue";

  File? ticketAttachment; // file selected by user

  // tickets list & pagination state
  List<dynamic> tickets = [];
  int currentPage = 1;
  int perPage = 10;
  bool isLoadingMore = false;
  bool hasMore = true;

  // ticket detail
  Map<String, dynamic>? ticketDetail;

  /// Pick attachment (use image_picker in UI code)
  void setAttachment(File file) {
    ticketAttachment = file;
    update();
  }

  /// Create ticket API
  Future<void> createTicket() async {
    // validate basic fields
    if (bookingIDController.text.trim().isEmpty) {
      Utility.showMessage('Enter Booking ID', MessageType.error, null, 'ok');
      return;
    }
    if (ticketsDateController.text.trim().isEmpty) {
      Utility.showMessage('Select date', MessageType.error, null, 'ok');
      return;
    }
    if (ticketDepController.text.trim().isEmpty) {
      Utility.showMessage('Enter description', MessageType.error, null, 'ok');
      return;
    }

    final response = await profilePresenter.createTicket(
      issueType: selectedIssue,
      description: ticketDepController.text.trim(),
      bookingId: bookingIDController.text.trim(),
      attachment: ticketAttachment,
      showLoader: true,
    );
    fetchTicketsWithoutPagination();
    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message'))
            ? body['message'].toString()
            : response.data;
        Utility.showMessage(msg, MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          'Failed to create ticket',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      final msg = (body is Map && body.containsKey('Message'))
          ? body['Message']
          : 'Ticket created';
      Utility.showMessage(msg.toString(), MessageType.success, null, 'ok');

      // optional: retrieve ticket id from response to navigate to detail
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        final ticketId = data is Map && data.containsKey('ticket_id')
            ? data['ticket_id'].toString()
            : null;
        if (ticketId != null) {
          // navigate to ticket details page, or refresh list
          RouteManagement.gotoTicketDetilesScreen(); // or pass id if your route accepts it
        } else {
          // just pop
          Get.back();
        }
      } else {
        Get.back();
      }

      // clear form
      bookingIDController.clear();
      ticketsDateController.clear();
      ticketDepController.clear();
      ticketAttachment = null;
      update();
    } catch (e) {
      Get.back();
      Utility.showMessage('Ticket created', MessageType.success, null, 'ok');
    }
  }

  /// Fetch tickets (without pagination)
  Future<void> fetchTicketsWithoutPagination({
    String search = '',
    String status = '',
    bool showLoader = true,
  }) async {
    if (_isFetchingTickets) return;
    _isFetchingTickets = true;
    try {
      final response = await profilePresenter.listTicketsWithoutPagination(
        search: search,
        status: status,
        showLoader: showLoader,
      );
      if (response.hasError) {
        try {
          final body = jsonDecode(response.data);
          final msg = (body is Map && body.containsKey('message'))
              ? body['message']
              : response.data;
          Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
        } catch (_) {
          Utility.showMessage(
            'Failed to fetch tickets',
            MessageType.error,
            null,
            'ok',
          );
        }
        return;
      }

      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        tickets = List.from(body['Data']);
        update();
      }
    } catch (_) {
    } finally {
      _isFetchingTickets = false;
    }
  }

  /// Fetch tickets with pagination (append)
  Future<void> fetchTicketsWithPagination({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
  }) async {
    if (!hasMore && page != 1) return;

    if (page == 1) {
      tickets = [];
      currentPage = 1;
      hasMore = true;
    } else {
      isLoadingMore = true;
      update();
    }

    final response = await profilePresenter.listTicketsWithPagination(
      page: page,
      limit: limit,
      search: search,
      status: status,
      showLoader: true,
    );

    if (response.hasError) {
      isLoadingMore = false;
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message'))
            ? body['message']
            : response.data;
        Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          'Failed to fetch tickets',
          MessageType.error,
          null,
          'ok',
        );
      }
      update();
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        final items = data is List
            ? data
            : (data is Map && data.containsKey('tickets')
                  ? List.from(data['tickets'])
                  : []);
        if (page == 1) {
          tickets = List.from(items);
        } else {
          tickets.addAll(List.from(items));
        }

        // Simple hasMore calculation: if returned less than limit then no more
        if (items.length < limit) {
          hasMore = false;
        } else {
          hasMore = true;
          currentPage = page;
        }
      }
    } catch (_) {
      // ignore
    } finally {
      isLoadingMore = false;
      update();
    }
  }

  /// View ticket details
  Future<void> fetchTicketDetails(String ticketId) async {
    final response = await profilePresenter.viewTicket(
      ticketId: ticketId,
      showLoader: true,
    );

    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('message'))
            ? body['message']
            : response.data;
        Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          'Failed to load ticket details',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      if (body is Map && body.containsKey('Data')) {
        ticketDetail = body['Data'] is Map
            ? Map<String, dynamic>.from(body['Data'])
            : null;
        update();
      }
    } catch (_) {}
  }

  /// --------------------------------------------------Delete Account------------------------------------------------------------------

  void showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: SvgPicture.asset(
                          AssetConstants.ic_cancel,
                          height: Dimens.twentyFive,
                        ),
                      ),
                    ],
                  ),
                  Dimens.boxHeight10,
                  // Using same icon or a warning icon
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 50,
                    color: Colors.red,
                  ),
                  Dimens.boxHeight12,
                  Center(
                    child: Text(
                      "Delete Account?",
                      style: Styles.txtBlackColorW70020,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Dimens.boxHeight10,
                  Center(
                    child: Text(
                      "Are you sure you want to delete your account? This action is irreversible and all your data will be removed.",
                      style: Styles.txtBlackColorW40014,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Dimens.boxHeight30,

                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // close dialog
                        await _performDeleteAccount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Red for danger
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimens.twenty),
                        ),
                      ),
                      child: Padding(
                        padding: Dimens.edgeInsets24_10_24_10,
                        child: Text(
                          "Yes, Delete",
                          style: Styles.whiteColorW60016, // White text
                        ),
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

  Future<void> _performDeleteAccount() async {
    final response = await profilePresenter.deleteAccount(showLoader: true);

    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg =
            (body is Map && (body['Message'] ?? body['message']) != null)
            ? (body['Message'] ?? body['message']).toString()
            : response.data;
        Utility.showMessage(msg, MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          response.data ?? 'Failed to delete account',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    // Success
    try {
      final body = jsonDecode(response.data);
      final msg = (body is Map && (body['Message'] ?? body['message']) != null)
          ? (body['Message'] ?? body['message']).toString()
          : 'Account deleted successfully';
      Utility.showMessage(msg, MessageType.success, null, 'ok');
    } catch (_) {
      Utility.showMessage(
        'Account deleted successfully',
        MessageType.success,
        null,
        'ok',
      );
    }

    // Clear local data and logout
    final repo = Get.find<Repository>();
    await repo.deleteAllSecuredValues();
    RouteManagement.gotoLoginScreen();
  }

  @override
  void onClose() {
    _phoneCheckDebounce?.cancel();
    super.onClose();
  }
}

