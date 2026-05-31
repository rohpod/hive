import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Auth redirect logic will handle routing to /login or / if authenticated
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
              errorBuilder: (_, __, ___) => const Icon(Icons.hive, size: 150, color: Color(0xFFFFD369)),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Hive',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFFFD369),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
