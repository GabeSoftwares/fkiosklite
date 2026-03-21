/// Information about an available update.
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final int fileSize;
  final String checksum;
  final bool mandatory;

  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.fileSize,
    required this.checksum,
    this.mandatory = false,
  });

  factory UpdateInfo.fromMap(Map<String, dynamic> map) => UpdateInfo(
        version: map['version'] as String,
        downloadUrl: map['downloadUrl'] as String,
        fileSize: map['fileSize'] as int,
        checksum: map['checksum'] as String,
        mandatory: map['mandatory'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'version': version,
        'downloadUrl': downloadUrl,
        'fileSize': fileSize,
        'checksum': checksum,
        'mandatory': mandatory,
      };
}

/// Status of an ongoing update operation.
class UpdateStatus {
  final UpdateState state;
  final int sessionId;
  final double progress;
  final String? error;

  const UpdateStatus({
    required this.state,
    required this.sessionId,
    this.progress = 0.0,
    this.error,
  });

  factory UpdateStatus.fromMap(Map<String, dynamic> map) => UpdateStatus(
        state: UpdateState.values.byName(map['state'] as String),
        sessionId: map['sessionId'] as int,
        progress: (map['progress'] as num?)?.toDouble() ?? 0.0,
        error: map['error'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'state': state.name,
        'sessionId': sessionId,
        'progress': progress,
        'error': error,
      };
}

enum UpdateState {
  downloading,
  installing,
  success,
  failed,
}
