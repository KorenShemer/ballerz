import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'screens/players_screen.dart';
import 'screens/teams_games_screen.dart';
import 'screens/stats_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const FootballApp());
}

class FootballApp extends StatelessWidget {
  const FootballApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Dark status/nav bar to match the dark theme
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return MaterialApp(
      title: 'Ballerz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF25D366),
          secondary: Color(0xFF128C7E),
          surface: Color(0xFF1F2C34),
          error: Color(0xFFFF3B30),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFE9EDEF),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFE9EDEF)),
        ),
        splashColor: const Color(0xFF25D366).withOpacity(0.08),
        highlightColor: const Color(0xFF25D366).withOpacity(0.04),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final _screens = const [
    PlayersScreen(),
    TeamsGamesScreen(),
    StatsScreen(),
  ];

  // Matching the players_screen dark palette
  static const _bg       = Color(0xFF000000);
  static const _surface  = Color(0xFF1F2C34);
  static const _primary  = Color(0xFF25D366);
  static const _textSub  = Color(0xFF8696A0);
  static const _divider  = Color(0xFF2A3942);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // Extend body behind the nav bar so the blur shows content beneath
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _FrostedNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ─── Frosted glass bottom nav bar ────────────────────────────────────────────
class _FrostedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _bg       = Color(0xFF000000);
  static const _surface  = Color(0xFF1F2C34);
  static const _primary  = Color(0xFF25D366);
  static const _textSub  = Color(0xFF8696A0);
  static const _divider  = Color(0xFF2A3942);

  const _FrostedNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded,      label: 'Squad'),
    _NavItem(icon: Icons.bolt_outlined,          activeIcon: Icons.bolt_rounded,         label: 'Teams'),
    _NavItem(icon: Icons.bar_chart_outlined,     activeIcon: Icons.bar_chart_rounded,    label: 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          // Same tint formula as the players_screen top bar
          color: const Color(0xFF121B22).withOpacity(0.82),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // thin top border — same _divider colour
              Container(height: 0.5, color: _divider),
              Padding(
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: bottomPad + 8,
                ),
                child: Row(
                  children: List.generate(_items.length, (i) {
                    final item     = _items[i];
                    final selected = i == currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected
                                    ? _primary.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                selected ? item.activeIcon : item.icon,
                                color: selected ? _primary : _textSub,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}