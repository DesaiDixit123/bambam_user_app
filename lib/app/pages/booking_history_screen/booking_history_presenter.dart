import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:bam_bam_user/app/utils/utility.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:bam_bam_user/domain/domain.dart';

class BookingHistoryPresenter {
  BookingHistoryPresenter(this.bookingHistoryUsecases);
  final BookingHistoryUsecases bookingHistoryUsecases;

  // Base host for APIs used by this presenter
  static const String _host = 'https://apis.bambamcabs.com';
Future<ResponseModel> payFullPayment(
  Map<String, dynamic> payload, {
  bool showLoader = true,
}) async {
  if (!await Utility.isNetworkAvailable()) {
    return ResponseModel(
      data: '{"message":"No internet"}',
      hasError: true,
      statusCode: 1000,
    );
  }

  final uri = Uri.parse('$_host/user/pay-full-payment');
      log('pay-full-payment payload ${payload}\n');
  if (showLoader) Utility.showLoader();

  try {
    final response = await ApiWrapper.client
        .post(
          uri,
          headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 120));

    if (showLoader) Utility.closeLoader();

    return ResponseModel(
      data: response.body,
      hasError: response.statusCode < 200 || response.statusCode >= 300,
      statusCode: response.statusCode,
    );
  } catch (e) {
    if (showLoader) Utility.closeLoader();
    return ResponseModel(
      data: '{"message":"$e"}',
      hasError: true,
    );
  }
}

  /// GET list of user bookings
  Future<ResponseModel> getUserBookings({bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_host/user/get-user-all-booking');

    if (showLoader) Utility.showLoader();

    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();
Utility.closeLoader();
      log('GET get-user-all-booking - status: ${response.statusCode}\nbody: ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
      
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// GET booking details by id
  Future<ResponseModel> getBookingDetails(String id, {bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_host/user/view/booking/$id');

    if (showLoader) Utility.showLoader();

    try {
      final response = await ApiWrapper.client
          .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log('GET view/booking/$id - status: ${response.statusCode}\nbody: ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// POST cancel booking
  /// payload example:
  /// {
  ///   "bookingId": "68e7212e86fac6ddd14edfc1",
  ///   "cancellation_reason": "Change of travel plan",
  ///   "cancellation_description": "I need to postpone my trip to next month."
  /// }
  Future<ResponseModel> cancelBooking(Map<String, dynamic> payload, {bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_host/user/booking/cancelled');

  

    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 120));

    Utility.closeLoader();
  

      log('POST cancel/booking - payload: $payload\nstatus: ${response.statusCode}\nbody: ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

 Future<ResponseModel> getCancellationReasons({bool showLoader = true}) async {
  if (!await Utility.isNetworkAvailable()) {
    return ResponseModel(
      data: '{"message":"No internet"}',
      hasError: true,
      statusCode: 1000,
    );
  }

  final uri = Uri.parse('${ApiWrapper.baseUrl}get-all-cancellation-reason');

  if (showLoader) Utility.showLoader();

  try {
    final response = await ApiWrapper.client
        .get(uri, headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true))
        .timeout(const Duration(seconds: 120));

    if (showLoader) Utility.closeDialog();

    return ResponseModel(
      data: response.body,
      hasError: response.statusCode < 200 || response.statusCode >= 300,
      statusCode: response.statusCode,
    );
  } on TimeoutException catch (_) {
    if (showLoader) Utility.closeDialog();
    return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
  } catch (e) {
    if (showLoader) Utility.closeDialog();
    return ResponseModel(data: '{"message":"$e"}', hasError: true);
  }
}

  Future<ResponseModel> submitReview(bool isReview,Map<String, dynamic> payload, {bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_host${isReview?"/user/booking/complete/submit/review":"/user/booking/complete/update/review"}');

    if (showLoader) Utility.showLoader();

    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeDialog();

      log('POST add/review - payload: $payload\nstatus: ${response.statusCode}\nbody: ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeDialog();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  Future<ResponseModel> updateBookingAddress(Map<String, dynamic> payload, {bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('$_host/user/booking/update-address');

    if (showLoader) Utility.showLoader();

    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log('POST updateBookingAddress - payload: $payload\nstatus: ${response.statusCode}\nbody: ${response.body}');

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"Request timed out"}', hasError: true);
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }
}
