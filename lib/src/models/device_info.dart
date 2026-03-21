/// Aggregated device status information.
class DeviceInfo {
  final bool isDeviceOwner;
  final bool isInKioskMode;
  final String packageName;
  final String versionName;
  final int versionCode;
  final int androidSdkVersion;

  const DeviceInfo({
    required this.isDeviceOwner,
    required this.isInKioskMode,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    required this.androidSdkVersion,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) => DeviceInfo(
        isDeviceOwner: map['isDeviceOwner'] as bool? ?? false,
        isInKioskMode: map['isInKioskMode'] as bool? ?? false,
        packageName: map['packageName'] as String? ?? '',
        versionName: map['versionName'] as String? ?? '',
        versionCode: map['versionCode'] as int? ?? 0,
        androidSdkVersion: map['androidSdkVersion'] as int? ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'isDeviceOwner': isDeviceOwner,
        'isInKioskMode': isInKioskMode,
        'packageName': packageName,
        'versionName': versionName,
        'versionCode': versionCode,
        'androidSdkVersion': androidSdkVersion,
      };
}
