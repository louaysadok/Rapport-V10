import 'package:flutter/material.dart';

void main() {
  runApp(const RapportApp());
}

class RapportApp extends StatelessWidget {
  const RapportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rapport+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A1931)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Rapport+ — en construction')),
      ),
    );
  }
}
