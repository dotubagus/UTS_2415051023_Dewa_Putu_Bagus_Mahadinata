import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/movie_provider.dart';
import 'providers/watchlist_provider.dart';
import 'repositories/movie_repository.dart';
import 'repositories/watchlist_repository.dart';
import 'screens/home_screen.dart';
import 'services/supabase_service.dart';
import 'services/tmdb_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const CineListApp());
}

class CineListApp extends StatelessWidget {
  const CineListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              MovieProvider(MovieRepository(TmdbService()))..loadTrending(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              WatchlistProvider(WatchlistRepository(SupabaseService()))
                ..load(),
        ),
      ],
      child: MaterialApp(
        title: 'CineList',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}