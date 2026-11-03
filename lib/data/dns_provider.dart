class DnsProvider {
  const DnsProvider({
    required this.id,
    required this.name,
    required this.hostname,
    this.description,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String hostname;
  final String? description;
  final bool isCustom;

  DnsProvider copyWith({String? name, String? hostname}) => DnsProvider(
    id: id,
    name: name ?? this.name,
    hostname: hostname ?? this.hostname,
    description: description,
    isCustom: isCustom,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hostname': hostname,
    'description': description,
    'isCustom': isCustom,
  };

  factory DnsProvider.fromJson(Map<String, dynamic> j) => DnsProvider(
    id: j['id'] as String,
    name: j['name'] as String,
    hostname: j['hostname'] as String,
    description: j['description'] as String?,
    isCustom: j['isCustom'] as bool? ?? false,
  );
}

// Verify each hostname against the provider's docs before shipping.
const kPresets = <DnsProvider>[
  DnsProvider(
    id: 'cloudflare',
    name: 'Cloudflare',
    hostname: 'one.one.one.one',
    description: 'Best for speed. Fast lookups with a privacy focus.',
  ),
  DnsProvider(
    id: 'google',
    name: 'Google',
    hostname: 'dns.google',
    description: 'Best for reliability. Stable worldwide, no filtering.',
  ),
  DnsProvider(
    id: 'quad9',
    name: 'Quad9',
    hostname: 'dns.quad9.net',
    description: 'Best for security. Blocks known malware and phishing sites.',
  ),
  DnsProvider(
    id: 'adguard',
    name: 'AdGuard',
    hostname: 'dns.adguard-dns.com',
    description: 'Best for ad blocking. Filters ads and trackers in every app.',
  ),
  DnsProvider(
    id: 'mullvad',
    name: 'Mullvad',
    hostname: 'dns.mullvad.net',
    description: 'Best for privacy. States it keeps no logs, no filtering.',
  ),
  DnsProvider(
    id: 'cleanbrowsing',
    name: 'CleanBrowsing',
    hostname: 'family-filter-dns.cleanbrowsing.org',
    description:
        'Best for family use. Blocks adult content, enforces safe search.',
  ),
];

final _hostRe = RegExp(
  r'^(?=.{1,253}$)([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
);

/// Returns an error message, or null if valid.
String? validateHostname(String? input) {
  final v = (input ?? '').trim().toLowerCase();
  if (v.isEmpty) return 'Enter a hostname';
  if (RegExp(r'^[\d.]+$').hasMatch(v) || v.contains(':')) {
    return 'Private DNS needs a hostname like dns.example.com, not an IP';
  }
  if (!_hostRe.hasMatch(v)) return 'Not a valid hostname';
  return null;
}
