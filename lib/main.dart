import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:potential_aid_app/config/supabase_config.dart';
import 'package:potential_aid_app/schedule/screens/main_screen.dart';
import 'package:potential_aid_app/widget/widget_background_callback.dart';
import 'package:potential_aid_app/widgets/common/global_search_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:time_machine/time_machine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);

  // Load environment variables first
  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

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
      home: const GlobalSearchLauncher(child: MainScreen()),
    );
  }
}
