import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'state/product_store.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/recipes_screen.dart'; 
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();
  runApp(const EcoChefApp());
}

class EcoChefApp extends StatelessWidget {
  const EcoChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            key: ValueKey('loading'),
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return MaterialApp(
            key: const ValueKey('onboarding'),
            title: 'EcoChef AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const OnboardingScreen(),
          );
        }

        return ChangeNotifierProvider<ProductStore>(
          key: ValueKey('user-${user.uid}'),
          create: (_) => ProductStore(uid: user.uid),
          child: MaterialApp(
            title: 'EcoChef AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const RootShell(),
          ),
        );
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    RecipesScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestInitialNotificationPermission();
  }

  Future<void> _requestInitialNotificationPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('hasAskedNotificationPermission') ?? false;

    if (!hasAsked) {
      final granted = await NotificationService().requestPermission();
      
      await prefs.setBool('notificationsEnabled', granted);
      
      await prefs.setBool('hasAskedNotificationPermission', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Stok'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Tarifler'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ayarlar'),
        ],
      ),
    );
  }
}