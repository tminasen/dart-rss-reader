/// API のベース URL から WebSocket（`/ws`）の接続先 URL を導出する。
///
/// `https` は `wss`、それ以外は `ws` にする。パスは常に `/ws`。
Uri webSocketUriFrom(Uri apiBaseUrl) {
  return apiBaseUrl.replace(
    scheme: apiBaseUrl.scheme == 'https' ? 'wss' : 'ws',
    path: '/ws',
  );
}
