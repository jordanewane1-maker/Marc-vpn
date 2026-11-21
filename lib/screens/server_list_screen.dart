import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vpn_engine.dart';
import '../models/vpn_config.dart';
import 'settings_screen.dart';

class ServerListScreen extends StatefulWidget {
  const ServerListScreen({super.key});

  @override
  State<ServerListScreen> createState() => _ServerListScreenState();
}

class _ServerListScreenState extends State<ServerListScreen> {
  String _searchQuery = '';
  String _selectedProtocol = 'TOUS';

  @override
  Widget build(BuildContext context) {
    final vpn = context.watch<VpnEngine>();

    // Extraction des protocoles uniques disponibles
    final availableProtocols = ['TOUS'];
    for (final c in vpn.configs) {
      final p = c.protocol.toUpperCase();
      if (!availableProtocols.contains(p) && p.isNotEmpty) {
        availableProtocols.add(p);
      }
    }

    // Filtrage des serveurs
    final filteredConfigs = vpn.configs.where((config) {
      final matchesSearch = config.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          config.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesProtocol = _selectedProtocol == 'TOUS' ||
          config.protocol.toUpperCase() == _selectedProtocol;
      return matchesSearch && matchesProtocol;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'Sélection du Serveur',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: vpn.isLoading ? null : () => vpn.refreshSubscription(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Colors.white38),
                    hintText: 'Rechercher un serveur ou une IP...',
                    hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                ),
              ),
            ),

            // Filtres de protocoles si plusieurs types existent
            if (availableProtocols.length > 2)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  itemCount: availableProtocols.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final proto = availableProtocols[index];
                    final isSelected = proto == _selectedProtocol;
                    return ChoiceChip(
                      label: Text(
                        proto,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: const Color(0xFF1E293B),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedProtocol = proto);
                        }
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // Liste des serveurs
            Expanded(
              child: filteredConfigs.isEmpty
                  ? _buildEmptyState(context, vpn)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredConfigs.length,
                      itemBuilder: (context, index) {
                        final config = filteredConfigs[index];
                        final isSelected = config == vpn.selectedConfig;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white.withOpacity(0.06),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF3B82F6).withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.dns_rounded,
                                color: isSelected ? const Color(0xFF3B82F6) : Colors.white60,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              config.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 4, right: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    config.protocol.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${config.address}:${config.port}',
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 24,
                                  )
                                : const Icon(
                                    Icons.circle_outlined,
                                    color: Colors.white24,
                                    size: 24,
                                  ),
                            onTap: () async {
                              vpn.selectConfig(config);
                              if (vpn.state == VpnState.connected) {
                                // Reconnexion avec le nouveau serveur
                                await vpn.disconnect();
                                await vpn.connect();
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, VpnEngine vpn) {
    final hasNoSubscription = vpn.configs.isEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasNoSubscription ? Icons.link_off : Icons.search_off,
              size: 64,
              color: Colors.white24,
            ),
            const SizedBox(height: 16),
            Text(
              hasNoSubscription
                  ? 'Aucun serveur configuré'
                  : 'Aucun serveur ne correspond à votre recherche',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasNoSubscription
                  ? 'Ajoutez une URL d\'abonnement 3X-UI dans les paramètres pour charger vos serveurs.'
                  : 'Essayez un autre mot-clé ou modifiez le filtre de protocole.',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (hasNoSubscription) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                label: const Text(
                  'Ouvrir les Paramètres',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
