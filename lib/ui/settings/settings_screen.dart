import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../widgets/one_ui_app_bar.dart';

const _devName = 'Debojit';
const _devRole = 'Developer of HDNS';
const _devBio = 'I built HDNS to make switching DNS as easy as toggling Wi-Fi.';
const _devEmail = '';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final version = ref.watch(appVersionProvider).value ?? '';
    final extraDim = ref.watch(extraDimProvider).value;

    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(t, style: tt.titleMedium?.copyWith(color: cs.primary)),
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const OneUiSliverAppBar(title: 'Settings'),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                section('Theme'),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {s.themeMode},
                  onSelectionChanged: (v) => n.setThemeMode(v.first),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dynamic color'),
                  subtitle: const Text('Match your wallpaper (Android 12+)'),
                  value: s.dynamicColor,
                  onChanged: n.setDynamicColor,
                ),
                section('When turned off, use'),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Automatic')),
                    ButtonSegment(value: false, label: Text('Off')),
                  ],
                  selected: {s.offIsAutomatic},
                  onSelectionChanged: (v) => n.setOffIsAutomatic(v.first),
                ),
                section('Quick Settings tile'),
                Text(
                  'Tap the tile to turn DNS on or off.\n'
                  'Long-press it to pick a different provider.',
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.add_to_home_screen_rounded),
                    label: const Text('Add tile'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final code = await ref
                          .read(dnsChannelProvider)
                          .requestAddTile();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(switch (code) {
                            -1 =>
                              'Open Quick Settings, tap the pencil, and drag “Private DNS” in.',
                            1 => 'Tile is already added.',
                            2 => 'Tile added.',
                            _ => 'Tile not added.',
                          }),
                        ),
                      );
                    },
                  ),
                ),
                if (extraDim == null || extraDim.supported) ...[
                  section('Extra Dim (Bonus feature)'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.brightness_medium_rounded),
                    title: const Text('Extra Dim'),
                    subtitle: const Text(
                      'Dim the display beyond minimum brightness. '
                      'Helpful on devices like HyperOS where this tile is missing.',
                    ),
                    value: extraDim?.enabled ?? false,
                    onChanged: (v) =>
                        ref.read(extraDimProvider.notifier).toggle(v),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.add_to_home_screen_rounded),
                      label: const Text('Add Extra Dim tile'),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final code = await ref
                            .read(dnsChannelProvider)
                            .requestAddExtraDimTile();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(switch (code) {
                              -1 =>
                                'Open Quick Settings, tap the pencil, and drag “Extra Dim” in.',
                              1 => 'Tile is already added.',
                              2 => 'Tile added.',
                              _ => 'Tile not added.',
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                section('About'),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('About HDNS'),
                  subtitle: Text(version.isEmpty ? '' : 'v$version'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAboutSheet(context, version),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAboutSheet(BuildContext context, String version) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
    ),
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final tt = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Text(
                      _devName.isEmpty ? '?' : _devName[0].toUpperCase(),
                      style: tt.headlineMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_devName, style: tt.headlineMedium),
                        Text(
                          _devRole,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(_devBio, style: tt.bodyLarge),
              if (_devEmail.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectableText(_devEmail, style: tt.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Center(
                child: Text(
                  version.isEmpty ? 'HDNS' : 'HDNS v$version',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
