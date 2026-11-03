import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dns_provider.dart';
import '../../state/providers.dart';
import '../custom/add_dns_sheet.dart';
import '../settings/settings_screen.dart';
import 'hero_card.dart';
import 'provider_tile.dart';
import '../../data/dns_channel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    DnsProvider p,
  ) async {
    HapticFeedback.mediumImpact();
    final ctrl = ref.read(dnsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final r = await ctrl.select(p);
    if (r == ApplyResult.ok) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            r == ApplyResult.failed
                ? 'Couldn’t apply. Check the permission.'
                : '${p.name} isn’t resolving. Revert?',
          ),
          action: SnackBarAction(label: 'Revert', onPressed: ctrl.turnOff),
        ),
      );
  }

  void _toggle(BuildContext context, WidgetRef ref, NativeDnsStateView v) {
    HapticFeedback.mediumImpact();
    final ctrl = ref.read(dnsControllerProvider.notifier);
    if (v.native.isOn) {
      ctrl.turnOff();
      return;
    }
    final list = ref.read(providersProvider);
    final p =
        list.where((x) => x.id == v.native.lastId).firstOrNull ?? list.first;
    _select(context, ref, p);
  }

  Future<void> _addOrEdit(
    BuildContext context,
    WidgetRef ref, {
    DnsProvider? existing,
  }) async {
    final result = await showAddDnsSheet(context, existing: existing);
    if (result == null) return;
    await ref.read(providersProvider.notifier).upsert(result);
    final native = ref.read(dnsControllerProvider).value;
    if (context.mounted &&
        existing != null &&
        native?.activeId == existing.id) {
      _select(context, ref, result); // re-apply edited hostname
    }
  }

  Future<void> _delete(WidgetRef ref, DnsProvider p) async {
    final native = ref.read(dnsControllerProvider).value;
    if (native?.activeId == p.id) {
      await ref.read(dnsControllerProvider.notifier).turnOff();
    }
    await ref.read(providersProvider.notifier).remove(p.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final native = ref.watch(dnsControllerProvider).value;
    final providers = ref.watch(providersProvider);
    final settings = ref.watch(settingsProvider);
    if (native == null) return const SizedBox.shrink();

    final active = providers.where((p) => p.id == native.activeId).firstOrNull;
    final on = native.isOn;
    final view = NativeDnsStateView(native);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        onPressed: () => _addOrEdit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('HDNS'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                HeroCard(
                  on: on,
                  label: on ? 'Using' : 'Private DNS',
                  title: on
                      ? (active?.name ?? native.hostname ?? 'Custom')
                      : (settings.offIsAutomatic ? 'Automatic' : 'Off'),
                  subtitle: on
                      ? (native.hostname ?? '')
                      : 'Tap the toggle to turn on',
                  onToggle: () => _toggle(context, ref, view),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'Providers',
                    style: tt.titleLarge?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                for (var i = 0; i < providers.length; i++)
                  ProviderTile(
                    provider: providers[i],
                    selected: on && providers[i].id == native.activeId,
                    isFirst: i == 0,
                    isLast: i == providers.length - 1,
                    onTap: () => _select(context, ref, providers[i]),
                    onEdit: () =>
                        _addOrEdit(context, ref, existing: providers[i]),
                    onDelete: () => _delete(ref, providers[i]),
                  ),
                const SizedBox(height: 96),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiny wrapper so _toggle can take the already-resolved native state.
class NativeDnsStateView {
  NativeDnsStateView(this.native);
  final NativeDnsState native;
}
