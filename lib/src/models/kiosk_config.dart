/// System UI features available in kiosk mode (Android 9+).
enum KioskFeature {
  systemInfo(1),
  notifications(2),
  home(4),
  overview(8),
  globalActions(16),
  keyguard(32);

  final int value;
  const KioskFeature(this.value);
}

/// Configuration for kiosk mode behavior.
class KioskConfig {
  /// Allow status bar info (time, battery, connectivity).
  final bool showStatusBar;

  /// Allow system notifications to appear.
  final bool showNotifications;

  /// Allow the home button.
  final bool enableHomeButton;

  /// Allow the overview/recents button.
  final bool enableOverviewButton;

  /// Allow the power button global actions dialog.
  final bool enablePowerButton;

  /// Additional packages allowed to run alongside the kiosk app.
  final List<String> allowedPackages;

  const KioskConfig({
    this.showStatusBar = false,
    this.showNotifications = false,
    this.enableHomeButton = false,
    this.enableOverviewButton = false,
    this.enablePowerButton = false,
    this.allowedPackages = const [],
  });

  Map<String, dynamic> toMap() => {
        'showStatusBar': showStatusBar,
        'showNotifications': showNotifications,
        'enableHomeButton': enableHomeButton,
        'enableOverviewButton': enableOverviewButton,
        'enablePowerButton': enablePowerButton,
        'allowedPackages': allowedPackages,
      };

  factory KioskConfig.fromMap(Map<String, dynamic> map) => KioskConfig(
        showStatusBar: map['showStatusBar'] as bool? ?? false,
        showNotifications: map['showNotifications'] as bool? ?? false,
        enableHomeButton: map['enableHomeButton'] as bool? ?? false,
        enableOverviewButton: map['enableOverviewButton'] as bool? ?? false,
        enablePowerButton: map['enablePowerButton'] as bool? ?? false,
        allowedPackages:
            (map['allowedPackages'] as List<dynamic>?)?.cast<String>() ??
                const [],
      );
}
