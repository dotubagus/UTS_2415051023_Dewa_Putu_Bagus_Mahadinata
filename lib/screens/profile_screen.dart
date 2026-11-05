import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/profile_provider.dart';
import '../providers/watchlist_provider.dart';
import '../widgets/profile_avatar.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

/// Halaman Profil bergaya IDLIX: avatar, tombol Edit Profile, nama,
/// informasi mahasiswa, dan 3 ringkasan statistik watchlist.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final profile = context.watch<ProfileProvider>();
    final items = context.watch<WatchlistProvider>().items;

    final watched = items.where((e) => e.watched).toList();
    // Rata-rata hanya dari film yang sudah ditonton & dinilai
    final avg = watched.isEmpty
        ? 0.0
        : watched.map((e) => e.rating).reduce((a, b) => a + b) / watched.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Pengaturan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  ProfileAvatar(profile: profile, size: 80),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EditProfileScreen()),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                        text: '${profile.name} di CineList: '
                            '${items.length} disimpan, ${watched.length} ditonton.',
                      ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Ringkasan profil disalin')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surface,
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.ios_share_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 26,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '2415051023 · PTI 5 IKI',
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 2),
              Text(
                'Universitas Pendidikan Ganesha',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _Stat(value: '${items.length}', label: 'DISIMPAN'),
                  _Stat(value: '${watched.length}', label: 'DITONTON'),
                  _Stat(
                    value: avg == 0 ? '-' : avg.toStringAsFixed(1),
                    label: 'RATA-RATA',
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Center(
                child: Text('CineList v1.0.0',
                    style: TextStyle(fontSize: 12, color: muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
