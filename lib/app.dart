import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';
import 'theme.dart';

class RapportApp extends ConsumerWidget {
  const RapportApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDark = settings.themeMode == ThemeMode.dark ||
        (settings.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return MaterialApp.router(
      title: 'Rapport+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('fr'), Locale('en')],
      locale: const Locale('fr'),
      routerConfig: appRouter,
    );
  }
}
