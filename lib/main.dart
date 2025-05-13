import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:baby_whistance_app/config/router/app_router.dart';
import 'package:baby_whistance_app/config/theme/app_theme.dart';

void main() async {
  print('[main.dart] main() CALLED');
  WidgetsFlutterBinding.ensureInitialized();
  print('[main.dart] WidgetsFlutterBinding.ensureInitialized() COMPLETED');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('[main.dart] Firebase.initializeApp() COMPLETED');
  runApp(const ProviderScope(child: MyApp()));
  print('[main.dart] runApp() COMPLETED');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('[main.dart] MyApp.build() CALLED');
    final router = ref.watch(appRouterProvider);
    print('[main.dart] MyApp.build() - appRouterProvider WATCHED');
    return MaterialApp.router(
      title: 'Baby Whistance App',
      theme: AppTheme.getTheme(),
      routerConfig: router,
    );
  }
}
