import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_providers.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/task_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recording_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    debugPrint('Failed to load .env: $e');
  }

  final apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
  final apiService = ApiService(baseUrl: apiBaseUrl);
  await apiService.init();

  runApp(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(apiService),
      ],
      child: const TodalkApp(),
    ),
  );
}

class TodalkApp extends ConsumerStatefulWidget {
  const TodalkApp({super.key});

  @override
  ConsumerState<TodalkApp> createState() => _TodalkAppState();
}

class _TodalkAppState extends ConsumerState<TodalkApp> {
  bool _initialized = false;
  String _initialRoute = '/auth';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initApp());
  }

  Future<void> _initApp() async {
    final results = await Future.wait([
      ref.read(authProvider.notifier).tryRestoreSession(),
      ref.read(taskProvider.notifier).loadTasks(),
    ]);

    final sessionRestored = results[0] as bool;

    if (mounted) {
      setState(() {
        _initialized = true;
        _initialRoute = sessionRestored ? '/home' : '/auth';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _initialized
          ? (_initialRoute == '/auth' ? const AuthScreen() : const MainScreen())
          : const _SplashScreen(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const MainScreen(),
        '/task-detail': (_) => const TaskDetailScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              size: const Size(120, 48),
              painter: _SplashWaveformPainter(),
            ),
            const SizedBox(height: 24),
            const Text(
              'TODALK',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 4,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashWaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    final bars = 18;
    final barWidth = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final x = i * barWidth + barWidth / 2;
      final height = (size.height / 2) * (0.2 + 0.8 * (1 - (i % 5) / 5));
      final top = (size.height - height) / 2;
      if (i == 0) path.moveTo(x, top);
      path.lineTo(x, top + height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  List<Widget> _screens() => [
    HomeScreen(
      onOpenRecording: _openRecording,
      onNavigateToTab: (index) => setState(() => _currentIndex = index),
    ),
    const TaskListScreen(),
    const ProfileScreen(),
  ];

  void _openRecording() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const RecordingScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task saved!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens(),
      ),
      floatingActionButton: SizedBox(
        width: 60,
        height: 60,
        child: FloatingActionButton(
          onPressed: _openRecording,
          backgroundColor: AppColors.surfaceRaised,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.mic, color: AppColors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
