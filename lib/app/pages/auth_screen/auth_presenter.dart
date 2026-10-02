// auth_presenter.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:bam_bam_user/domain/models/response_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as media_type;
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/data.dart';

class AuthPresenter {
  final ApiWrapper apiWrapper;

  AuthPresenter(this.apiWrapper);

  /// Signup request with multipart/form-data
  Future<ResponseModel> signup({
    required String fullName,
    required String email,
    required String phoneNo,
    required String country,
    required String state,
    required String city,
    required String zipCode,
    String? fcmToken,
    File? profileImage,
    bool showLoader = true,
  }) async {
    // check network
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or wi-fi in your phone settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}signup');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final request = http.MultipartRequest('POST', uri);

      // add form fields
      request.fields['full_name'] = fullName;
      request.fields['email'] = email;
      request.fields['phone_no'] = phoneNo;
      request.fields['country'] = country;
      request.fields['state'] = state;
      request.fields['city'] = city;
      request.fields['zip_code'] = zipCode;
      if (fcmToken != null) {
        request.fields['fcm_token'] = fcmToken;
      }

      // add file if provided
      if (profileImage != null && await profileImage.exists()) {
        final ext = profileImage.path.split('.').last.toLowerCase();
        final mimeType = (ext == 'png') ? 'png' : 'jpeg';
        final contentType = media_type.MediaType('image', mimeType);
        final multipartFile = await http.MultipartFile.fromPath(
          'profile_image',
          profileImage.path,
          contentType: contentType,
        );
        request.files.add(multipartFile);
      }

      // headers
      request.headers.addAll(
        Utility.commonHeader(
          isDefaultAuthorizationKeyAdd: false,
          otherHeader: {'Accept': 'application/json'},
        ),
      );

      final streamedResponse = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 120));

      final responseString = await streamedResponse.stream.bytesToString();

      if (showLoader) Utility.closeDialog();

      final statusCode = streamedResponse.statusCode;
      final hasError = statusCode < 200 || statusCode >= 300;

      log(
        'URL :- $uri\nFields :- ${request.fields}\nHeaders :- ${request.headers}\nResponse :-\nStatus Code :- $statusCode\nResponse Data :- $responseString',
      );

      return ResponseModel(
        data: responseString,
        hasError: hasError,
        statusCode: statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      print('Signup error: $e');
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Something went wrong","error":"${e.toString()}"}',
        hasError: true,
      );
    }
  }

  Future<ResponseModel> verifyOtp({
    required String phoneNo,
    required String otp,
    String? fcmToken,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or wi-fi in your phone settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}verify-otp');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({
        'phone_no': phoneNo,
        'otp': otp,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

      final response = await ApiWrapper.client
          .post(
            uri,
            body: body,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nData :- $body\nHeaders :- ${Utility.commonHeader(isDefaultAuthorizationKeyAdd: false)}\nResponse :-\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
      );

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Something went wrong","error":"${e.toString()}"}',
        hasError: true,
      );
    }
  }

  Future<ResponseModel> sendOtp({
    required String phoneNo,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or wi-fi in your phone settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}send-otp');
    print(uri);
    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({'phone_no': phoneNo});

      final response = await ApiWrapper.client
          .post(
            uri,
            body: body,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nData :- $body\nHeaders :- ${Utility.commonHeader(isDefaultAuthorizationKeyAdd: false)}\nResponse :-\nStatus Code :- ${response.statusCode}\nResponse Data :- ${response.body}',
      );

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Something went wrong","error":"${e.toString()}"}',
        hasError: true,
      );
    }
  }

  Future<ResponseModel> checkPhoneRegistered({
    required String phoneNo,
    bool showLoader = false,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet connection"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}check-phone-registered');
    if (showLoader) Utility.showLoader();

    try {
      final body = jsonEncode({'phone_no': phoneNo});
      final response = await ApiWrapper.client
          .post(
            uri,
            body: body,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 15));

      if (showLoader) Utility.closeDialog();

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(
        data: '{"message":"Something went wrong"}',
        hasError: true,
      );
    }
  }

  Future<ResponseModel> getStates() async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet connection"}',
        hasError: true,
        statusCode: 1000,
      );
    }
    final String baseUrl = ApiWrapper.baseUrl.replaceAll('/user/', '/vendor/common/');
    final uri = Uri.parse('${baseUrl}states/IN');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 30));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Something went wrong"}',
        hasError: true,
      );
    }
  }

  Future<ResponseModel> getCities(String stateCode) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet connection"}',
        hasError: true,
        statusCode: 1000,
      );
    }
    final String baseUrl = ApiWrapper.baseUrl.replaceAll('/user/', '/vendor/common/');
    final uri = Uri.parse('${baseUrl}cities/IN/$stateCode');
    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false))
          .timeout(const Duration(seconds: 30));
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ResponseModel(
        data: '{"message":"Something went wrong"}',
        hasError: true,
      );
    }
  }
}
