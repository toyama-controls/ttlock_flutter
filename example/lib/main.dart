import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ttlock_flutter/smart_lock.dart';
import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, TTLockScanModel> models = {};
  Map<String, TTGatewayScanModel> gateways = {};
  String? lockData;
  int? lockId;
  final _baseUrl = "https://euapi.ttlock.com";
  final _clientId = "f44038e255414ef6b1ef09d81e2d0d8b";

  _uploadLockData(String lockData) async {
    final url = Uri.parse('$_baseUrl/v3/lock/initialize');
    final token = "2cf60fe878f573df8855da97499acd66";
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final body = {
      "clientId": _clientId,
      "accessToken": token,
      "lockData": lockData,
      "date": timestamp.toString()
    };

    String encodedBody = body.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: encodedBody,
    );
    print(response.body);
  }

  _updateLockData(String lockData, int lockId) async {
    final url = Uri.parse('$_baseUrl/v3/lock/updateLockData');
    final token = "2cf60fe878f573df8855da97499acd66";
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final body = {
      "clientId": _clientId,
      "accessToken": token,
      "lockData": lockData,
      "date": timestamp.toString(),
      "lockId": lockId.toString(),
    };

    String encodedBody = body.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: encodedBody,
    );
    print(response.body);
  }

  _queryGatewayInit(String gatewayNetMac) async {
    final url = Uri.parse('$_baseUrl/v3/lock/updateLockData');
    final token = "2cf60fe878f573df8855da97499acd66";
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final body = {
      "clientId": _clientId,
      "accessToken": token,
      "date": timestamp.toString(),
      "gatewayNetMac": gatewayNetMac,
    };

    String encodedBody = body.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: encodedBody,
    );
    print(response.body);
  }

  Future<bool> _requestAndroidPermissions() async {
    final deviceInfo = DeviceInfoPlugin();

    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    if (Platform.isAndroid) {
      if (androidInfo.version.sdkInt >= 31) {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();
      } else {
        await Permission.location.request();
      }
    }

    return await _isAndroidPermissionGranted();
  }

  Future<bool> _isAndroidPermissionGranted() async {
    if (await Permission.location.isGranted ||
        await Permission.bluetoothScan.isGranted) {
      return true;
    }
    return false;
  }

  _initLock(TTLockScanModel scanModel) async {
    if (scanModel.isInited) {
      throw Exception("LOCK NEEDS TO BE IN SETTING MODE");
    }

    var lockData = await SmartLock.initLock(scanModel);
    print("LOCK INIT SUCCESS : $lockData");
    lockData = await SmartLock.setLockRemoteUnlockSwitchState(
        lockData: lockData, isOn: true);
    await _uploadLockData(lockData);

    // TTLock.initLock({
    //   "lockMac": scanModel.lockMac,
    //   "isInited": scanModel.isInited,
    //   "lockVersion": scanModel.lockVersion
    // }, (String lockData) {
    //   print("LOCK DATA: ${lockData}");
    //   this.lockData = lockData;
    //   this._uploadLockData(lockData);
    //   TTLock.setLockRemoteUnlockSwitchState(true, lockData, (lockData) {
    //     print("SET TO REMOTE UNLOCK MODE");
    //     this.lockData = lockData;
    //     this._uploadLockData(lockData);
    //   }, (error, errorMessage) {
    //     print("$error $errorMessage");
    //   });
    // }, (error, errorMessage) {
    //   print("$error $errorMessage");
    // });
  }

  Future<void> _showDevicesBottomSheet() async {
    if (!await _isAndroidPermissionGranted()) {
      await _requestAndroidPermissions();
    }
    final lockScanStream = await SmartLock.startLockScan();

    lockScanStream.listen((scanModel) {
      setState(() {
        models[scanModel.lockMac] = scanModel;
      });
    });

    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) => Container(
            height: 300,
            child: ListView.builder(
              itemCount: models.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _initLock(models.values.elementAt(index));
                  },
                  child: ListTile(
                    title: Text(models.values.elementAt(index).lockName),
                    subtitle: Text(models.values.elementAt(index).lockMac),
                  ),
                );
              },
            )));

    // TTLock.startScanLock((scanModel) {
    //   print("MODEL : ${scanModel.lockName}");
    //   setState(() {
    //     models[scanModel.lockMac] = scanModel;
    //   });
    // });

    // showModalBottomSheet(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return Container(
    //         height: 300,
    //         child: ListView.builder(
    //           itemCount: models.length,
    //           itemBuilder: (context, index) {
    //             return GestureDetector(
    //               onTap: () {
    //                 _initLock(models.values.elementAt(index));
    //               },
    //               child: ListTile(
    //                 title: Text(models.values.elementAt(index).lockName),
    //                 subtitle: Text(models.values.elementAt(index).lockMac),
    //               ),
    //             );
    //           },
    //         ),
    //       );
    //     }).whenComplete(() {
    //   TTLock.stopScanLock();
    // });
  }

  _lookForGateways() async {
    if (!await _isAndroidPermissionGranted()) {
      await _requestAndroidPermissions();
    }
    TTGateway.startScan((scanModel) {
      print("MODEL : ${scanModel.gatewayName}");
      gateways[scanModel.gatewayMac] = scanModel;
    });

    Future<Map<dynamic, dynamic>> _connectAndInitGateway(String mac) {
      Completer<Map<dynamic, dynamic>> completer =
          Completer<Map<dynamic, dynamic>>();
      TTGateway.connect(mac, (connectStatus) {
        if (connectStatus == TTGatewayConnectStatus.success) {
          print("CONNECT SUCCESS");
          TTGateway.init({
            "mac": mac,
            "uid": 28736614,
            "wifi": "Toyama Controls",
            "wifiPassword": "Z7LFRZer",
            "ttlockLoginPassword": "fa32bc3ffcc0f1b723ca756861844fe3",
            "gatewayName": "GATEWAY 1",
          }, (map) {
            // print("GATEWAY SUCCESS : $map");
            // _queryGatewayInit("F5:58:4D:99:50:8E");
            completer.complete(map);
          }, (error, errorMessage) {
            print("ERROR : $error $errorMessage");
          });
        }
      });

      return completer.future;
    }

    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 300,
            child: ListView.builder(
              itemCount: gateways.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () async {
                    var res = await _connectAndInitGateway(
                        gateways.values.elementAt(index).gatewayMac);
                    print("returned from init gateway");
                    print(res);
                  },
                  child: ListTile(
                    title: Text(gateways.values.elementAt(index).gatewayName),
                    subtitle: Text(gateways.values.elementAt(index).gatewayMac),
                  ),
                );
              },
            ),
          );
        }).whenComplete(() {
      TTGateway.stopScan();
    });
  }

  @override

  /// Builds the home screen of the app.
  ///
  /// The screen contains buttons to:
  /// - scan for devices
  /// - init a device
  /// - scan for gateways
  /// - reset a lock
  /// - lock a lock
  /// - unlock a lock
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Flutter Demo'),
        ),
        body: Column(
          children: [
            ElevatedButton(
                onPressed: () {
                  _showDevicesBottomSheet();
                },
                child: Text("LOOK FOR DEVICES")),
            ElevatedButton(onPressed: () {}, child: Text("INIT DEVICE")),
            ElevatedButton(
                onPressed: () {
                  _lookForGateways();
                },
                child: Text("LOOK FOR GATEWAYS")),
            ElevatedButton(
                onPressed: () {
                  TTLock.resetLock(lockData!, () {}, (error, errmessage) {});
                },
                child: Text("RESET LOCK")),
            Row(
              children: [
                ElevatedButton(
                    onPressed: () {
                      TTLock.controlLock(
                        lockData!,
                        TTControlAction.lock,
                        (a, b, c) {},
                        (error, errmessage) {},
                      );
                    },
                    child: Text("LOCK")),
                ElevatedButton(
                    onPressed: () {
                      TTLock.controlLock(lockData!, TTControlAction.unlock,
                          (a, b, c) {}, (error, errmessage) {});
                    },
                    child: Text("UNLOCK"))
              ],
            )
          ],
        ));
  }
}
