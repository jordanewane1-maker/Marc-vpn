import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../services/vpn_engine.dart';
import '../models/vpn_config.dart';
import 'settings_screen.dart';
import 'server_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnEngine>();
    final quota = vpn.quota;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Mon VPN',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: vpn.isLoading ? null : () => vpn.refreshSubscription(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (vpn.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Text(
                    vpn.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Carte de quota de données
              _buildQuotaCard(context, vpn),

              const SizedBox(height: 32),

              // Bouton central de connexion
              _buildConnectionButton(context, vpn),

              const SizedBox(height: 32),

              // Indicateurs de débit (Upload / Download)
              _buildSpeedRow(vpn),

              const SizedBox(height: 28),

              // Sélecteur de serveur
              _buildServerSelector(context, vpn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaCard(BuildContext context, VpnEngine vpn) {
    final quota = vpn.quota;
    final hasTotal = quota.totalBytes > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consommation Données',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: quota.isValid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  quota.isValid ? 'Actif' : 'Expiré / Épuisé',
                  style: TextStyle(
                    color: quota.isValid ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          CircularPercentIndicator(
            radius: 70.0,
            lineWidth: 12.0,
            animation: true,
            animateFromLastPercent: true,
            percent: quota.usageRatio,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(quota.usageRatio * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Utilisé',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: quota.usageRatio > 0.85
                ? Colors.redAccent
                : quota.usageRatio > 0.65
                    ? Colors.orangeAccent
                    : Colors.blueAccent,
            backgroundColor: Colors.white10,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuotaStat(
                'Consommé',
                '${quota.usedGB.toStringAsFixed(2)} Go',
                Colors.orangeAccent,
              ),
              _buildQuotaStat(
                'Total Alloué',
                hasTotal ? '${quota.totalGB.toStringAsFixed(1)} Go' : 'Illimité',
                Colors.blueAccent,
              ),
              _buildQuotaStat(
                'Restant',
                hasTotal ? '${quota.remainingGB.toStringAsFixed(2)} Go' : '∞',
                Colors.greenAccent,
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                'Expire le : ${quota.formattedExpiry}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildConnectionButton(BuildContext context, VpnEngine vpn) {
    final isConnected = vpn.state == VpnState.connected;
    final isConnecting = vpn.state == VpnState.connecting;

    Color btnColor = const Color(0xFF3B82F6);
    if (isConnected) btnColor = const Color(0xFF10B981);
    if (isConnecting) btnColor = const Color(0xFFF59E0B);

    return Column(
      children: [
        GestureDetector(
          onTap: isConnecting ? null : () => vpn.toggleConnection(),
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: btnColor.withOpacity(0.15),
              border: Border.all(color: btnColor, width: 4),
              boxShadow: [
                if (isConnected)
                  BoxShadow(
                    color: btnColor.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
              ],
            ),
            child: Center(
              child: isConnecting
                  ? const CircularProgressIndicator(color: Colors.amberAccent)
                  : Icon(
                      Icons.power_settings_new,
                      size: 60,
                      color: btnColor,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isConnected
              ? 'CONNECTÉ'
              : isConnecting
                  ? 'CONNEXION EN COURS...'
                  : 'DÉCONNECTÉ',
          style: TextStyle(
            color: btnColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedRow(VpnEngine vpn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSpeedBadge(
          Icons.arrow_downward,
          'Téléchargement',
          vpn.downloadSpeed,
          Colors.cyanAccent,
        ),
        const SizedBox(width: 20),
        _buildSpeedBadge(
          Icons.arrow_upward,
          'Envoi',
          vpn.uploadSpeed,
          Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildSpeedBadge(IconData icon, String label, String speed, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                speed,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerSelector(BuildContext context, VpnEngine vpn) {
    final selected = vpn.selectedConfig;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ServerListScreen()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            const Icon(Icons.dns, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected?.name ?? 'Aucun serveur configuré',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    selected != null
                        ? '${selected.protocol} • ${selected.address}:${selected.port}'
                        : 'Ajoutez un lien d\'abonnement dans les paramètres',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  void _showServerSelectionModal(BuildContext context, VpnEngine vpn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: vpn.configs.length,
          itemBuilder: (context, index) {
            final config = vpn.configs[index];
            final isChosen = config == vpn.selectedConfig;
            return ListTile(
              leading: Icon(
                Icons.check_circle,
                color: isChosen ? Colors.greenAccent : Colors.white24,
              ),
              title: Text(
                config.name,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              subtitle: Text(
                '${config.protocol} • ${config.address}:${config.port}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                vpn.selectConfig(config);
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }
}
