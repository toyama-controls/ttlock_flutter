///
///Represents an exception that occured while interacting with the TTLock SDK.
///

class SmartLockException implements Exception {
  final String errorMessage;
  final String errCode;
  SmartLockException({required this.errorMessage, required this.errCode});

  @override
  String toString() {
    return errorMessage;
  }
}
