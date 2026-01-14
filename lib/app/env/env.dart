import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
final class Env {
  @EnviedField(varName: 'PUBLISHABLE_KEY', obfuscate: true)
  static String publishableKey = _Env.publishableKey;

  @EnviedField(varName: 'SECRET_KEY', obfuscate: true)
  static String secretKey = _Env.secretKey;

  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true)
  static String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true)
  static String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'STARBUCKS_WEB_URL', obfuscate: true)
  static String starbucksWebUrl = _Env.starbucksWebUrl;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID', obfuscate: true)
  static String googleClientId = _Env.googleClientId;

  @EnviedField(varName: 'GOOGLE_WEB_SERVER_CLIENT_ID', obfuscate: true)
  static String googleWebServerClientId = _Env.googleWebServerClientId;

  @EnviedField(varName: 'FIREBASE_HOSTING_DOMAIN', obfuscate: true)
  static String firebaseHostingDomain = _Env.firebaseHostingDomain;

  @EnviedField(varName: 'SSL_SHA256_FINGER_PRINT', obfuscate: true)
  static String sslSha256FingerPrint = _Env.sslSha256FingerPrint;
}
