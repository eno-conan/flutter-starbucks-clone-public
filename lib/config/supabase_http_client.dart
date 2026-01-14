import 'package:http/http.dart' as http;

/// Supabase用のカスタムHTTPクライアント（タイムアウト対応）
class SupabaseHttpClient extends http.BaseClient {
  SupabaseHttpClient({this.timeout = const Duration(seconds: 5)}) {
    _inner = http.Client();
  }

  late final http.Client _inner;
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(timeout);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
