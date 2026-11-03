import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

const kRepoOwner = 'Debojit-mitra';
const kRepoName = 'hdns';
const kReleasesPage =
    'https://github.com/$kRepoOwner/$kRepoName/releases/latest';

class UpdateInfo {
  const UpdateInfo({
    required this.current,
    required this.latest,
    required this.notes,
    required this.url,
  });
  final String current; // e.g. 0.1.0
  final String latest; // e.g. 0.2.0
  final String notes;
  final String url;
}

/// Returns update info if a newer release exists, otherwise null.
/// Never throws: any failure (offline, rate limit, no releases) returns null.
Future<UpdateInfo?> checkForUpdate() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final current = (await PackageInfo.fromPlatform()).version;

    final req = await client.getUrl(
      Uri.parse(
        'https://api.github.com/repos/$kRepoOwner/$kRepoName/releases/latest',
      ),
    );
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    req.headers.set(HttpHeaders.userAgentHeader, 'hdns-app');

    final res = await req.close().timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      await res.drain<void>();
      return null;
    }
    final body = await res.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;

    final tag = (json['tag_name'] as String?) ?? '';
    if (!_isNewer(tag, current)) return null;

    return UpdateInfo(
      current: current,
      latest: tag.replaceFirst(RegExp(r'^[vV]'), ''),
      notes: (json['body'] as String?) ?? '',
      url: (json['html_url'] as String?) ?? kReleasesPage,
    );
  } catch (_) {
    return null;
  } finally {
    client.close();
  }
}

List<int> _parse(String v) {
  final core = v
      .trim()
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split(RegExp(r'[-+]'))
      .first;
  return core.split('.').map((p) => int.tryParse(p) ?? 0).toList();
}

bool _isNewer(String latest, String current) {
  final a = _parse(latest);
  final b = _parse(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}
