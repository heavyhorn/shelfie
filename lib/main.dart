import 'package:flutter/material.dart';
import 'data/repositories/product_repository.dart';
import 'services/notification_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.init();
  } catch (e, st) {
    debugPrint('Notification init failed: $e\n$st');
  }
  runApp(const ShelfieApp());
  // Фоновое перепланирование — не блокирует показ UI.
  _rescheduleNotificationsInBackground();
}

Future<void> _rescheduleNotificationsInBackground() async {
  try {
    final products = await ProductRepository().getAll();
    await NotificationService.instance.rescheduleAll(products);
  } catch (e, st) {
    debugPrint('Reschedule in background failed: $e\n$st');
  }
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