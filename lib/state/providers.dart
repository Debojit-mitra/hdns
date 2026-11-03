import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/update_service.dart';

import '../data/dns_channel.dart';
import '../data/dns_provider.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final dnsChannelProvider = Provider<DnsChannel>((ref) => DnsChannel());

// ---------- Settings ----------
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.dynamicColor,
    required this.offIsAutomatic,
  });
  final ThemeMode themeMode;
  final bool dynamicColor;
  final bool offIsAutomatic;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? dynamicColor,
    bool? offIsAutomatic,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    dynamicColor: dynamicColor ?? this.dynamicColor,
    offIsAutomatic: offIsAutomatic ?? this.offIsAutomatic,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  AppSettings build() => AppSettings(
    themeMode: ThemeMode.values[(_p.getInt('theme') ?? 0).clamp(0, 2)],
    dynamicColor: _p.getBool('dynamic') ?? true,
    offIsAutomatic: _p.getBool('offAuto') ?? true,
  );

  void setThemeMode(ThemeMode m) {
    _p.setInt('theme', m.index);
    state = state.copyWith(themeMode: m);
  }

  void setDynamicColor(bool v) {
    _p.setBool('dynamic', v);
    state = state.copyWith(dynamicColor: v);
  }

  Future<void> setOffIsAutomatic(bool v) async {
    await _p.setBool('offAuto', v);
    state = state.copyWith(offIsAutomatic: v);
    await ref.read(dnsControllerProvider.notifier).sync();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ---------- Provider list (presets + custom) ----------
class ProvidersNotifier extends Notifier<List<DnsProvider>> {
  SharedPreferences get _p => ref.read(sharedPrefsProvider);

  @override
  List<DnsProvider> build() {
    final raw = _p.getString('custom');
    final custom = raw == null
        ? <DnsProvider>[]
        : (jsonDecode(raw) as List)
              .map(
                (e) =>
                    DnsProvider.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
    return [...kPresets, ...custom];
  }

  Future<void> _persist() async {
    await _p.setString(
      'custom',
      jsonEncode(
        state.where((p) => p.isCustom).map((p) => p.toJson()).toList(),
      ),
    );
    await ref.read(dnsControllerProvider.notifier).sync();
  }

  Future<void> upsert(DnsProvider p) async {
    final i = state.indexWhere((x) => x.id == p.id);
    state = i < 0 ? [...state, p] : ([...state]..[i] = p);
    await _persist();
  }

  Future<void> remove(String id) async {
    state = state.where((p) => p.id != id).toList();
    await _persist();
  }
}

final providersProvider =
    NotifierProvider<ProvidersNotifier, List<DnsProvider>>(
      ProvidersNotifier.new,
    );

// ---------- DNS controller (talks to Android) ----------
enum ApplyResult { ok, failed, unverified }

class DnsController extends AsyncNotifier<NativeDnsState> {
  DnsChannel get _ch => ref.read(dnsChannelProvider);

  @override
  Future<NativeDnsState> build() async {
    await sync();
    return _ch.getState();
  }

  /// Pushes the provider list and off-mode to Android so the tile can use them.
  Future<void> sync() => _ch.syncConfig(
    providers: ref.read(providersProvider),
    offIsAutomatic: ref.read(settingsProvider).offIsAutomatic,
  );

  Future<void> refresh() async {
    state = AsyncData(await _ch.getState());
  }

  Future<void> turnOff() async {
    state = AsyncData(await _ch.turnOff());
  }

  Future<ApplyResult> select(DnsProvider p) async {
    final s = await _ch.apply(p.id);
    state = AsyncData(s);
    if (!s.ok) return ApplyResult.failed;
    return await _verify() ? ApplyResult.ok : ApplyResult.unverified;
  }

  Future<bool> _verify() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    try {
      final r = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 5));
      return r.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

final dnsControllerProvider =
    AsyncNotifierProvider<DnsController, NativeDnsState>(DnsController.new);

// ---------- Updates ----------
final updateProvider = FutureProvider<UpdateInfo?>((ref) => checkForUpdate());

final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);
