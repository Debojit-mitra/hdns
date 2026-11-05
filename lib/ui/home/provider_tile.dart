import 'package:flutter/material.dart';
import '../../data/dns_provider.dart';

enum _Action { edit, delete }

class ProviderTile extends StatelessWidget {
  const ProviderTile({
    super.key,
    required this.provider,
    required this.selected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final DnsProvider provider;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(24);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        animationDuration: const Duration(milliseconds: 400),
        color: selected ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutBack,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(selected ? 14 : 22),
                  ),
                  child: Icon(
                    selected ? Icons.check_rounded : Icons.dns_outlined,
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(provider.name, style: tt.titleMedium),
                      if (provider.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            provider.description!,
                            style: tt.bodyMedium?.copyWith(
                              color: selected
                                  ? cs.onPrimaryContainer
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        provider.hostname,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (provider.isCustom)
                  PopupMenuButton<_Action>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (a) =>
                        a == _Action.edit ? onEdit?.call() : onDelete?.call(),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: _Action.edit, child: Text('Edit')),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
