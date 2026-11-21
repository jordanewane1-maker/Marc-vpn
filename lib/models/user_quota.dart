import 'package:intl/intl.dart';

class UserQuota {
  final int uploadBytes;
  final int downloadBytes;
  final int totalBytes;
  final int? expireTimestamp;

  UserQuota({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.totalBytes,
    this.expireTimestamp,
  });

  int get usedBytes => uploadBytes + downloadBytes;

  double get usedGB => usedBytes / (1024 * 1024 * 1024);
  double get totalGB => totalBytes / (1024 * 1024 * 1024);
  double get remainingGB {
    final rem = totalBytes - usedBytes;
    return (rem > 0 ? rem : 0) / (1024 * 1024 * 1024);
  }

  double get usageRatio {
    if (totalBytes <= 0) return 0.0;
    final ratio = usedBytes / totalBytes;
    return ratio.clamp(0.0, 1.0);
  }

  bool get isExpiredByTime {
    if (expireTimestamp == null || expireTimestamp == 0) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expireMs = expireTimestamp! > 9999999999
        ? expireTimestamp!
        : expireTimestamp! * 1000;
    return nowMs > expireMs;
  }

  bool get isQuotaExceeded {
    if (totalBytes <= 0) return false;
    return usedBytes >= totalBytes;
  }

  bool get isValid => !isExpiredByTime && !isQuotaExceeded;

  String get formattedExpiry {
    if (expireTimestamp == null || expireTimestamp == 0) return 'Illimité';
    final expireMs = expireTimestamp! > 9999999999
        ? expireTimestamp!
        : expireTimestamp! * 1000;
    final date = DateTime.fromMillisecondsSinceEpoch(expireMs);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static UserQuota fromSubscriptionHeader(String header) {
    int upload = 0;
    int download = 0;
    int total = 0;
    int? expire;

    final parts = header.split(';');
    for (final part in parts) {
      final kv = part.trim().split('=');
      if (kv.length == 2) {
        final key = kv[0].trim().toLowerCase();
        final value = int.tryParse(kv[1].trim());
        if (value != null) {
          if (key == 'upload') upload = value;
          if (key == 'download') download = value;
          if (key == 'total') total = value;
          if (key == 'expire') expire = value;
        }
      }
    }

    return UserQuota(
      uploadBytes: upload,
      downloadBytes: download,
      totalBytes: total,
      expireTimestamp: expire,
    );
  }

  static UserQuota empty() {
    return UserQuota(
      uploadBytes: 0,
      downloadBytes: 0,
      totalBytes: 0,
    );
  }
}
