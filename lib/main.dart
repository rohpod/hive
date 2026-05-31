import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'utils/routes.dart';
import 'utils/theme.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Attempt to initialize Firebase.
    // NOTE: User must configure firebase_options.dart using `flutterfire configure`.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed: $e. Please run flutterfire configure.");
  }

  runApp(const ProviderScope(child: CollegeEventsApp()));
}

class CollegeEventsApp extends ConsumerWidget {
  const CollegeEventsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Hive',
      themeMode: ThemeMode.dark, // Force dark mode as per requirements
      darkTheme: AppTheme.darkTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
