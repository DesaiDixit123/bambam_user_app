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
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bam_bam_user/device/notification_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
    if (Get.arguments != null && Get.arguments is String && (Get.arguments as String).isNotEmpty) {
      phoneForOtp = Get.arguments as String;
    }
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
    debugPrint('👉 signInWithFacebook triggered! isSignup: $isSignup');
    isSigningIn = true;
    update();
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
        'Facebook login error: $e',
        MessageType.error,
        null,
        'OK',
      );
    } finally {
      isSigningIn = false;
      update();
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
    debugPrint('👉 signInWithGoogle triggered! isSignup: $isSignup');
    isSigningIn = true;
    update();

    try {
      // Sign out first with timeout so it never blocks or hangs
      try {
        await _googleSignIn.signOut().timeout(const Duration(seconds: 1));
      } catch (signOutErr) {
        debugPrint('Google signOut ignored/failed: $signOutErr');
      }

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
      final String tokenToSend = (idToken != null && idToken.isNotEmpty)
          ? idToken
          : (firebaseIdToken ?? user.serverAuthCode ?? accessToken ?? '');
      debugPrint('Sending token to backend (length: ${tokenToSend.length}, isGoogleIdToken: ${tokenToSend == idToken})');

      final Map<String, dynamic> payload = {
        'id_token': tokenToSend,
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

          Map<String, dynamic> userMap = {};
          if (data is Map) {
            if (data['userdetails'] is Map) {
              userMap = Map<String, dynamic>.from(data['userdetails']);
            } else if (data['user'] is Map) {
              userMap = Map<String, dynamic>.from(data['user']);
            } else if (data['userData'] is Map) {
              userMap = Map<String, dynamic>.from(data['userData']);
            }
          }
          if (userMap.isEmpty || (userMap['full_name']?.toString().isEmpty ?? true)) {
            userMap['full_name'] = user.displayName ?? '';
            userMap['email'] = user.email;
            userMap['profile_image'] = user.photoUrl ?? '';
          }
          Get.find<Repository>().saveValue(
            LocalKeys.userDetails,
            jsonEncode(userMap),
          );
          if (userMap.containsKey('_id')) {
            Get.find<Repository>().saveValue(
              LocalKeys.userId,
              userMap['_id']?.toString() ?? '',
            );
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
        final errorMsg = res['Message'] ?? res['message'] ?? res['error'] ?? 'Google login failed. Please try again.';
        Utility.showMessage(
          errorMsg.toString(),
          MessageType.error,
          null,
          'OK',
        );
      }
    } catch (e, st) {
      debugPrint('Google sign in failed: $e\n$st');
      final readableMsg = _parseGoogleSignInError(e);
      if (readableMsg.isNotEmpty) {
        Utility.showMessage(
          readableMsg,
          MessageType.error,
          null,
          'OK',
        );
      }
    } finally {
      isSigningIn = false;
      update();
    }
  }

  String _parseGoogleSignInError(dynamic error) {
    final errStr = error.toString();
    if (errStr.contains('ApiException: 10') || errStr.contains(': 10:')) {
      return "Google Sign-In Error (Code 10): SHA-1 Fingerprint is not added in Firebase Console for this device.";
    } else if (errStr.contains('ApiException: 12500') || errStr.contains(': 12500:')) {
      return "Google Sign-In Error (Code 12500): Google Play Services error or unauthorized account.";
    } else if (errStr.contains('ApiException: 7') || errStr.toLowerCase().contains('network')) {
      return "Network error: Unable to connect to Google Services. Please check your internet connection.";
    } else if (error is PlatformException) {
      if (error.code == 'sign_in_canceled' || (error.message?.toLowerCase().contains('cancel') ?? false)) {
        return ""; // User cancelled account picker
      }
      return error.message?.isNotEmpty == true
          ? error.message!
          : "Google Sign-In failed (${error.code})";
    }
    return "Google Sign-In failed. Please try again.";
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
      if (response.body.isEmpty) {
        return {'IsSuccess': false, 'Message': 'Empty response from server', 'Data': null};
      }
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        return {'IsSuccess': false, 'Message': 'Invalid response format from server', 'Data': null};
      } catch (jsonErr) {
        return {'IsSuccess': false, 'Message': 'Server error (${response.statusCode})', 'Data': null};
      }
    } catch (e) {
      return {'IsSuccess': false, 'Message': 'Network error: Please check your internet connection', 'Data': null};
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
    _phoneCheckDebounce?.cancel();
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
  static String savedPhoneForOtp = "";
  String _phoneForOtp = "";

  String get phoneForOtp {
    if (_phoneForOtp.isNotEmpty) return _phoneForOtp;
    if (savedPhoneForOtp.isNotEmpty) return savedPhoneForOtp;
    if (Get.arguments != null && Get.arguments is String && (Get.arguments as String).isNotEmpty) {
      return Get.arguments as String;
    }
    if (logainMobileNumberController.text.trim().isNotEmpty) {
      return logainMobileNumberController.text.trim();
    }
    if (phoneNumberController.text.trim().isNotEmpty) {
      return phoneNumberController.text.trim();
    }
    return "";
  }

  set phoneForOtp(String val) {
    _phoneForOtp = val;
    savedPhoneForOtp = val;
  }

  void setServerOtpAndPhone({required String phone, required String otp}) {
    phoneForOtp = phone;
    savedPhoneForOtp = phone;
    receivedOtp = otp;
    update();
  }

  Future<void> sendOtp({required String phone, bool showLoader = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    phoneForOtp = phone;
    savedPhoneForOtp = phone;
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
      RouteManagement.gotoOtpVerifyScreen(phone);
      Future.delayed(const Duration(milliseconds: 300), () {
        Utility.showMessage('OTP sent', MessageType.success, null, 'OK');
      });
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Utility.showMessage('OTP sent', MessageType.success, null, 'OK');
      });
      startResendCooldown(seconds: 30);
      RouteManagement.gotoOtpVerifyScreen(phone);
    }
  }

  Future<void> signUp() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final phoneNo = phoneNumberController.text.trim();

    // 1. If already detected as registered, block immediately
    if (isPhoneAlreadyRegistered) {
      Utility.showMessage(
        'This phone number is already registered. Please login.',
        MessageType.error,
        null,
        'OK',
      );
      isLogin = true;
      logainMobileNumberController.text = phoneNo;
      update();
      return;
    }

    if (!singUpKey.currentState!.validate()) return;

    // 2. Pre-check with server before submitting signup
    final checkRes = await authPresenter.checkPhoneRegistered(phoneNo: phoneNo, showLoader: true);
    if (!checkRes.hasError && checkRes.data != null) {
      try {
        final body = jsonDecode(checkRes.data);
        if (body is Map && body['Data'] is Map && body['Data']['is_registered'] == true) {
          isPhoneAlreadyRegistered = true;
          isLogin = true;
          logainMobileNumberController.text = phoneNo;
          update();
          Utility.showMessage(
            'This phone number is already registered. Please login.',
            MessageType.error,
            null,
            'OK',
          );
          return;
        }
      } catch (_) {}
    }

    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final country = "India";
    final state = selectedState.isNotEmpty ? selectedState : "";
    final city = selectedCity.isNotEmpty ? selectedCity : "";
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
        final bool isAlreadyRegistered = body is Map && (
          body['is_already_registered'] == true ||
          (body['Data'] is Map && body['Data']['is_already_registered'] == true) ||
          (body['Message'] != null && (
            body['Message'].toString().toLowerCase().contains('already registered') ||
            body['Message'].toString().toLowerCase().contains('already exist')
          )) ||
          (body['message'] != null && (
            body['message'].toString().toLowerCase().contains('already registered') ||
            body['message'].toString().toLowerCase().contains('already exist')
          ))
        );

        if (isAlreadyRegistered) {
          isPhoneAlreadyRegistered = true;
          isLogin = true;
          logainMobileNumberController.text = phoneNo;
          update();

          Utility.showMessage(
            'This phone number is already registered. Please login.',
            MessageType.error,
            null,
            'OK',
          );
          return; // DO NOT SEND OTP!
        }

        final msg = (body is Map && body.containsKey('message'))
            ? body['message']
            : (body is Map && body.containsKey('Message'))
                ? body['Message']
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
      RouteManagement.gotoOtpVerifyScreen(phoneNo);
      fullNameController.clear();
      emailController.clear();
    } catch (e) {
      RouteManagement.gotoOtpVerifyScreen(phoneNo);
    }
  }

  Future<void> verifyOtp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!otpKey.currentState!.validate()) return;

    final otpToVerify = code.trim();
    final phone = phoneForOtp.isNotEmpty
        ? phoneForOtp
        : (savedPhoneForOtp.isNotEmpty
            ? savedPhoneForOtp
            : (logainMobileNumberController.text.trim().isNotEmpty
                ? logainMobileNumberController.text.trim()
                : phoneNumberController.text.trim()));

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
    isPhoneAlreadyRegistered = false;
  }

  GlobalKey<FormState> singUpKey = GlobalKey<FormState>();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController pinCodeController = TextEditingController();

  bool isPhoneAlreadyRegistered = false;
  bool isCheckingPhone = false;
  Timer? _phoneCheckDebounce;

  void onSignupPhoneChanged(String value) {
    update();
    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 10) {
      if (isPhoneAlreadyRegistered) {
        isPhoneAlreadyRegistered = false;
        update();
      }
      return;
    }

    if (cleanPhone.length == 10) {
      _phoneCheckDebounce?.cancel();
      _phoneCheckDebounce = Timer(const Duration(milliseconds: 300), () async {
        await checkPhoneIfRegistered(cleanPhone);
      });
    }
  }

  Future<void> checkPhoneIfRegistered(String phone) async {
    isCheckingPhone = true;
    update();

    try {
      final response = await authPresenter.checkPhoneRegistered(phoneNo: phone);
      if (!response.hasError && response.data != null) {
        final body = jsonDecode(response.data);
        if (body is Map && body['Data'] is Map) {
          final isRegistered = body['Data']['is_registered'] == true;
          isPhoneAlreadyRegistered = isRegistered;
          if (isRegistered) {
            Utility.showMessage(
              "This phone number is already registered. Please login.",
              MessageType.error,
              null,
              "OK",
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking phone registration: $e");
    } finally {
      isCheckingPhone = false;
      update();
    }
  }

  bool get isSignupFormValid {
    if (fullNameController.text.trim().isEmpty) return false;
    final phone = phoneNumberController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length != 10) return false;
    if (isPhoneAlreadyRegistered) return false;
    if (isCheckingPhone) return false;
    if (selectedState.trim().isEmpty) return false;
    if (selectedCity.trim().isEmpty) return false;
    if (emailController.text.trim().isNotEmpty && !GetUtils.isEmail(emailController.text.trim())) {
      return false;
    }
    if (pinCodeController.text.trim().isNotEmpty && pinCodeController.text.trim().length != 6) {
      return false;
    }
    return true;
  }
  // TextEditingController Controller = TextEditingController();

  List<Map<String, dynamic>> stateListMap = [];
  List<String> stateList = [];
  String selectedState = "";

  List<String> cityList = [];
  String selectedCity = "";

  bool isFetchingStates = false;
  bool isFetchingCities = false;

  bool isDetectingLocation = false;

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
          stateList = stateListMap.map((e) => e['name'].toString().trim()).where((s) => s.isNotEmpty).toSet().toList();
          stateList.sort((a, b) => a.compareTo(b));
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
      if (s['name'].toString().toLowerCase() == stateName.toLowerCase()) {
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
            cityList = data
                .map((e) => e['name'].toString().trim())
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList();
            cityList.sort((a, b) => a.compareTo(b));
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

      // 1. Try Reverse Geocoding with placemarks
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
        log("Auth direct Google Geocoding error: $gErr");
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

      // 3️⃣ Fallback: Backend reverse-geocode if needed
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
      log("Error detecting location: $e");
      Utility.showMessage(
        'Failed to detect location: ${e.toString()}',
        MessageType.error,
        null,
        'OK',
      );
    } finally {
      Utility.closeLoader();
      isDetectingLocation = false;
      update();
    }
  }

  // ---------------------------------------------------------otp Screen------------------------------------------------------

  String code = "";
  GlobalKey<FormState> otpKey = GlobalKey<FormState>();
}
