class WifiScanResult {
  String ssid;
  int rssi;
  WifiScanResult(this.ssid, this.rssi);

  factory WifiScanResult.fromMap(Map<dynamic, dynamic> map) {
    return WifiScanResult(map['wifi'].toString(), (map['rssi'] as num).toInt());
  }

  static List<WifiScanResult> fromMapList(List<dynamic> list) => list
      .map(
          (element) => WifiScanResult.fromMap(element as Map<dynamic, dynamic>))
      .toList();
}
