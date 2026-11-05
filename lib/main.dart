import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/app_settings_provider.dart';
import 'providers/movie_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/watchlist_provider.dart';
import 'repositories/movie_repository.dart';
import 'repositories/watchlist_repository.dart';
import 'screens/main_shell.dart';
import 'services/supabase_service.dart';
import 'services/tmdb_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Muat variabel lingkungan dari file .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Gagal memuat file .env: $e');
  }

  // Mendukung key SUPABASE_KEY maupun SUPABASE_ANON_KEY
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey =
      dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
    } catch (e) {
      debugPrint('Gagal inisialisasi Supabase: $e');
    }
  }

  runApp(const CineListApp());
}

class CineListApp extends StatelessWidget {
  const CineListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider Pengaturan (Tema Gelap/Terang, Bahasa, Notifikasi)
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        // Provider profil lokal (nama & foto)
        ChangeNotifierProvider(create: (_) => ProfileProvider()..load()),
        // Provider film dari TMDB; langsung muat trending saat app mulai
        ChangeNotifierProvider(
          create: (_) =>
              MovieProvider(MovieRepository(TmdbService()))..loadTrending(),
        ),
        // Provider watchlist dari Supabase; langsung muat data saat app mulai
        ChangeNotifierProvider(
          create: (_) =>
              WatchlistProvider(WatchlistRepository(SupabaseService()))..load(),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();

    return MaterialApp(
      title: 'CineList',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const MainShell(),
    );
  }
}

/// Warna khas IDLIX: hitam pekat + merah.
const kIdlixRed = Color(0xFFE11D2E);

/// Tema bergaya IDLIX: gelap pekat, aksen merah, sudut membulat.
ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final bg = isDark ? const Color(0xFF050505) : const Color(0xFFF6F6F6);
  final surface = isDark ? const Color(0xFF111111) : Colors.white;
  final ink = isDark ? const Color(0xFFF2F2F2) : const Color(0xFF151515);
  final line = isDark ? const Color(0xFF232323) : const Color(0xFFE3E3E3);

  final scheme = ColorScheme.fromSeed(
    seedColor: kIdlixRed,
    brightness: brightness,
  ).copyWith(
    primary: kIdlixRed,
    onPrimary: Colors.white,
    primaryContainer:
        isDark ? const Color(0xFF2A0D11) : const Color(0xFFFFE3E5),
    onPrimaryContainer: isDark ? const Color(0xFFFF6B77) : kIdlixRed,
    secondary: kIdlixRed,
    surface: surface,
    onSurface: ink,
    onSurfaceVariant: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF666666),
    surfaceContainerHighest:
        isDark ? const Color(0xFF1B1B1B) : const Color(0xFFEDEDED),
    outline: isDark ? const Color(0xFF6B6B6B) : const Color(0xFF9A9A9A),
    outlineVariant: line,
  );

  final r12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    dividerColor: line,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: line),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : surface,
      elevation: 0,
      height: 64,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((st) => IconThemeData(
            color: st.contains(WidgetState.selected)
                ? kIdlixRed
                : scheme.onSurfaceVariant,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((st) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: st.contains(WidgetState.selected)
                ? kIdlixRed
                : scheme.onSurfaceVariant,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kIdlixRed,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: r12,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: line),
        shape: r12,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kIdlixRed),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: r12,
    ),
  );
}
