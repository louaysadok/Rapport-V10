import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_state.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  appDatabase = await openAppDatabase();
  await appDatabase.init();

  // Notifications locales : rappel quotidien à 18:00 heure locale.
  await notificationService.init();
  await notificationService.scheduleDailyReminder();

  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const RapportApp(),
    ),
  );
}
