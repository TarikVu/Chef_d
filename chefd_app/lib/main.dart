import 'package:chefd_app/allergen_menu.dart';
import 'package:chefd_app/home_layout.dart';
import 'package:chefd_app/login.dart';
import 'package:chefd_app/sign_up.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chefd_app/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zwokvovrkprpsdjozoqa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp3b2t2b3Zya3BycHNkam96b3FhIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODA2MzE4NjUsImV4cCI6MTk5NjIwNzg2NX0.eWhOvIRApOd_kwHtaNG4wqFeqyC04s2yg3y0YNO3EB0',
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Chef'd App",
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginWidget(),
        '/login': (context) => const LoginWidget(),
        '/home': (context) => const HomeWidget(),
        '/signup': (context) => const SignUpWidget(),
        '/additionalinfo': (context) => const AdditionalInfoWidget(),
      },
      //home: LoginWidget(),
    );
  }
}
