import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:bam_bam_user/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_user/domain/repositories/repository.dart';
import 'package:flutter/material.dart';

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

  List<String> cityList = [];
  String? selectedCity;
  List<String> stateList = [];
  String? selectedState;

  // Profile state
  String profileImageUrl = "";
  File? profileImageFile; // local picked image for upload

  @override
  void onInit() {
    super.onInit();
    initData();
  }

  Future<void> initData() async {
    await fetchStates();
    await fetchProfile();
  }

  Future<void> fetchStates() async {
    try {
      final res = await http.get(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/states/q?country=India'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] != null && data['data']['states'] != null) {
          final states = data['data']['states'] as List;
          stateList = states.map((e) => e['name'].toString()).toList();
          update();
        }
      }
    } catch (_) {}
  }

  Future<void> fetchCities(String stateName) async {
    try {
      final res = await http.get(
        Uri.parse('https://countriesnow.space/api/v0.1/countries/state/cities/q?country=India&state=$stateName'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['data'] != null) {
          final cities = data['data'] as List;
          cityList = cities.map((e) => e.toString()).toList();
          update();
        }
      }
    } catch (_) {}
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
        phoneNumberController.text = data['phone_no']?.toString() ?? '';
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

  /// Update profile (calls presenter.updateProfile)
  Future<void> updateProfile() async {
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
}
