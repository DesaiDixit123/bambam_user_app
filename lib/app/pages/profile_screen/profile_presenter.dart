import 'package:bam_bam_user/domain/domain.dart';

// profile_presenter.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as media_type;
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/data.dart';

class ProfilePresenter {
  ProfilePresenter(ProfileUsecases put);

  final String _base = 'https://apis.bambamcabs.com';

  Future<ResponseModel> getProfile({bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data:
            '{"message":"No internet, please enable mobile data or wi-fi in your phone settings and try again"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_base/user/profile');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final response = await ApiWrapper.client
          .get(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nHeaders :- ${Utility.commonHeader(isDefaultAuthorizationKeyAdd: true)}\nResponse :- ${response.statusCode}\n${response.body}',
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

  Future<ResponseModel> updateProfile({
    required String fullName,
    required String email,
    required String phoneNo,
    required String country,
    required String state,
    required String city,
    required String zipCode,
    File? profileImage,
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

    final uri = Uri.parse('$_base/user/update-profile');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final request = http.MultipartRequest('PUT', uri);

      // add text fields
      request.fields['full_name'] = fullName;
      request.fields['email'] = email;
      request.fields['phone_no'] = phoneNo;
      request.fields['country'] = country;
      request.fields['state'] = state;
      request.fields['city'] = city;
      request.fields['zip_code'] = zipCode;

      // add profile image if available
      if (profileImage != null && await profileImage.exists()) {
        final ext = profileImage.path.split('.').last.toLowerCase();
        final mime = (ext == 'png') ? 'png' : 'jpeg';
        final contentType = media_type.MediaType('image', mime);
        final multipartFile = await http.MultipartFile.fromPath(
          'profile_image',
          profileImage.path,
          contentType: contentType,
        );
        request.files.add(multipartFile);
      }

      // headers - do not set Content-Type; add Authorization via commonHeader(forMultipart:true)
      request.headers.addAll(
        Utility.commonHeader(
          isDefaultAuthorizationKeyAdd: true,
          forMultipart: true,
        ),
      );

      final streamedResponse = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 120));
      final responseString = await streamedResponse.stream.bytesToString();

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nFields :- {full_name,email,phone_no,...}\nHeaders :- ${request.headers}\nStatus: ${streamedResponse.statusCode}\nResponse: $responseString',
      );

      return ResponseModel(
        data: responseString,
        hasError:
            streamedResponse.statusCode < 200 ||
            streamedResponse.statusCode >= 300,
        statusCode: streamedResponse.statusCode,
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

  /// Create support ticket (multipart/form-data). 'attachment' optional.
  Future<ResponseModel> createTicket({
    required String issueType,
    required String description,
    required String bookingId,
    File? attachment,
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

    final uri = Uri.parse('$_base/user/support-ticket/save');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['issue_type'] = issueType;
      request.fields['description'] = description;
      request.fields['booking_id'] = bookingId;

      // Add attachment (field name 'attachment' as shown in Postman)
      if (attachment != null && await attachment.exists()) {
        final ext = attachment.path.split('.').last.toLowerCase();
        final mime = (ext == 'png')
            ? 'png'
            : (ext == 'jpg' || ext == 'jpeg')
            ? 'jpeg'
            : 'octet-stream';
        final contentType = media_type.MediaType('image', mime);
        final multipartFile = await http.MultipartFile.fromPath(
          'attachment',
          attachment.path,
          contentType: contentType,
        );
        request.files.add(multipartFile);
      }

      // Headers (don't set Content-Type here — MultipartRequest sets boundary)
      request.headers.addAll(Utility.commonHeader(forMultipart: true));

      final streamedResponse = await ApiWrapper.client
          .send(request)
          .timeout(const Duration(seconds: 120));

      final responseString = await streamedResponse.stream.bytesToString();

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nFields :- {issue_type, description, booking_id}\nStatusCode :- ${streamedResponse.statusCode}\nResponse :- $responseString',
      );

      return ResponseModel(
        data: responseString,
        hasError:
            streamedResponse.statusCode < 200 ||
            streamedResponse.statusCode >= 300,
        statusCode: streamedResponse.statusCode,
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


  /// View support ticket details (POST JSON with ticket_id)
  Future<ResponseModel> viewTicket({
    required String ticketId,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_base/user/support-ticket/view');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({'ticket_id': ticketId});
      final response = await ApiWrapper.client
          .post(uri, body: body, headers: Utility.commonHeader())
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}',
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

  /// List tickets without pagination (POST JSON {search, status})
  Future<ResponseModel> listTicketsWithoutPagination({
    String search = '',
    String status = '',
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_base/user/support-ticket/list/without/pagination');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({'search': search, 'status': status});
      final response = await ApiWrapper.client
          .post(uri, body: body, headers: Utility.commonHeader())
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}',
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

  /// List tickets with pagination (POST JSON {page, limit, search, status})
  Future<ResponseModel> listTicketsWithPagination({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = '',
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_base/user/support-ticket/list/with/pagination');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final body = jsonEncode({
        'page': page,
        'limit': limit,
        'search': search,
        'status': status,
      });
      final response = await ApiWrapper.client
          .post(uri, body: body, headers: Utility.commonHeader())
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nBody :- $body\nStatus :- ${response.statusCode}\nResponse :- ${response.body}',
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

  /// Delete Account (POST /user/delete-account)
  Future<ResponseModel> deleteAccount({bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_base/user/delete-account');

    if (showLoader) {
      try {
        if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
      } catch (_) {}
      Utility.showLoader();
    }

    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log(
        'URL :- $uri\nStatus :- ${response.statusCode}\nResponse :- ${response.body}',
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
}
