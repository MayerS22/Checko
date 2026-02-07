import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_colors.dart';
import 'theme/dark_modern_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/data_provider.dart';
import 'providers/user_provider.dart';
import 'screens/dark_home_screen.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize data provider (Firebase + local storage)
  final dataProvider = DataProvider();
  await dataProvider.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(MyApp(dataProvider: dataProvider));
}

class MyApp extends StatelessWidget {
  final DataProvider dataProvider;

  const MyApp({super.key, required this.dataProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: dataProvider),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Checko',
            debugShowCheckedModeBanner: false,
            theme: DarkModernTheme.createTheme(),
            home: const DarkHomeScreen(),
          );
        },
      ),
    );
  }
}
