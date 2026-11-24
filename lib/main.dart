import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  runApp(const ShelfieApp());
}

class ShelfieApp extends StatelessWidget {
  const ShelfieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shelfie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}