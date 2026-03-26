import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/budget_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FloussiApp());
}

class FloussiApp extends StatelessWidget {
  const FloussiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetProvider()..loadData(),
      child: MaterialApp(
        title: 'فلوسي - Floussi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1A6B4A),
            primary: const Color(0xFF1A6B4A),
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1A6B4A),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1A6B4A),
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A6B4A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
