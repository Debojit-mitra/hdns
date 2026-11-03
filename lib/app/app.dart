import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../ui/home/home_screen.dart';
import '../ui/setup/setup_screen.dart';
import '../ui/update/update_sheet.dart';
import 'theme.dart';

class HdnsApp extends ConsumerWidget {
  const HdnsApp({super.key});

  static const _seed = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return DynamicColorBuilder(
      builder: (lightDyn, darkDyn) {
        final useDyn = settings.dynamicColor;
        final light = useDyn && lightDyn != null
            ? lightDyn
            : ColorScheme.fromSeed(seedColor: _seed);
        final dark = useDyn && darkDyn != null
            ? darkDyn
            : ColorScheme.fromSeed(
                seedColor: _seed,
                brightness: Brightness.dark,
              );
        return MaterialApp(
          title: 'HDNS',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: buildTheme(light),
          darkTheme: buildTheme(dark),
          home: const _Gate(),
        );
      },
    );
  }
}

/// Shows setup until the permission is granted, then the home screen.
/// Re-checks Android's real state whenever the app comes back to the foreground.
class _Gate extends ConsumerStatefulWidget {
  const _Gate();
  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    final info = await ref.read(updateProvider.future);
    if (info == null || !mounted) return;
    showUpdateSheet(context, info);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      ref.read(dnsControllerProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(dnsControllerProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
          data: (s) => s.permission
              ? const HomeScreen()
              : SetupScreen(packageName: s.packageName),
        );
  }
}
