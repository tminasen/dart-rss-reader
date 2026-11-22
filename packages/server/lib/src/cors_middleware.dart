import 'package:shelf/shelf.dart';

/// [allowedOrigins] に含まれるオリジンからのリクエストにだけ CORS ヘッダを付ける。
///
/// 許可するメソッドは GET のみ。許可外オリジンからのプリフライトは 403 を返す。
/// 許可外オリジンや Origin の無い通常のリクエストは、そのまま内側のハンドラに渡す
/// （ブロックするのはブラウザ側）。
Middleware corsMiddleware({required Set<String> allowedOrigins}) {
  return (Handler inner) {
    return (Request request) async {
      final origin = request.headers['origin'];
      final isAllowed = origin != null && allowedOrigins.contains(origin);
      final isPreflight =
          request.method == 'OPTIONS' &&
          origin != null &&
          request.headers.containsKey('access-control-request-method');

      if (isPreflight) {
        if (!isAllowed) return Response.forbidden('Origin not allowed');
        return Response(
          204,
          headers: {
            'access-control-allow-origin': origin,
            'access-control-allow-methods': 'GET',
            'vary': 'Origin',
          },
        );
      }

      final response = await inner(request);
      if (!isAllowed) return response;
      return response.change(
        headers: {'access-control-allow-origin': origin, 'vary': 'Origin'},
      );
    };
  };
}
