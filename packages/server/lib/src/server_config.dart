const defaultHost = '127.0.0.1';
const defaultPort = 8080;
const defaultAllowedOrigins = {'http://localhost:8081'};

final _whitespacePattern = RegExp(r'\s');

/// サーバーの待ち受け設定と CORS 許可オリジン。
final class ServerConfig {
  const ServerConfig({
    required this.host,
    required this.port,
    required this.allowedOrigins,
  });

  /// 環境変数 `HOST`（未指定なら [defaultHost]）、
  /// `PORT`（1〜65535 の整数、未指定なら [defaultPort]）、
  /// `ALLOWED_ORIGINS`（カンマ区切りの http/https オリジン、未指定なら [defaultAllowedOrigins]）
  /// から作る。空文字は未指定として扱う。不正値があれば [ArgumentError] を投げる。
  factory ServerConfig.fromEnvironment(Map<String, String> environment) {
    final host = _nonEmpty(environment['HOST']) ?? defaultHost;
    if (_whitespacePattern.hasMatch(host)) {
      throw ArgumentError.value(host, 'HOST', 'must not contain whitespace');
    }
    final portRaw = _nonEmpty(environment['PORT']);
    final originsRaw = _nonEmpty(environment['ALLOWED_ORIGINS']);
    return ServerConfig(
      host: host,
      port: portRaw == null ? defaultPort : _parsePort(portRaw),
      allowedOrigins: originsRaw == null
          ? defaultAllowedOrigins
          : _parseAllowedOrigins(originsRaw),
    );
  }

  final String host;
  final int port;
  final Set<String> allowedOrigins;

  @override
  bool operator ==(Object other) =>
      other is ServerConfig &&
      other.host == host &&
      other.port == port &&
      _setEquals(other.allowedOrigins, allowedOrigins);

  @override
  int get hashCode =>
      Object.hash(host, port, Object.hashAllUnordered(allowedOrigins));
}

Set<String> _parseAllowedOrigins(String raw) {
  final origins = raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toSet();
  if (origins.isEmpty) {
    throw ArgumentError.value(
      raw,
      'ALLOWED_ORIGINS',
      'must contain at least one valid origin',
    );
  }
  for (final origin in origins) {
    if (!_isValidOrigin(origin)) {
      throw ArgumentError.value(
        origin,
        'ALLOWED_ORIGINS',
        'must contain valid http(s) origins',
      );
    }
  }
  return Set.unmodifiable(origins);
}

bool _isValidOrigin(String origin) {
  if (_whitespacePattern.hasMatch(origin)) return false;
  if (!origin.startsWith('http://') && !origin.startsWith('https://')) {
    return false;
  }
  if (origin.contains('@')) return false;
  final uri = Uri.tryParse(origin);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.path.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      uri.userInfo.isEmpty;
}

int _parsePort(String value) {
  final n = int.tryParse(value);
  if (n == null || n < 1 || n > 65535) {
    throw ArgumentError.value(value, 'PORT', 'must be an integer in 1..65535');
  }
  return n;
}

bool _setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

String? _nonEmpty(String? s) => (s == null || s.isEmpty) ? null : s;
