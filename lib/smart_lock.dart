import 'dart:async';

import 'package:ttlock_flutter/smart_lock_error.dart';
import 'package:ttlock_flutter/tt_gateway_connection.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:ttlock_flutter/wifi_scan_result.dart';

class SmartLock {
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
    Completer<String> completer = Completer();
    TTLock.setLockRemoteUnlockSwitchState(isOn, lockData, (lockData) {
      completer.complete(lockData);
    }, (error, errorMessage) {
      throw SmartLockException(errorMessage: errorMessage, errCode: error.name);
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
