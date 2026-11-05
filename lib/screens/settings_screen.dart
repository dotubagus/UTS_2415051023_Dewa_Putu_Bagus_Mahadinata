import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show kIdlixRed;
import '../providers/app_settings_provider.dart';
import '../providers/movie_provider.dart';

/// Halaman Pengaturan (Settings) bergaya IDLIX:
/// - Desain minimalis dan elegan
/// - Mode Gelap / Terang & Ikuti Sistem
/// - Bahasa default: Bahasa Indonesia
/// - Bersihkan cache & info aplikasi
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = settings.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ─── Tampilan ───
              _SectionLabel('TAMPILAN & TEMA', muted),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: kIdlixRed,
                      secondary: Icon(
                        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: isDark ? kIdlixRed : Colors.amber.shade700,
                      ),
                      title: const Text(
                        'Mode Gelap',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                        style: TextStyle(fontSize: 12, color: muted),
                      ),
                      value: isDark,
                      onChanged: (val) =>
                          context.read<AppSettingsProvider>().toggleDarkMode(val),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                    ListTile(
                      leading: Icon(Icons.brightness_auto_rounded, color: muted, size: 22),
                      title: const Text(
                        'Ikuti Pengaturan Sistem',
                        style: TextStyle(fontSize: 14),
                      ),
                      trailing: Radio<ThemeMode>(
                        activeColor: kIdlixRed,
                        value: ThemeMode.system,
                        groupValue: settings.themeMode,
                        onChanged: (val) {
                          if (val != null) {
                            context.read<AppSettingsProvider>().setThemeMode(val);
                          }
                        },
                      ),
                      onTap: () => context
                          .read<AppSettingsProvider>()
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Bahasa ───
              _SectionLabel('BAHASA', muted),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Text('🇮🇩', style: TextStyle(fontSize: 22)),
                  title: const Text(
                    'Bahasa Indonesia',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Bahasa default aplikasi',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: const Icon(Icons.check_circle_rounded, color: kIdlixRed, size: 22),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Data & Cache ───
              _SectionLabel('DATA & PENYIMPANAN', muted),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(Icons.cleaning_services_rounded, color: muted, size: 22),
                  title: const Text(
                    'Bersihkan Cache Pencarian',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Muat ulang katalog film trending TMDB',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: muted),
                  onTap: () {
                    context.read<MovieProvider>().loadTrending();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache pencarian berhasil dibersihkan!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ─── Tentang Aplikasi ───
              _SectionLabel('TENTANG', muted),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.info_outline_rounded, color: muted, size: 20),
                      title: const Text('Versi Aplikasi'),
                      trailing: Text(
                        '1.0.0',
                        style: TextStyle(fontWeight: FontWeight.w700, color: muted),
                      ),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.school_outlined, color: muted, size: 20),
                      title: const Text('Pengembang'),
                      trailing: Text(
                        'Dewa Putu Bagus Mahadinata',
                        style: TextStyle(fontWeight: FontWeight.w600, color: muted),
                      ),
                    ),
                    Divider(height: 1, indent: 56, color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                    ListTile(
                      dense: true,
                      leading: Icon(Icons.badge_outlined, color: muted, size: 20),
                      title: const Text('NIM & Kelas'),
                      trailing: Text(
                        '2415051023 · PTI 5 IKI',
                        style: TextStyle(fontWeight: FontWeight.w600, color: muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}
