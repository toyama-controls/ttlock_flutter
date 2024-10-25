import 'package:ttlock_flutter/smart_lock_models/fingerprint_progress.dart';

class AddFingerprintResult {
  AddFingerprintResult(this.progressStream, this.fingerprintNumber);
  final Stream<FingerprintProgress> progressStream;
  final Future<String> fingerprintNumber;
}
