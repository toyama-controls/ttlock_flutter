import 'dart:async';

import 'package:ttlock_flutter/enum.dart';
import 'package:ttlock_flutter/smart_lock_models/add_fingerprint_result.dart';
import 'package:ttlock_flutter/smart_lock_models/exceptions/smart_lock_exception.dart';
import 'package:ttlock_flutter/smart_lock_models/fingerprint_progress.dart';
import 'package:ttlock_flutter/tt_gateway_connection.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:ttlock_flutter/smart_lock_models/wifi_scan_result.dart';

class SmartLock {
  /// A thin wrapper over the TTLock SDK.
  /// Uses awaitable Futures over callbacks

  static StreamController<TTLockScanModel> _lockScanController =
      StreamController.broadcast();
  static Stream<TTLockScanModel> get lockScanStream =>
      _lockScanController.stream;

  static StreamController<TTGatewayScanModel> _gatewayScanController =
      StreamController.broadcast();
  static Stream<TTGatewayScanModel> get gatewayScanStream =>
      _gatewayScanController.stream;

  // static StreamController<TTWifiInfoModel> _wifiInfoController =
  //     StreamController.broadcast();
  // static Stream<TTWifiInfoModel> get wifiInfoStream =>
  //     _wifiInfoController.stream;

  /// Start scanning for locks.
  ///
  /// This function returns a [Stream] that emits [TTLockScanModel] objects, which
  /// contain information about the locks that were found.
  ///
  /// The Stream will continue to emit [TTLockScanModel] objects until stopLockScan
  /// is called.
  ///
  /// The Stream will throw a [SmartLockException] if there is an error.
  static Future<Stream<TTLockScanModel>> startLockScan() async {
    TTLock.startScanLock((scanModel) {
      _lockScanController.add(scanModel);
    });
    return lockScanStream;
  }

