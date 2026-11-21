import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_quota.dart';
import '../models/vpn_config.dart';

class SubscriptionResult {
  final UserQuota quota;
  final List<VpnConfig> configs;

  SubscriptionResult({required this.quota, required this.configs});
}

class SubscriptionService {
  static const String _subKey = 'user_subscription_url';

  Future<void> saveSubscriptionUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subKey, url.trim());
  }

  Future<String?> getSavedSubscriptionUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subKey);
  }

  Future<SubscriptionResult> fetchSubscription(String subUrl) async {
    final uri = Uri.parse(subUrl.trim());
    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'v2rayNG/1.8.5',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Erreur serveur HTTP ${response.statusCode}');
    }

    UserQuota quota = UserQuota.empty();
    final userInfoHeader = response.headers['subscription-userinfo'] ??
        response.headers['Subscription-UserInfo'] ??
        response.headers['Subscription-Userinfo'];

    if (userInfoHeader != null && userInfoHeader.isNotEmpty) {
      quota = UserQuota.fromSubscriptionHeader(userInfoHeader);
    }

    String decodedBody = response.body;
    try {
      final sanitized = response.body.replaceAll(RegExp(r'\s+'), '');
      final bytes = base64.decode(base64.normalize(sanitized));
      decodedBody = utf8.decode(bytes);
    } catch (_) {
      // Le corps n'est pas en base64, on utilise le texte brut
    }

    final lines = decodedBody.split(RegExp(r'[\r\n]+'));
    final List<VpnConfig> configs = [];

    for (final line in lines) {
      final config = VpnConfig.parse(line);
      if (config != null) {
        configs.add(config);
      }
    }

    return SubscriptionResult(quota: quota, configs: configs);
  }
}
