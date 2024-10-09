import 'dart:async';

import 'package:ttlock_flutter/ttgateway.dart';
import 'package:ttlock_flutter/ttlock.dart';

class TtGatewayConnection {
  final String macAddress;

  TtGatewayConnection(this.macAddress);
  Function()? _executeWhileConnected;

  Future<void> whileConnected(Function() callback) async {
    _executeWhileConnected = callback;
  }

  Future<bool> connect() async {
    Completer<bool> completer = Completer();
    TTGateway.connect(this.macAddress, (connectStatus) {
      if (connectStatus == TTGatewayConnectStatus.success) {
        if (_executeWhileConnected != null) {
          _executeWhileConnected!();
        }
        completer.complete(true);
      } else {
        completer.complete(false);
      }
    });
    return completer.future;
  }
}
