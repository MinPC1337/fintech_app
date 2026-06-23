import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'core/navigation/app_navigator.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

const String _kOnboardingDone = 'onboarding_done';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await di.init();

  // Check xem đã xem onboarding chưa
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingDone = prefs.getBool(_kOnboardingDone) ?? false;

  runApp(
    BlocProvider(
      create: (_) => di.sl<AuthCubit>(),
      child: FintechApp(showOnboarding: !onboardingDone),
    ),
  );
}

class FintechApp extends StatelessWidget {
  final bool showOnboarding;
  const FintechApp({super.key, this.showOnboarding = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Fintech Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: showOnboarding ? const OnboardingPage() : const LoginPage(),
    );
  }
}
