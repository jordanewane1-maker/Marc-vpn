import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import '../models/user_quota.dart';
import '../models/vpn_config.dart';
import 'subscription_service.dart';

enum VpnState { disconnected, connecting, connected, error }

class VpnEngine extends ChangeNotifier {
  final FlutterV2ray _flutterV2ray = FlutterV2ray();
  final SubscriptionService _subService = SubscriptionService();

  VpnState _state = VpnState.disconnected;
  UserQuota _quota = UserQuota.empty();
  List<VpnConfig> _configs = [];
  VpnConfig? _selectedConfig;

  String _uploadSpeed = '0 KB/s';
  String _downloadSpeed = '0 KB/s';
  String? _subscriptionUrl;
  bool _isLoading = false;
  String? _errorMessage;

  VpnState get state => _state;
  UserQuota get quota => _quota;
  List<VpnConfig> get configs => _configs;
  VpnConfig? get selectedConfig => _selectedConfig;
  String get uploadSpeed => _uploadSpeed;
  String get downloadSpeed => _downloadSpeed;
  String? get subscriptionUrl => _subscriptionUrl;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    try {
      await _flutterV2ray.initializeV2Ray();
      _flutterV2ray.v2rayStatus.addListener(_onV2rayStatusChanged);
    } catch (e) {
      debugPrint('Initialisation V2Ray error: $e');
    }

    _subscriptionUrl = await _subService.getSavedSubscriptionUrl();
    if (_subscriptionUrl != null && _subscriptionUrl!.isNotEmpty) {
      await refreshSubscription();
    }
  }

  void _onV2rayStatusChanged() {
    final status = _flutterV2ray.v2rayStatus.value;
    _uploadSpeed = status.uploadSpeed;
    _downloadSpeed = status.downloadSpeed;

    switch (status.state) {
      case 'CONNECTED':
        _state = VpnState.connected;
        break;
      case 'CONNECTING':
        _state = VpnState.connecting;
        break;
      case 'DISCONNECTED':
      default:
        _state = VpnState.disconnected;
        break;
    }
    notifyListeners();
  }

  void selectConfig(VpnConfig config) {
    _selectedConfig = config;
    notifyListeners();
  }

  Future<void> updateSubscriptionUrl(String url) async {
    _subscriptionUrl = url.trim();
    await _subService.saveSubscriptionUrl(_subscriptionUrl!);
    await refreshSubscription();
  }

  Future<void> refreshSubscription() async {
    if (_subscriptionUrl == null || _subscriptionUrl!.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _subService.fetchSubscription(_subscriptionUrl!);
      _quota = result.quota;
      _configs = result.configs;
      if (_configs.isNotEmpty && (_selectedConfig == null || !_configs.contains(_selectedConfig))) {
        _selectedConfig = _configs.first;
      }
    } catch (e) {
      _errorMessage = 'Erreur synchronisation : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleConnection() async {
    if (_state == VpnState.connected) {
      await disconnect();
    } else if (_state == VpnState.disconnected) {
      await connect();
    }
  }

  Future<void> connect() async {
    if (_selectedConfig == null) {
      _errorMessage = 'Aucun serveur sélectionné';
      notifyListeners();
      return;
    }

    if (_quota.totalBytes > 0 && !_quota.isValid) {
      _errorMessage = 'Quota de données épuisé ou compte expiré';
      notifyListeners();
      return;
    }

    _state = VpnState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      if (await _flutterV2ray.requestPermission()) {
        final v2rayURL = _flutterV2ray.parseV2rayURL(_selectedConfig!.rawUrl);
        await _flutterV2ray.startV2Ray(
          remark: _selectedConfig!.name,
          config: v2rayURL.getFullConfiguration(),
          proxyOnly: false,
        );
      } else {
        _state = VpnState.disconnected;
        _errorMessage = 'Permission VPN refusée par Android';
        notifyListeners();
      }
    } catch (e) {
      _state = VpnState.error;
      _errorMessage = 'Échec de connexion : $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _flutterV2ray.stopV2Ray();
      _state = VpnState.disconnected;
      _uploadSpeed = '0 KB/s';
      _downloadSpeed = '0 KB/s';
      notifyListeners();
      // Rafraîchir les données de consommation après la session
      await refreshSubscription();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }

  @override
  void dispose() {
    _flutterV2ray.v2rayStatus.removeListener(_onV2rayStatusChanged);
    super.dispose();
  }
}
