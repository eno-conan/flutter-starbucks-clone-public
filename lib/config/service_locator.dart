import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository/e_ticket_repository.dart';
import '../services/auth_service.dart';

GetIt locator = GetIt.instance;

/// DIコンテナのセットアップ
void setupLocator() {
  // HTTP Clientのシングルトンインスタンスを登録
  locator.registerLazySingleton<http.Client>(() => http.Client());
  // Supabaseクライアントの登録
  locator.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  // AuthServiceの登録
  locator.registerLazySingleton<AuthService>(() => AuthService());
  // ETicketRepositoryの登録
  locator.registerLazySingleton<ETicketRepository>(
    () => ETicketRepository(locator<SupabaseClient>()),
  );
}
