class WifiScanResult {
  String ssid;
  int rssi;
  WifiScanResult(this.ssid, this.rssi);

  factory WifiScanResult.fromMap(Map<String, dynamic> map) {
    return WifiScanResult(map['wifi'], map['rssi']);
  }

  static List<WifiScanResult> fromMapList(List<Map<String, dynamic>> list) =>
      list.map((element) => WifiScanResult.fromMap(element)).toList();
}
