import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/video_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system navigation and status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0F17),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const GSVideoPlayerApp());
}

class GSVideoPlayerApp extends StatelessWidget {
  const GSVideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GS Video Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0F17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00ADB5),
          secondary: Color(0xFF6366F1),
          surface: Color(0xFF1E2235),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF141724),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E2235),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const VideoListScreen(),
    );
  }
}
