/*
 * MAIN APP ENTRY POINT - EXTENDED WITH NAVIGATION
 * 
 * This is the main application entry point. Recently extended to support
 * navigation between the main schedule screen and the new projects screen.
 * 
 * RECENT CHANGES: Added routing support for the projects feature (Phase 2).
 * The app now supports navigation between MainScreen and ProjectsScreen.
 * 
 * TODO: Task 6.1 - Complete navigation structure setup
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:potential_aid_app/screens/main_screen.dart';
import 'package:potential_aid_app/screens/projects_screen.dart';
import 'package:time_machine/time_machine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TimeMachine.initialize({'rootBundle': rootBundle});
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Potential Aid App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // TODO: Task 6.1 - Set up navigation structure
      // STEPS:
      // 1. Add routes for ProjectsScreen
      // 2. Consider using named routes or go_router for future expansion
      // 3. Ensure proper back navigation between screens
      home: const MainScreen(),
      routes: {'/projects': (context) => const ProjectsScreen()},
    );
  }
}
