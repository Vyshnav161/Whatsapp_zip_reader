import 'package:flutter/material.dart';

// Custom App Theme
class WhatsAppTheme {
  // Primary colors
  static const Color primaryColor = Color.fromARGB(255, 76, 84, 147); // Deep purple
  static const Color primaryDarkColor = Color.fromARGB(255, 50, 56, 104); // Darker purple
  static const Color accentColor = Color(0xFFF4A261); // Peach accent
  
  // Chat bubble colors
  static const Color outgoingMessageColor = Color(0xFFE9D8FD); // Light purple for outgoing messages
  static const Color incomingMessageColor = Color(0xFFF8F9FA); // Light gray for incoming messages
  
  // Text colors
  static const Color primaryTextColor = Color(0xFF2D3748); // Dark slate
  static const Color secondaryTextColor = Color(0xFF718096); // Medium gray
  static const Color linkColor = Color(0xFF4299E1); // Blue for links
  
  // Background colors
  static const Color backgroundColor = Color(0xFFF0F4F8); // Light blue-gray background
  static const Color appBarColor = primaryDarkColor;
  
  // Create custom theme
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      cardTheme: CardTheme(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Roboto',
    );
  }
}