// home_presenter.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:bam_bam_user/domain/models/response_model.dart';
import 'package:bam_bam_user/domain/usecases/home_usecases.dart';
import 'package:get/get.dart';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/data.dart';
import 'package:http/http.dart' as http;

class HomePresenter {
  HomePresenter(HomeUsecases put);

  Future<ResponseModel> exploreCabs(
    Map<String, dynamic> body, {
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}explore-cab');

    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();
      log(
        'explore-cab request: $body\nstatus: ${response.statusCode}\nbody: ${response.body}',
      );
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// select vehicle (confirm selection)
  Future<ResponseModel> selectVehicle({
    required String vehicleId,
    required String exploreCabId,
    String? selectedHours,
    String? selectedKm,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}select-vehicle');
    final body = {
      'vehicleId': vehicleId,
      'exploreCabId': exploreCabId,
      if (selectedHours != null) 'selected_hours': selectedHours,
      if (selectedKm != null) 'selected_km': selectedKm,
    };

    bool loaderShown = false;
    try {
      // if (showLoader) {
      //   Utility.showLoader();
      //   loaderShown = true;
      // }

      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      log(
        'select-vehicle request: $body\nstatus: ${response.statusCode}\nbody: ${response.body}',
      );

      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      log('select-vehicle timeout: $body');
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e, st) {
      log('select-vehicle catch: $e\n$st');
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    } finally {
      // always try to close loader but only if we showed it
      try {
        //  if (loaderShown) Utility.closeLoader();
      } catch (e) {
        // defensive: if closeLoader throws, log it but don't crash
        log('Utility.closeLoader() threw: $e');
      }
    }
  }

  /// Get special services list
  Future<ResponseModel> getSpecialServices({bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}special-services');

    try {
      final response = await ApiWrapper.client
          .get(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
          )
          .timeout(const Duration(seconds: 120));

      log(
        'special-services status: ${response.statusCode}\nbody: ${response.body}',
      );
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Get offers / coupons for a vehicle + route
  Future<ResponseModel> getOffers({
    required String vehicleId,
    required String from,
    required String to,
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final query = Uri(
      queryParameters: {'vehicleId': vehicleId, 'from': from, 'to': to},
    ).query;
    final uri = Uri.parse('${ApiWrapper.baseUrl}get-vehicles-offers?$query');

    try {
      final response = await ApiWrapper.client
          .get(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
          )
          .timeout(const Duration(seconds: 120));

      log(
        'offers request: $uri\nstatus: ${response.statusCode}\nbody: ${response.body}',
      );
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      if (showLoader) Utility.closeLoader();
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Process booking (final POST)
  Future<ResponseModel> processBooking(
    Map<String, dynamic> body, {
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }
    final uri = Uri.parse('${ApiWrapper.baseUrl}create-travel-details');

    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      log(
        'book-trip request: $body\nstatus: ${response.statusCode}\nbody: ${response.body}',
      );
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// create booking API wrapper
  Future<ResponseModel> createBooking(
    Map<String, dynamic> body, {
    bool showLoader = true,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}create-booking');

    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();
      log(
        'create-booking request: $body\nstatus: ${response.statusCode}\nbody: ${response.body}',
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
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// calculate airport slab price API wrapper
  Future<ResponseModel> airportCalculateSlabPrice(
    Map<String, dynamic> body, {
    bool showLoader = false,
  }) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}airport/calculate-slab-price');

    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client
          .post(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();
      log(
        'airport/calculate-slab-price request: $body\nstatus: ${response.statusCode}\nbody: ${response.body}',
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
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Fetch homepage reviews (GET: get-homepage-reviews)
  Future<ResponseModel> getHomepageReviews({bool showLoader = false}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}get-homepage-reviews');

    try {
      final response = await ApiWrapper.client
          .get(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: false),
          )
          .timeout(const Duration(seconds: 30));

      log(
        'get-homepage-reviews status: ${response.statusCode}\nbody: ${response.body}',
      );
      return ResponseModel(
        data: response.body,
        hasError: response.statusCode < 200 || response.statusCode >= 300,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      return ResponseModel(
        data: '{"message":"Request timed out"}',
        hasError: true,
      );
    } catch (e) {
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }

  /// Fetch available payment types (GET: get-user-payment-type)
  Future<ResponseModel> getPaymentTypes({bool showLoader = true}) async {
    if (!await Utility.isNetworkAvailable()) {
      return ResponseModel(
        data: '{"message":"No internet"}',
        hasError: true,
        statusCode: 1000,
      );
    }

    final uri = Uri.parse('${ApiWrapper.baseUrl}get-user-payment-type');

    if (showLoader) Utility.showLoader();
    try {
      final response = await ApiWrapper.client
          .get(
            uri,
            headers: Utility.commonHeader(isDefaultAuthorizationKeyAdd: true),
          )
          .timeout(const Duration(seconds: 120));

      if (showLoader) Utility.closeLoader();

      log(
        'get-user-payment-type request: ${uri.toString()}\nstatus: ${response.statusCode}\nbody: ${response.body}',
      );
      print('GET-USER-PAYMENT-TYPE RESPONSE: ${response.body}');
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
      return ResponseModel(data: '{"message":"$e"}', hasError: true);
    }
  }
}
