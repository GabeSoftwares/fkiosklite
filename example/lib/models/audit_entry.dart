/// Registo de uma ação do utilizador e o respetivo resultado.
class AuditEntry {
  final DateTime timestamp;
  final String action;
  final bool success;

  /// Detalhe do sucesso ou mensagem de erro, quando aplicável.
  final String? message;

  AuditEntry({
    required this.action,
    required this.success,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  AuditEntry.success(this.action, [this.message])
      : success = true,
        timestamp = DateTime.now();

  AuditEntry.failure(this.action, this.message)
      : success = false,
        timestamp = DateTime.now();

  String get formattedTime {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(timestamp.hour)}:${two(timestamp.minute)}:${two(timestamp.second)}';
  }
}
