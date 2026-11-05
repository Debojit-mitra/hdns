import 'dart:convert';
import 'package:flutter/services.dart';
import 'dns_provider.dart';

class NativeDnsState {
  const NativeDnsState({
    required this.permission,
    required this.packageName,
    this.mode,
    this.hostname,
    this.activeId,
    this.lastId,
    this.ok = true,
  });

  final bool permission;
  final String packageName;
  final String? mode;
  final String? hostname;
  final String? activeId;
  final String? lastId;
  final bool ok;

  bool get isOn => mode == 'hostname';

  factory NativeDnsState.fromMap(Map<dynamic, dynamic> m) => NativeDnsState(
    permission: m['permission'] == true,
    packageName: m['package'] as String? ?? '',
    mode: m['mode'] as String?,
    hostname: m['hostname'] as String?,
    activeId: m['activeId'] as String?,
    lastId: m['lastId'] as String?,
    ok: m['ok'] != false,
  );
}

class DnsChannel {
  static const _c = MethodChannel('hdns/dns');

  Future<NativeDnsState> _state(String method, [Object? args]) async =>
      NativeDnsState.fromMap(await _c.invokeMethod(method, args) as Map);

  Future<NativeDnsState> getState() => _state('getState');
  Future<NativeDnsState> apply(String id) => _state('apply', {'id': id});
  Future<NativeDnsState> turnOff() => _state('turnOff');

  Future<void> syncConfig({
    required List<DnsProvider> providers,
    required bool offIsAutomatic,
  }) => _c.invokeMethod('syncConfig', {
    'providers': jsonEncode(providers.map((p) => p.toJson()).toList()),
    'offMode': offIsAutomatic ? 'opportunistic' : 'off',
  });

  /// -1 = unsupported (below Android 13), 0 = not added, 1 = already added, 2 = added.
  Future<int> requestAddTile() async =>
      (await _c.invokeMethod<int>('requestAddTile')) ?? 0;

  Future<Map<String, bool>> getExtraDimState() async {
    final res = await _c.invokeMapMethod<String, dynamic>('getExtraDimState');
    return {
      'supported': res?['supported'] == true,
      'enabled': res?['enabled'] == true,
    };
  }

  Future<bool> setExtraDim(bool enabled) async =>
      (await _c.invokeMethod<bool>('setExtraDim', {'enabled': enabled})) ?? false;

  /// -1 = unsupported (below Android 13), 0 = not added, 1 = already added, 2 = added.
  Future<int> requestAddExtraDimTile() async =>
      (await _c.invokeMethod<int>('requestAddExtraDimTile')) ?? 0;
}
