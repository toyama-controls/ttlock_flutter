import 'package:ttlock_flutter/smart_lock_models/fingerprint_progress.dart';

/// [AddFingerprintResult] is and object returned from when the addfingerprint method is called.
///
/// [progressStream] is a stream of [FingerprintProgress] objects, they represent
/// the progress of the operation.
///
/// [fingerprintNumber] will complete with the fingerprint number of the newly created fingerprint once the operation is completed.
/// [progressStream] will close before the future completes.
///
///
class AddFingerprintResult {
  AddFingerprintResult(this.progressStream, this.fingerprintNumber);
  final Stream<FingerprintProgress> progressStream;
  final Future<String> fingerprintNumber;
}
