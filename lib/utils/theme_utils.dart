import 'package:flutter/material.dart';

// WhatsApp theme colors
class WhatsAppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF128C7E); // WhatsApp green
  static const Color primaryDarkColor = Color(0xFF075E54); // WhatsApp dark green
  static const Color accentColor = Color(0xFF25D366); // WhatsApp light green
  
  // Chat bubble colors
  static const Color outgoingMessageColor = Color(0xFFDCF8C6); // Light green for outgoing messages
  static const Color incomingMessageColor = Color(0xFFFFFFFF); // White for incoming messages
  
  // Text colors
  static const Color primaryTextColor = Color(0xFF000000); // Black
  static const Color secondaryTextColor = Color(0xFF8C8C8C); // Gray
  static const Color linkColor = Color(0xFF039BE5); // Blue for links
  
  // Background colors
  static const Color backgroundColor = Color(0xFFECE5DD); // Light beige background
  static const Color appBarColor = primaryDarkColor;
  
  // Create WhatsApp theme
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
    );
  }
}