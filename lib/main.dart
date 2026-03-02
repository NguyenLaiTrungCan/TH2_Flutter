import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:todo_list/firebase_options.dart';
import 'package:todo_list/screens/home_screen.dart';
import 'package:todo_list/services/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ThemeManager().init();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ThemeManager().themeIndex,
      builder: (context, idx, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeManager.themeDataForIndex(idx),
          home: const HomeScreen(),
        );
      },
    );
  }
}
