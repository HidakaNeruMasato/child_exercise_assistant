import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 温かみのある親しみやすい保護者向けMaterial3テーマ定義
class AppTheme {
  // カラーパレット
  static const Color primaryColor = Color(0xFFFF6F61); // ウォームコーラル
  static const Color primaryContainer = Color(0xFFFFDACC);
  static const Color secondaryColor = Color(0xFF4DB6AC); // パステルミント
  static const Color secondaryContainer = Color(0xFFB2DFDB);
  static const Color tertiaryColor = Color(0xFFFFA000); // ソフトアンバー
  static const Color backgroundColor = Color(0xFFFAF6F0); // 暖かみのあるウォームホワイト
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textDarkColor = Color(0xFF2C3E50);
  static const Color textMutedColor = Color(0xFF7F8C8D);
  static const Color cardBorderColor = Color(0xFFF0E5D8);

  /// 丸みのある角丸radius定義
  static const double cardRadius = 24.0;
  static const double buttonRadius = 28.0;
  static const double chipRadius = 16.0;

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.mPlusRounded1cTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        primaryContainer: primaryContainer,
        secondary: secondaryColor,
        secondaryContainer: secondaryContainer,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSurface: textDarkColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textDarkColor),
        titleTextStyle: GoogleFonts.mPlusRounded1c(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDarkColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: cardBorderColor, width: 1.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          minimumSize: const Size.fromHeight(56), // 大きめタップ領域
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.mPlusRounded1c(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: primaryColor, width: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: GoogleFonts.mPlusRounded1c(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer.withOpacity(0.4),
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        labelStyle: GoogleFonts.mPlusRounded1c(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDarkColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(chipRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDarkColor,
        ),
        titleLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textDarkColor,
        ),
        titleMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDarkColor,
        ),
        bodyLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 17,
          fontWeight: FontWeight.normal,
          color: textDarkColor,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.mPlusRounded1c(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: textDarkColor,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.mPlusRounded1c(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textDarkColor,
        ),
      ),
    );
  }
}
