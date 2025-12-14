part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final bool isDarkMode;

  const ThemeState({required this.isDarkMode});

  ThemeData get themeData {
    if (isDarkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF4CAF50), // Verde sapo
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F1F1F),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF4CAF50), // Verde sapo
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F1F1F),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  List<Object> get props => [isDarkMode];
}
