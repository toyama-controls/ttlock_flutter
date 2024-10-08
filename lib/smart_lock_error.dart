import 'package:ttlock_flutter/ttlock.dart';

class SmartLockException implements Exception {
  final String errorMessage;
  final String errCode;
  SmartLockException({required this.errorMessage, required this.errCode});

  @override
  String toString() {
    return errorMessage;
  }
}
