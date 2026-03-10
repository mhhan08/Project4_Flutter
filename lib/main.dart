import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'features/logbook/models/log_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('id_ID', null);

  await Hive.initFlutter();
  
  Hive.registerAdapter(LogCategoryAdapter()); 
  Hive.registerAdapter(LogModelAdapter()); 

  await Hive.openBox<LogModel>(
    'offline_logs',
  ); 

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogBook App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const OnboardingView(), 
    );
  }
}