class VpnConfig {
  final String name;
  final String rawUrl;
  final String protocol;
  final String address;
  final int port;

  VpnConfig({
    required this.name,
    required this.rawUrl,
    required this.protocol,
    required this.address,
    required this.port,
  });

  static VpnConfig? parse(String link) {
    try {
      final trimmed = link.trim();
      if (trimmed.isEmpty) return null;

      final uri = Uri.parse(trimmed);
      final scheme = uri.scheme.toUpperCase();

      String remarks = uri.fragment.isNotEmpty
          ? Uri.decodeComponent(uri.fragment)
          : '${scheme}_Server';

      return VpnConfig(
        name: remarks,
        rawUrl: trimmed,
        protocol: scheme,
        address: uri.host.isNotEmpty ? uri.host : 'Serveur VPS',
        port: uri.port != 0 ? uri.port : 443,
      );
    } catch (_) {
      return VpnConfig(
        name: 'Serveur VPN',
        rawUrl: link,
        protocol: 'V2RAY',
        address: 'VPS',
        port: 443,
      );
    }
  }
}
