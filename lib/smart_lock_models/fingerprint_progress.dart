///Represents the current progress of an add fingerprint operation
///
///[currentCount] The number of times fingerprint has been scanned
///
///[totalCount] The total number of times fingerprint has to be scanned
///

class FingerprintProgress {
  FingerprintProgress({required this.currentCount, required this.totalCount});
  final int currentCount;
  final int totalCount;
}
