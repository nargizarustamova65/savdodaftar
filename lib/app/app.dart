import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../features/tools/tools_screens.dart';
import 'locale_provider.dart';
import 'router.dart';
import '../core/l10n/app_strings.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class BozorProApp extends ConsumerWidget { const BozorProApp({super.key}); @override Widget build(BuildContext context, WidgetRef ref) { final mode=ref.watch(themeModeProvider); return MaterialApp.router(title:'BozorPro',debugShowCheckedModeBanner:false,theme:AppTheme.light(),darkTheme:AppTheme.dark(),themeMode:mode,routerConfig:appRouter,locale:ref.watch(localeControllerProvider),supportedLocales:AppStrings.supportedLocales,localizationsDelegates:const [AppStringsDelegate(),GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate]); } }
