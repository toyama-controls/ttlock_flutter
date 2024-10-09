import 'dart:async';

import 'package:ttlock_flutter/smart_lock_error.dart';
import 'package:ttlock_flutter/tt_gateway_connection.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';

class SmartLock {
  static StreamController<TTLockScanModel> _lockScanController =
      StreamController.broadcast();
  static Stream<TTLockScanModel> get lockScanStream =>
      _lockScanController.stream;

  static StreamController<TTGatewayScanModel> _gatewayScanController =
      StreamController.broadcast();
  static Stream<TTGatewayScanModel> get gatewayScanStream =>
      _gatewayScanController.stream;

  static StreamController<TTWifiInfoModel> _wifiInfoController =
      StreamController.broadcast();
  static Stream<TTWifiInfoModel> get wifiInfoStream =>
      _wifiInfoController.stream;
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

  static Future<Stream<TTLockScanModel>> startLockScan() async {
    TTLock.startScanLock((scanModel) {
      _lockScanController.add(scanModel);
    });
    return lockScanStream;
  }

  static Future<void> stopLockScan() async {
    TTLock.stopScanLock();
  }

  static Future<Stream<TTGatewayScanModel>> startGatewayScan() async {
    TTGateway.startScan((TTGatewayScanModel scanModel) {
      _gatewayScanController.add(scanModel);
    });
    return gatewayScanStream;
  }

  static Future<void> stopGatewayScan() async {
    TTGateway.stopScan();
  }

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

  static Future<TtGatewayConnection> createGatewayConnection(String mac) async {
    return TtGatewayConnection(mac);
  }

  static Future<bool> initGateway(
      {required String macAddress,
      required String wifiName,
      required String wifiPassword,
      required String uid,
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

  static Future<void> disconnectGateway(String mac) async {
    TTGateway.disconnect(
      mac,
      () {},
    );
  }

  static Future<List<dynamic>> startWifiScan({required String lockData}) async {
    Completer<List<dynamic>> completer = Completer();
    TTLock.scanWifi(lockData, (hasFinished, wifiList) {
      if (hasFinished) {
        completer.complete(wifiList);
      }
    }, (errCode, errMessage) {
      throw SmartLockException(errorMessage: errMessage, errCode: errCode.name);
    });
    return completer.future;
  }

  static Future<void> configWifi(
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
