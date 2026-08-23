// coverage:ignore-file
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/data/data.dart';
import 'package:bam_bam_user/device/device.dart';
import 'package:bam_bam_user/domain/domain.dart';

/// Repositories that communicate with the platform e.g. GPS
class DeviceRepository extends DomainRepository {
  /// initialize flutter secure storage
  final _flutterSecureStorage = const FlutterSecureStorage();

  /// initialize the hive box
  Future<void> init({bool isTest = false}) async {
    if (isTest) {
      Hive.init('HIVE_TEST');
      await Hive.openBox<dynamic>(StringConstants.appName);
    } else {
      await Hive.initFlutter();
      await Hive.openBox<dynamic>(StringConstants.appName);
    }
  }

  /// Returns the box in which the data is stored.
  Box _getBox() => Hive.box<dynamic>(StringConstants.appName);

  @override
  void clearData(dynamic key) {
    _getBox().delete(key);
  }

  /// Delete the box
  @override
  void deleteBox() {
    Hive.box<void>(StringConstants.appName).clear();
  }

  /// returns stored string value
  @override
  String getStringValue(String key) {
    var box = _getBox();
    var defaultValue = '';
    if (key == DeviceConstants.localLang) {
      defaultValue = DataConstants.defaultLang;
    }
    String? value = box.get(key, defaultValue: defaultValue) as String;
    return value;
  }

  /// store the data
  @override
  void saveValue(dynamic key, dynamic value) {
    _getBox().put(key, value);
  }

  /// return bool value
  @override
  bool getBoolValue(String key) =>
      _getBox().get(key, defaultValue: false) as bool;

  /// Get data from secure storage
  @override
  Future<String> getSecuredValue(String key) async {
    try {
      var value = await _flutterSecureStorage.read(key: key);
      if (value == null || value.isEmpty) {
        value = '';
      }
      return value;
    } catch (error) {
      return '';
    }
  }

  /// Save data in secure storage
  @override
  void saveValueSecurely(String key, String value) {
    _flutterSecureStorage.write(key: key, value: value);
  }

  /// Delete data from secure storage
  @override
  void deleteSecuredValue(String key) {
    _flutterSecureStorage.delete(key: key);
  }

  /// Delete all data from secure storage
  /// Delete all data from secure storage AND Hive (local) storage.
  @override
  Future<void> deleteAllSecuredValues() async {
    try {
      // Clear FlutterSecureStorage (async)
      await _flutterSecureStorage.deleteAll();
    } catch (e) {
      print('Error clearing secure storage: $e');
    }

    try {
      // Clear Hive box (this is synchronous)
      final box = _getBox();
      await box.clear(); // Box.clear returns Future in Hive >=2.0
    } catch (e) {
      print('Error clearing hive box: $e');
    }
  }

  /// API to get the IP of the user
  @override
  Future<String> getIp() {
    throw UnimplementedError();
  }

  @override
  Future<ResponseModel> getNotifications() {
    throw UnimplementedError();
  }
}
