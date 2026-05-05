import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splashScreen.dart';
import 'loginPage.dart';
import 'homePage.dart';
import 'createReportPage.dart';
import 'viewReportsPage.dart';
import 'selectDatePage.dart';
import 'reportResultsPage.dart';

import 'compare_reports.dart';
import 'comparison_results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyBtDV0lphm17347g4zzo8y8k5WU5pc5Bns",
      appId: "775959999284",
      messagingSenderId: "1:775959999284:android:ae552832ad0089279eeb61",
      projectId: "brochette-3da65",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SysDev',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/reportResults') {
          final args = settings.arguments as DateTime;
          return MaterialPageRoute(
            builder: (context) => ReportResultsPage(selectedDate: args),
          );
        }

        return null;
      },
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(),
        '/createReport': (context) => const CreateReportPage(),
        '/viewReports': (context) => const ViewReportsPage(),
        '/selectDate': (context) => const SelectDatePage(),
        '/reports/compare': (_) => const CompareReportsScreen(),
        '/reports/comparison-results': (_) => const ComparisonResultsScreen(),
      },
    );
  }
}
