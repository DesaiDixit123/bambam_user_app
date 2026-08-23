//   final HomePresenter bottomBarPresenter;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:developer';

import 'package:bam_bam_user/domain/models/response_model.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/data.dart';
import 'package:bam_bam_user/app/navigators/routes_management.dart';
import 'package:bam_bam_user/app/pages/pages.dart';
import 'package:bam_bam_user/app/utils/utility.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:bam_bam_user/domain/repositories/local_storage_keys.dart';
import 'package:bam_bam_user/domain/repositories/repository.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bam_bam_user/device/notification_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthController extends GetxController {
  AuthController(this.authPresenter);
  final AuthPresenter authPresenter;

  File? profileImageFile;
  final RxInt resendCooldown = 0.obs; // seconds remaining for cooldown
  Timer? _resendTimer;

  // v6 stable API — works reliably on both Android and iOS
  late final GoogleSignIn _googleSignIn;
  bool isSigningIn = false;

  // Web/server client ID — required to get idToken on Android
  static const String SERVER_CLIENT_ID =
      '278955640717-7bge7bg04luqclsg37ho0heorvh076ju.apps.googleusercontent.com';

  @override
  void onInit() {
    super.onInit();
    // v6: construct GoogleSignIn with serverClientId so Android gets an idToken
    _googleSignIn = GoogleSignIn(
      serverClientId: SERVER_CLIENT_ID,
      scopes: ['openid', 'email', 'profile'],
    );
    fetchStates();
  }

  Future<void> signInWithFacebook({
    required bool isSignup,
    bool showLoader = true,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final token = accessToken.tokenString;

        final profile = await FacebookAuth.instance.getUserData(
          fields: "name,email,picture.width(200)",
        );
        debugPrint('FB profile: $profile');

        final backendRes = await _sendFacebookTokenToBackend(
          accessToken: token,
          isSignup: isSignup,
          showLoader: showLoader,
        );

        if (backendRes == null) {
          debugPrint('Facebook backend response was null');
          Utility.showMessage(
            'Failed to contact server. Please try again.',
            MessageType.error,
            null,
            'OK',
          );
          return;
        }

        if (backendRes.hasError) {
          try {
            final body = jsonDecode(backendRes.data);
            Utility.showMessage(
              body['Message'] ?? 'Authentication failed',
              MessageType.error,
              null,
              'OK',
            );
          } catch (_) {
            Utility.showMessage(
              'Authentication failed',
              MessageType.error,
              null,
              'OK',
            );
          }
          return;
        }

        final body = jsonDecode(backendRes.data);
        if (body['IsSuccess'] == true && body['Data'] != null) {
          final data = body['Data'];
          Utility.showMessage(
            body['Message'] ?? 'Logged in',
            MessageType.success,
            null,
            'OK',
          );
          RouteManagement.gotoBottomBarScreen();
        } else {
          Utility.showMessage(
            body['Message'] ?? 'Facebook authentication failed',
            MessageType.error,
            null,
            'OK',
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        Utility.showMessage(
          'Facebook login cancelled',
          MessageType.information,
          null,
          'OK',
        );
      } else {
        Utility.showMessage(
          'Facebook login failed: ${result.message}',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e) {
      debugPrint('Facebook login error: $e');
      Utility.showMessage(
        'Facebook login error',
        MessageType.error,
        null,
        'OK',
      );
    }
  }

  Future<ResponseModel?> _sendFacebookTokenToBackend({
    required String accessToken,
    required bool isSignup,
    bool showLoader = true,
  }) async {
    final api = ApiWrapper();
    final endpoint = isSignup ? 'facebook-signup' : 'facebook-login';

    final headers = Utility.commonHeader(isDefaultAuthorizationKeyAdd: false);
    final fcmToken = await NotificationService.getFCMToken();
    final body = {
      'access_token': accessToken,
      if (fcmToken != null) 'fcm_token': fcmToken,
    };

    try {
      final res = await api.makeRequest(
        endpoint,
        Request.post,
        body,
        showLoader,
        headers,
      );

      if (res.data == null) {
        debugPrint('Backend facebook call error: empty response');
        return res;
      }

      final token = _extractTokenFromFacebookResponse(res.data);
      if (token.isNotEmpty) {
        Get.find<Repository>().saveValue(LocalKeys.authToken, token);
      }
      return res;
    } catch (e) {
      debugPrint('Backend facebook call error: $e');
      return null;
    }
  }

  String _extractTokenFromFacebookResponse(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return '';

      final data = decoded['Data'];
      if (data is! Map) return '';

      String token =
          (data['accesstoken'] ??
                  data['accessToken'] ??
                  data['token'] ??
                  data['jwt_token'])
              ?.toString() ??
          '';

      if (token.isEmpty && data['userdetails'] is Map) {
        final userdetails = data['userdetails'] as Map;
        token =
            (userdetails['accesstoken'] ??
                userdetails['accessToken'] ??
                userdetails['jwt_token']) ??
            userdetails['token']?.toString() ??
            '';
      }

      return token;
    } catch (e) {
      debugPrint('Error parsing facebook response for token: $e');
      return '';
    }
  }

  // v6 does not need a separate initialize() call — ready after constructor

  Future<void> signInWithGoogle({required bool isSignup}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    isSigningIn = true;
    update();

    try {
      // Sign out first to always show the account picker fresh
      await _googleSignIn.signOut();

      // v6 API: call signIn() — shows account picker
      final GoogleSignInAccount? user = await _googleSignIn.signIn();

      if (user == null) {
        // User cancelled the picker
        isSigningIn = false;
        update();
        return;
      }

      // Get the auth credentials
      final GoogleSignInAuthentication auth = await user.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      debugPrint('Google user email: ${user.email}');
      debugPrint('Google idToken null: ${idToken == null}');
      debugPrint('Google accessToken null: ${accessToken == null}');
      debugPrint('Google serverAuthCode: ${user.serverAuthCode}');

      // Use FirebaseAuth to verify the credential (handles SHA issues)
      String? firebaseIdToken;
      try {
        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        firebaseIdToken =
            await userCredential.user?.getIdToken();
        debugPrint('Firebase idToken obtained: ${firebaseIdToken != null}');
      } catch (firebaseErr) {
        debugPrint('Firebase sign-in error (will use google token directly): $firebaseErr');
        // Fall through — use the Google idToken directly
      }

      final fcmToken = await NotificationService.getFCMToken();
      final Map<String, dynamic> payload = {
        'id_token': firebaseIdToken ?? idToken ?? user.serverAuthCode ?? accessToken ?? '',
        'email': user.email,
        'full_name': user.displayName ?? '',
        'profile_image': user.photoUrl ?? '',
        if (fcmToken != null) 'fcm_token': fcmToken,
      };

      final String path = isSignup
          ? '${ApiWrapper.baseUrl}google-Auth'
          : '${ApiWrapper.baseUrl}google-login-mobile';

      debugPrint('Google SignIn Payload: $payload');
      final res = await _postToBackend(path, payload);
      debugPrint('Google SignIn Response: $res');

      if ((res['IsSuccess'] == true) || (res['Status'] == 200)) {
        final data = res['Data'];
        if (data != null) {
          final token =
              (data['accesstoken'] ??
                      data['accessToken'] ??
                      data['token'] ??
                      data['jwt_token'])
                  ?.toString() ??
              '';
          if (token.isNotEmpty) {
            Get.find<Repository>().saveValue(LocalKeys.authToken, token);
          }
        }
        Utility.showMessage(
          res['Message']?.toString() ?? 'Success',
          MessageType.success,
          null,
          'OK',
        );
        RouteManagement.gotoBottomBarScreen();
      } else {
        Utility.showMessage(
          res['Message']?.toString() ?? 'Google login failed',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e, st) {
      debugPrint('Google sign in failed: $e\n$st');
      Utility.showMessage(
        'Error: $e',
        MessageType.error,
        null,
        'OK',
      );
    } finally {
      isSigningIn = false;
      update();
    }
  }

  Future<Map<String, dynamic>> _postToBackend(
    String url,
    Map<String, dynamic> payload,
  ) async {
    try {
      final headers = Utility.commonHeader(isDefaultAuthorizationKeyAdd: false);
      headers['Content-Type'] = 'application/json';
      final response = await ApiWrapper.client
          .post(Uri.parse(url), headers: headers, body: json.encode(payload))
          .timeout(const Duration(seconds: 30));
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'IsSuccess': false, 'Message': 'Network error', 'Data': null};
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google disconnect failed: $e');
    }
  }

  Future<void> signInWithApple({required bool isSignup}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    isSigningIn = true;
    update();
    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
          );

      final String identityToken = credential.identityToken ?? "";
      final String fullName =
          "${credential.givenName ?? ''} ${credential.familyName ?? ''}".trim();

      final fcmToken = await NotificationService.getFCMToken();

      Map<String, dynamic> payload = {'identityToken': identityToken};

      if (isSignup) {
        payload['fullName'] = fullName.isNotEmpty ? fullName : "Apple User";
      }

      if (fcmToken != null) {
        payload['fcmToken'] = fcmToken;
      }

      log('Apple SignIn Payload: $payload');

      final String path = isSignup
          ? '${ApiWrapper.baseUrl}apple-signup-mobile'
          : '${ApiWrapper.baseUrl}apple-login-mobile';

      final res = await _postToBackend(path, payload);

      log('Apple SignIn Response: $res');

      if ((res['IsSuccess'] == true) || (res['Status'] == 200)) {
        final data = res['Data'];
        if (data != null) {
          final accessToken =
              (data['accesstoken'] ??
                      data['accessToken'] ??
                      data['token'] ??
                      data['jwt_token'])
                  ?.toString() ??
              '';
          if (accessToken.isNotEmpty) {
            Get.find<Repository>().saveValue(LocalKeys.authToken, accessToken);
          }
        }
        Utility.showMessage(
          res['Message']?.toString() ?? 'Success',
          MessageType.success,
          null,
          'OK',
        );
        RouteManagement.gotoBottomBarScreen();
      } else {
        Utility.showMessage(
          res['Message']?.toString() ?? 'Login failed',
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e, st) {
      debugPrint('Apple sign in failed: $e\n$st');
      Utility.showMessage(
        'Apple sign-in failed: $e',
        MessageType.error,
        null,
        'OK',
      );
    } finally {
      isSigningIn = false;
      update();
    }
  }

  void startResendCooldown({int seconds = 30}) {
    _resendTimer?.cancel();
    resendCooldown.value = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value = resendCooldown.value - 1;
      } else {
        timer.cancel();
        _resendTimer = null;
      }
    });
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }

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

  String receivedOtp = "";
  String phoneForOtp = "";

  void setServerOtpAndPhone({required String phone, required String otp}) {
    phoneForOtp = phone;
    receivedOtp = otp;
    update();
  }

  Future<void> sendOtp({required String phone, bool showLoader = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    phoneForOtp = phone;
    update();

    final response = await authPresenter.sendOtp(
      phoneNo: phone,
      showLoader: showLoader,
    );

    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        String message = "Failed to send OTP";
        if (body is Map) {
          if (body['error'] != null && body['error'].toString().isNotEmpty) {
            message = body['error'].toString();
          } else if (body['Message'] != null) {
            message = body['Message'].toString();
          } else if (body['message'] != null) {
            message = body['message'].toString();
          }
        } else if (response.data != null) {
          message = response.data.toString();
        }
        Utility.showMessage(message, MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          response.data ?? 'Failed to send OTP',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      String otp = "";
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        if (data is Map && data.containsKey('otp')) {
          otp = data['otp'].toString();
        }
      }
      receivedOtp = otp;
      update();
      startResendCooldown(seconds: 30);
      RouteManagement.gotoOtpVerifyScreen();
      Future.delayed(const Duration(milliseconds: 300), () {
        Utility.showMessage('OTP sent', MessageType.success, null, 'OK');
      });
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Utility.showMessage('OTP sent', MessageType.success, null, 'OK');
      });
      startResendCooldown(seconds: 30);
      RouteManagement.gotoOtpVerifyScreen();
    }
  }

  Future<void> signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!singUpKey.currentState!.validate()) return;

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phoneNo = phoneNumberController.text.trim();
    final country = "India";
    final state = selectedState.isNotEmpty ? selectedState : "Gujarat";
    final city = selectedCity.isNotEmpty ? selectedCity : "Surat";
    final zipCode = pinCodeController.text.trim();

    final fcmToken = await NotificationService.getFCMToken();

    final response = await authPresenter.signup(
      fullName: fullName,
      email: email,
      phoneNo: phoneNo,
      country: country,
      state: state,
      city: city,
      zipCode: zipCode,
      fcmToken: fcmToken,
      profileImage: profileImageFile,
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
          response.data ?? 'Signup failed',
          MessageType.error,
          null,
          'ok',
        );
      }
      return;
    }

    try {
      final body = jsonDecode(response.data);
      String otp = "";
      if (body is Map && body.containsKey('Data')) {
        final data = body['Data'];
        if (data is Map && data.containsKey('otp')) {
          otp = data['otp'].toString();
        }
      }
      setServerOtpAndPhone(phone: phoneNo, otp: otp);
      RouteManagement.gotoOtpVerifyScreen();
      fullNameController.clear();
      emailController.clear();
    } catch (e) {
      RouteManagement.gotoOtpVerifyScreen();
    }
  }

  Future<void> verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!otpKey.currentState!.validate()) return;

    final otpToVerify = code.trim();
    final phone = phoneForOtp.isNotEmpty
        ? phoneForOtp
        : phoneNumberController.text.trim();

    final fcmToken = await NotificationService.getFCMToken();

    final response = await authPresenter.verifyOtp(
      phoneNo: phone,
      otp: otpToVerify,
      fcmToken: fcmToken,
      showLoader: true,
    );

    if (response.hasError) {
      try {
        final body = jsonDecode(response.data);
        final msg = (body is Map && body.containsKey('Message'))
            ? body['Message']
            : response.data;
        Utility.showMessage(msg.toString(), MessageType.error, null, 'ok');
      } catch (_) {
        Utility.showMessage(
          response.data ?? 'OTP verification failed',
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
        final data = body['Data'] as Map<String, dynamic>;
        final accessToken =
            (data['accesstoken'] ??
                    data['accessToken'] ??
                    data['token'] ??
                    data['jwt_token'])
                ?.toString() ??
            '';
        if (accessToken.isNotEmpty) {
          Get.find<Repository>().saveValue(LocalKeys.authToken, accessToken);
        }

        if (data.containsKey('userdetails') && data['userdetails'] is Map) {
          final userMap = data['userdetails'] as Map<String, dynamic>;
          Get.find<Repository>().saveValue(
            LocalKeys.userId,
            userMap['_id']?.toString() ?? '',
          );
          Get.find<Repository>().saveValue(
            LocalKeys.userDetails,
            jsonEncode(userMap),
          );
        }
      }

      final successMsg = (body['Message'] ?? 'Verified successfully')
          .toString();
      RouteManagement.gotoBottomBarScreen();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Utility.showMessage(successMsg, MessageType.success, null, 'ok');
      });
    } catch (e) {
      Utility.showMessage(
        'Verified successfully',
        MessageType.success,
        null,
        'ok',
      );
      RouteManagement.gotoBottomBarScreen();
    }
  }
  // ---------------------------------------------------------Logain Screen------------------------------------------------------

  bool isLogin = true;
  bool isSignUp = false;

  TextEditingController logainMobileNumberController = TextEditingController();

  // ---------------------------------------------------------SignUP Screen------------------------------------------------------

  void initializeFieldListeners() {
    final controllers = [
      logainMobileNumberController,
      fullNameController,
      emailController,
      phoneNumberController,
      pinCodeController,
    ];

    for (var ctrl in controllers) {
      ctrl.addListener(() {
        update();
      });
    }
  }

  void clearController() {
    logainMobileNumberController.clear();
    fullNameController.clear();
    emailController.clear();
    phoneNumberController.clear();
    pinCodeController.clear();
  }

  GlobalKey<FormState> singUpKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();
  // TextEditingController Controller = TextEditingController();

  List<Map<String, dynamic>> stateListMap = [];
  List<String> stateList = [];
  String selectedState = "";

  List<String> cityList = [];
  String selectedCity = "";

  bool isFetchingStates = false;
  bool isFetchingCities = false;

  Future<void> fetchStates() async {
    isFetchingStates = true;
    update();
    final response = await authPresenter.getStates();
    if (!response.hasError && response.data != null) {
      try {
        final body = jsonDecode(response.data);
        if (body['isSuccess'] == true && body['data'] != null) {
          final List data = body['data'];
          stateListMap = data.map((e) => e as Map<String, dynamic>).toList();
          stateList = stateListMap.map((e) => e['name'].toString()).toList();
          // State is not auto-selected to force user choice
        } else {
          Utility.errorMessage("Failed to load states from server.");
        }
      } catch (e) {
        log('Error parsing states: $e');
        Utility.errorMessage("Failed to load states due to invalid response.");
      }
    } else {
      Utility.errorMessage("Network error: Failed to fetch states.");
    }
    isFetchingStates = false;
    update();
  }

  Future<void> fetchCities(String stateName) async {
    selectedState = stateName;
    selectedCity = "";
    cityList = [];
    isFetchingCities = true;
    update();

    String stateCode = "";
    for (var s in stateListMap) {
      if (s['name'] == stateName) {
        stateCode = s['isoCode'].toString();
        break;
      }
    }

    if (stateCode.isNotEmpty) {
      final response = await authPresenter.getCities(stateCode);
      if (!response.hasError && response.data != null) {
        try {
          final body = jsonDecode(response.data);
          if (body['isSuccess'] == true && body['data'] != null) {
            final List data = body['data'];
            cityList = data.map((e) => e['name'].toString()).toList();
            // City is not auto-selected to force user choice
          } else {
            Utility.errorMessage("Failed to load cities for the selected state.");
          }
        } catch (e) {
          log('Error parsing cities: $e');
          Utility.errorMessage("Failed to parse city data.");
        }
      } else {
        Utility.errorMessage("Network error: Failed to fetch cities.");
      }
    }

    isFetchingCities = false;
    update();
  }

  // ---------------------------------------------------------otp Screen------------------------------------------------------

  String code = "";
  GlobalKey<FormState> otpKey = GlobalKey<FormState>();
}