  /// Initialize lock, given a [TTLockScanModel].
  ///
  /// This function should be called after a lock has been scanned.
  ///
  /// The [TTLockScanModel] should be from the [lockScanStream].
  ///
  /// The returned Future will complete with the lockData.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<String> initLock(TTLockScanModel scanModel) async {
    Completer<String> completer = Completer();
    TTLock.initLock({
      "lockMac": scanModel.lockMac,
      "isInited": scanModel.isInited,
      "lockVersion": scanModel.lockVersion
    }, (String lockData) {
      completer.complete(lockData);
    }, (error, errorMessage) {
      throw SmartLockException(errCode: error.name, errorMessage: errorMessage);
    });
    return completer.future;
  }

  /// Reset a lock.Deletes it's lock data and sets the lock to Setting mode.
  ///
  /// The [lockData] parameter is required to reset the lock.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> resetLock({required String lockData}) async {
    Completer<bool> completer = Completer();
    TTLock.resetLock(lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Stop scanning for locks.
  ///
  /// This function should be called when you want to stop listening for locks.
  ///
  /// The [lockScanStream] will no longer emit [TTLockScanModel] objects until
  /// [startLockScan] is called again.
  ///
  /// The returned Future will complete when the stop operation is successful.
  static Future<void> stopLockScan() async {
    TTLock.stopScanLock();
  }

  /// Unlock a lock with bluetooth.
  ///
  /// The [lockData] parameter is required to unlock the lock.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> unsetLock({required String lockData}) async {
    Completer<bool> completer = Completer();
    TTLock.controlLock(lockData, TTControlAction.unlock,
        (lockTime, electricQuantity, uniqueId) {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Lock a lock with bluetooth.
  ///
  /// The [lockData] parameter is required to lock the lock.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> setLock({required String lockData}) async {
    Completer<bool> completer = Completer();
    TTLock.controlLock(lockData, TTControlAction.lock,
        (lockTime, electricQuantity, uniqueId) {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Set the remote unlock switch state.
  ///
  /// The [lockData] parameter is required to set the remote unlock switch state.
  ///
  /// The [isOn] parameter is required and indicates if the remote unlock is
  /// enabled (true) or disabled (false).
  ///
  /// The returned Future will complete with the updated lock data if the
  /// operation is successful.
  ///
  /// REMINDER: THE UPDATED LOCK DATA SHOULD BE UPLOADED TO THE CLOUD
  /// FOR REMOTE FUNCTION TO WORK PROPERLY
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<String> setLockRemoteUnlockSwitchState(
      {required String lockData, required bool isOn}) async {
    //TODO change isOn on [RemoteUnlockState]
    Completer<String> completer = Completer();
    TTLock.setLockRemoteUnlockSwitchState(isOn, lockData, (lockData) {
      completer.complete(lockData);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });

    return completer.future;
  }

  /// Get the remote unlock switch state.
  ///
  /// The [lockData] parameter is required to get the remote unlock switch state.
  ///
  /// The returned Future will complete with [RemoteUnlockState.ENABLED] if remote
  /// unlock is enabled, [RemoteUnlockState.DISABLED] if remote unlock is disabled.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<RemoteUnlockState> getRemoteUnlockSwitchState(
      String lockData) async {
    final completer = Completer<RemoteUnlockState>();

    TTLock.getLockRemoteUnlockSwitchState(lockData, (isOn) {
      completer.complete(
          isOn ? RemoteUnlockState.ENABLED : RemoteUnlockState.DISABLED);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Set the lock time.
  ///
  /// The [lockData] parameter is required to set the lock time.
  ///
  /// The [timestamp] parameter is required and is the timestamp of the lock time.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> setLockTime(String lockData, int timestamp) async {
    Completer<bool> completer = Completer();
    TTLock.setLockTime(timestamp, lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Get the lock time.
  ///
  /// The [lockData] parameter is required to get the lock time.
  ///
  /// The returned Future will complete with the timestamp of the lock time.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<int> getLockTime(String lockData) async {
    Completer<int> completer = Completer();
    TTLock.getLockTime(lockData, (timestamp) {
      completer.complete(timestamp);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Get the operation log of a lock.
  ///
  /// The [type] parameter is the type of the operation log.
  /// The type can be [TTOperateRecordType.latest] : the latest action of the lock
  /// or [TTOperateRecordType.total] : the total log of the lock.
  ///
  /// The returned Future will complete with the operation log string.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<String> getLockOperateRecord(
      TTOperateRecordType type, String lockData) async {
    final completer = Completer<String>();
    TTLock.getLockOperateRecord(type, lockData, (record) {
      completer.complete(record);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Get the battery level of a lock.
  ///
  /// The [lockData] parameter is required to get the power level.
  ///
  /// The returned Future will complete with the battery level of the lock, in percentage.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<int> getLockPower(String lockData) async {
    final completer = Completer<int>();
    TTLock.getLockPower(lockData, (batteryLevel) {
      completer.complete(batteryLevel);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Set the lock automatic locking periodic time.
  ///
  /// The [duration] and [lockData] parameters are required to set the automatic locking time
  /// for a lock. The duration must be a positive duration.
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> setAutoLockingPeriod(
      {required Duration duration, required String lockData}) async {
    final completer = Completer<bool>();
    TTLock.setLockAutomaticLockingPeriodicTime(duration.inSeconds, lockData,
        () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Create a custom passcode for a lock.
  ///
  /// The [passCode] parameter is required and is the passcode to be created.
  /// The [startDate] and [endDate] parameters are the start and end
  /// dates of the passcode's validity period.
  ///
  /// The [lockData] paramter is the lock data of the target lock.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> setCustomPasscode(
      {required String passCode,
      required DateTime startDate,
      required DateTime endDate,
      required String lockData}) async {
    final completer = Completer<bool>();
    TTLock.createCustomPasscode(passCode, startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch, lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Modify a custom passcode for a lock.
  ///
  /// The [oldPassCode] parameter is the passcode to be modified.
  /// The [newPassCode] parameter is the new passcode to replace the old one.
  /// The [startDate] and [endDate] parameters are the start and end
  /// dates of the new passcode's validity period.
  ///
  /// The [lockData] paramter is the lock data of the target lock.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> modifyPassCode(
      {required String oldPassCode,
      required String newPassCode,
      required DateTime startDate,
      required DateTime endDate,
      required String lockData}) {
    final completer = Completer<bool>();
    TTLock.modifyPasscode(
        oldPassCode,
        newPassCode,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
        lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Delete a custom passcode for a lock.
  ///
  /// The [passCode] parameter is the passcode to be deleted.
  ///
  /// The [lockData] parameter is the lock data of the target lock.
  ///
  /// The returned Future will complete with true if the operation is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> deletePasscode(
      {required String passCode, required String lockData}) async {
    final completer = Completer<bool>();
    TTLock.deletePasscode(passCode, lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Reset all passcodes for a lock.
  ///
  /// The [lockData] parameter is required to reset all passcodes for a lock.
  ///
  /// The returned Future will complete with a string containing the new admin passcode.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<String> resetPassCodes(String lockData) async {
    final completer = Completer<String>();
    TTLock.resetPasscode(lockData, (string) {
      completer.complete(string);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }

  /// Start scanning for gateways.
  ///
  /// This function returns a [Stream] that emits [TTGatewayScanModel] objects, which
  /// contain information about the gateways that were found.
  ///
  /// The Stream will continue to emit [TTGatewayScanModel] objects until stopGatewayScan
  /// is called.
  ///
  /// The Stream will throw a [SmartLockException] if there is an error.
  static Future<Stream<TTGatewayScanModel>> startGatewayScan() async {
    TTGateway.startScan((TTGatewayScanModel scanModel) {
      _gatewayScanController.add(scanModel);
    });
    return gatewayScanStream;
  }

  /// Stop scanning for gateways.
  ///
  /// This function should be called when you want to stop listening for gateways.
  ///
  /// The [gatewayScanStream] will no longer emit [TTGatewayScanModel] objects until
  /// [startGatewayScan] is called again.
  ///
  /// The returned Future will complete when the stop operation is successful.
  static Future<void> stopGatewayScan() async {
    TTGateway.stopScan();
  }

  /// Connect to a gateway.
  ///
  /// This function will attempt to connect to a gateway with the given mac address.
  ///
  /// The returned Future will complete with a boolean indicating whether the
  /// connection was successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> connectGateway(String mac) async {
    Completer<bool> completer = Completer();
    TTGateway.connect(mac, (connectStatus) {
      if (connectStatus == TTGatewayConnectStatus.success) {
        completer.complete(true);
      } else {
        completer.complete(false);
      }
    });
    return completer.future;
  }

  /// Creates a new [TtGatewayConnection] object with the given mac address.
  ///
  /// Use this function to create a new gateway connection object, which can be used to
  /// connect and init the gateway.
  static Future<TtGatewayConnection> createGatewayConnection(String mac) async {
    return TtGatewayConnection(mac);
  }

  /// Initialize a gateway.
  ///
  /// This function will attempt to initialize a gateway with the given mac address,
  /// wifi name, wifi password, user id, user password (md5), and gateway name.
  ///
  /// The returned Future will complete with a boolean indicating whether the
  /// initialization was successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<bool> initGateway(
      {required String macAddress,
      required String wifiName,
      required String wifiPassword,
      required int uid,
      required String userPasswordmd5,
      required String gatewayName}) async {
    Completer<bool> completer = Completer();
    TTGateway.init({
      "mac": macAddress,
      "uid": uid,
      "ttlockLoginPassword": userPasswordmd5,
      "wifi": wifiName,
      "wifiPassword": wifiPassword,
      "gatewayName": gatewayName,
    }, (map) {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
    });
    return completer.future;
  }

  /// Disconnect from a gateway.
  ///
  /// This function will attempt to disconnect from a gateway with the given mac address.
  ///
  /// The returned Future will complete when the disconnection is successful.
  ///
  /// The Future will throw a [SmartLockException] if there is an error.
  static Future<void> disconnectGateway(String mac) async {
    TTGateway.disconnect(
      mac,
      () {},
    );
  }

  static Future<AddFingerprintResult> addFingerPrint(
      {List<TTCycleModel>? cycleModel,
      required DateTime startDate,
      required DateTime endDate,
      required String lockData}) async {
    final progressController =
        StreamController<FingerprintProgress>.broadcast();
    final completer = Completer<String>();
    TTLock.addFingerprint(cycleModel, startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch, lockData, (currentCount, totalCount) {
      progressController.add(FingerprintProgress(
        currentCount: currentCount,
        totalCount: totalCount,
      ));
    }, (fingerprintNumber) {
      completer.complete(fingerprintNumber);
    }, (error, errorMessage) {
      completer.completeError(
          SmartLockException(errorMessage: errorMessage, errCode: error.name));
    });

    return AddFingerprintResult(progressController.stream, completer.future);
  }

  static Future<void> getValidFingerprints(String lockData) async {
    //TODO
    TTLock.getAllValidFingerprints(
        lockData, (fingerprints) {}, (error, errorMessage) {});
  }

  static Future<bool> deleteFingerprint(
      {required String fingerprintNumber, required String lockData}) async {
    Completer<bool> completer = Completer();
    TTLock.deleteFingerprint(fingerprintNumber, lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
    });
    return completer.future;
  }

  static Future<bool> deleteAllFingerprints(String lockData) async {
    Completer<bool> completer = Completer();
    TTLock.clearAllFingerprints(lockData, () {
      completer.complete(true);
    }, (error, errorMessage) {
      completer.complete(false);
    });
    return completer.future;
  }

  static Future<void> modifyFingerprintPeriod() async {
    //TODO
  }

  static Future<List<WifiScanResult>> scanWifi(
      {required String lockData}) async {
    Completer<List<WifiScanResult>> completer = Completer();
    TTLock.scanWifi(lockData, (hasFinished, wifiList) {
      if (hasFinished) {
        completer.complete(WifiScanResult.fromMapList(wifiList));
      }
    }, (errCode, errMessage) {
      throw SmartLockException(errorMessage: errMessage, errCode: errCode.name);
    });
    return completer.future;
  }

  static Future<bool> configWifi(
      {required String wifiName,
      required String wifiPassword,
      required String lockData}) {
    Completer<bool> completer = Completer();
    TTLock.configWifi(wifiName, wifiPassword, lockData, () {
      completer.complete(true);
    }, (errCode, errMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errMessage, errCode: errCode.name);
    });
    return completer.future;
  }

  static Future<bool> configWifiServer(
      {required String lockData,
      required String serverIp,
      required String port}) {
    Completer<bool> completer = Completer();
    TTLock.configServer(serverIp, port, lockData, () {
      completer.complete(true);
    }, (errCode, errMessage) {
      completer.complete(false);
      throw SmartLockException(errorMessage: errMessage, errCode: errCode.name);
    });
    return completer.future;
  }

  static Future<TTWifiInfoModel> getWifiInfo({required String lockData}) async {
    Completer<TTWifiInfoModel> completer = Completer();
    TTLock.getWifiInfo(lockData, (wifiInfoModel) {
      completer.complete(wifiInfoModel);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
    });
    return completer.future;
  }
}
