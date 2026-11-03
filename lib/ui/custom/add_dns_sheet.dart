import 'package:flutter/material.dart';
import '../../data/dns_provider.dart';

Future<DnsProvider?> showAddDnsSheet(
  BuildContext context, {
  DnsProvider? existing,
}) {
  return showModalBottomSheet<DnsProvider>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
    ),
    builder: (_) => _AddDnsSheet(existing: existing),
  );
}

class _AddDnsSheet extends StatefulWidget {
  const _AddDnsSheet({this.existing});
  final DnsProvider? existing;
  @override
  State<_AddDnsSheet> createState() => _AddDnsSheetState();
}

class _AddDnsSheetState extends State<_AddDnsSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _host = TextEditingController(text: widget.existing?.hostname);

  @override
  void dispose() {
    _name.dispose();
    _host.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final host = _host.text.trim().toLowerCase();
    final name = _name.text.trim();
    final e = widget.existing;
    Navigator.pop(
      context,
      e != null
          ? e.copyWith(name: name, hostname: host)
          : DnsProvider(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              hostname: host,
              isCustom: true,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add custom DNS' : 'Edit DNS',
              style: tt.headlineMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _host,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Hostname (DNS-over-TLS)',
                hintText: 'dns.example.com',
                helperText:
                    'Hostname only. IP addresses don’t work with Private DNS. '
                    'NextDNS: <id>.dns.nextdns.io',
                helperMaxLines: 2,
              ),
              validator: validateHostname,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
