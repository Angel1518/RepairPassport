import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/passport/ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RepairPassportApp()));
}

class RepairPassportApp extends ConsumerWidget {
  const RepairPassportApp({super.key});

  static const Color accentGreen = Color(0xFF15803D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'RepairPassport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accentGreen),
      darkTheme: AppTheme.dark(accent: accentGreen),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
