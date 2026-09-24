import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';
abstract final class AppTheme {
 static ThemeData light(){final t=AppTypography.build();return ThemeData(useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:AppColors.primary),scaffoldBackgroundColor:AppColors.background,textTheme:t,appBarTheme:AppBarTheme(backgroundColor:AppColors.background,foregroundColor:AppColors.textPrimary,titleSpacing:AppSpacing.screen),inputDecorationTheme:const InputDecorationTheme(filled:true,fillColor:AppColors.card),navigationBarTheme:const NavigationBarThemeData(backgroundColor:AppColors.card));}
 static ThemeData dark(){final t=AppTypography.build();final c=ColorScheme.fromSeed(seedColor:AppColors.primary,brightness:Brightness.dark);return ThemeData(useMaterial3:true,colorScheme:c,brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF101615),textTheme:t,appBarTheme:const AppBarTheme(backgroundColor:Color(0xFF101615),foregroundColor:Colors.white),navigationBarTheme:const NavigationBarThemeData(backgroundColor:Color(0xFF17201E)));}
}
