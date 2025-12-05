import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Red Theme Colors
  static const Color primaryRed = Color(0xFFDC2626); // Strong red
  static const Color secondaryRed = Color(0xFFEF4444); // Medium red
  static const Color lightRed = Color(0xFFFECACA); // Light red
  static const Color darkRed = Color(0xFF991B1B); // Dark red
  static const Color borderColor = Color(0xFFE5E5E5);
  static const Color accentColor = Color(
    0xFF059669,
  ); // Green for positive actions
  static const Color dangerColor = Color(0xFFDC2626); // Red for alerts
  static const Color warningColor = Color(0xFFD97706); // Amber for warnings
  static const Color backgroundColor = Color(
    0xFFFEF2F2,
  ); // Very light red background
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray for text
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color gradientStart = Color(0xFFDC2626);
  static const Color gradientEnd = Color(0xFFEF4444);

  static LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    offset: Offset(0, 2),
  );

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryRed,
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: primaryRed),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: GoogleFonts.poppins(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.inter(
        color: surfaceColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: GoogleFonts.inter(color: textSecondary),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryRed, width: 2),
      ),
    ),

    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: surfaceColor,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
  );
}
