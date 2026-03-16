import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:todo_list/firebase_options.dart';
import 'package:todo_list/screens/home_screen.dart';
import 'package:todo_list/screens/login_screen.dart';
import 'package:todo_list/services/supabase_media_service.dart';
import 'package:todo_list/services/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await SupabaseMediaService.initialize();
    await ThemeManager().init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, bootstrapSnapshot) {
        if (bootstrapSnapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeManager.themeDataForIndex(0),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (bootstrapSnapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text('Startup failed: ${bootstrapSnapshot.error}'),
              ),
            ),
          );
        }

        return ValueListenableBuilder<int>(
          valueListenable: ThemeManager().themeIndex,
          builder: (context, idx, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeManager.themeDataForIndex(idx),
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    return const HomeScreen();
                  }
                  return const LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}
