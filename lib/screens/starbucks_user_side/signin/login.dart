import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/id_keys.dart';
import '../../../constants/my_colors.dart';
import '../../../core/services/logger_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_permission_service.dart';
import '../../../shared/helpers/launch_url.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import '../home/main.dart';

/// ログイン画面（コメント暫定変更）
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String routeName = '/starbucks_login_page';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _supabase = GetIt.instance<SupabaseClient>();
  final _authService = GetIt.instance<AuthService>();
  late final NotificationPermissionService _notificationService;

  // 指紋認証関係の実装
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  // セキュアストレージ
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static const _credentialsKey = 'user_credentials';
  static const _biometricEnabledKey = 'biometric_enabled';

  String? _email;
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationPermissionService(_authService);
    _setupAuthStateListener();
    _initializeBiometricAuth();
  }

  /// 指紋認証の初期化と自動ログインの判定
  Future<void> _initializeBiometricAuth() async {
    // 指紋認証の可用性を直接取得
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = [];

    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();
      canCheckBiometrics = canCheckBiometrics && isDeviceSupported;

      if (canCheckBiometrics) {
        availableBiometrics = await auth.getAvailableBiometrics();
      }
    } on PlatformException catch (e) {
      canCheckBiometrics = false;
      LoggerService.warn('生体認証チェックエラー: $e');
    }

    // 状態を更新
    if (mounted) {
      setState(() {
        _isBiometricAvailable = canCheckBiometrics && availableBiometrics.isNotEmpty;
      });
    }

    // 指紋認証が利用可能かつ有効化されている場合は指紋認証を優先
    final biometricEnabled = await _isBiometricEnabled();
    final hasStoredCredentials = await _hasStoredCredentials();

    // ローカル変数を使用して判定
    final isBiometricReady =
        canCheckBiometrics &&
        availableBiometrics.isNotEmpty &&
        biometricEnabled &&
        hasStoredCredentials;

    if (isBiometricReady) {
      if (kDebugMode) {
        LoggerService.info('指紋認証が利用可能です。自動ログインを開始します。');
      }

      // 自動的に指紋認証を開始
      await _authenticateWithBiometrics();
    } else {
      // 指紋認証が利用できない場合でも、保存された認証情報がある場合は利用を提案
      if (!_isBiometricAvailable && hasStoredCredentials) {
        if (kDebugMode) {
          LoggerService.info('指紋認証は利用できませんが、保存された認証情報があります。');
        }
        await _promptToUseSavedCredentials();
      } else {
        // 従来のGoogle Sign-In初期化
        if (kDebugMode) {
          LoggerService.info(
            '指紋認証が利用できません。通常のログイン画面を表示します。'
            'canCheck=$canCheckBiometrics, '
            'available=${availableBiometrics.isNotEmpty}, '
            'enabled=$biometricEnabled, '
            'hasCredentials=$hasStoredCredentials',
          );
        }
        await _initializeGoogleSignIn();
      }
    }
  }

  /// 従来のGoogle Sign-In初期化
  Future<void> _initializeGoogleSignIn() async {
    try {
      await _authService.initializeGoogleSignIn();
      if (_authService.isAuthenticated()) {
        _navigateToHome();
      }
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Google Sign-In initialization/authentication error: $e');
      }
    }
  }

  /// 指紋認証の実行
  Future<void> _authenticateWithBiometrics() async {
    if (!_isBiometricAvailable) {
      _showSnackBar('指紋認証が利用できません');
      return;
    }

    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });

      authenticated = await auth.authenticate(
        localizedReason: '指紋認証でログインしてください',
        persistAcrossBackgrounding: true,
      );

      setState(() {
        _isAuthenticating = false;
      });

      if (authenticated && mounted) {
        await _performBiometricLogin();
      }
    } on LocalAuthException catch (e) {
      setState(() {
        _isAuthenticating = false;
      });

      if (e.code != LocalAuthExceptionCode.userCanceled &&
          e.code != LocalAuthExceptionCode.systemCanceled) {
        _showSnackBar('指紋認証に失敗しました: ${e.description ?? e.code.name}');
      }
      return;
    } on PlatformException catch (e) {
      setState(() {
        _isAuthenticating = false;
      });
      LoggerService.warn('指紋認証エラー: $e');
      _showSnackBar('指紋認証でエラーが発生しました');
      return;
    }

    if (!mounted) {
      return;
    }
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      context.go(Home.routeName);
      await Future<void>.delayed(Duration(milliseconds: 1500));
      // ログイン成功後に通知許可をリクエスト
      await _notificationService.requestPermissionAfterLogin();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthStateListener() {
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      _handleAuthStateChange(event, session);
      // トークンリフレッシュがあれば実施
      try {
        FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
          await _authService.setFcmTokenAndNotifySetting(fcmToken, true);
        });
      } catch (e) {
        if (kDebugMode) {
          LoggerService.warn('FCMトークンリフレッシュエラー: $e');
        }
      }
    });
  }

  Future<void> _handleAuthStateChange(AuthChangeEvent event, Session? session) async {
    String? newEmail;
    bool newIsLoading = false;

    switch (event) {
      case AuthChangeEvent.initialSession:
        if (kDebugMode) {
          LoggerService.info('login:AuthChangeEvent.initialSession');
        }
        newEmail = session?.user.email;
      case AuthChangeEvent.signedIn:
        newEmail = session?.user.email;
      case AuthChangeEvent.signedOut:
        newEmail = null;
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.tokenRefreshed:
        newEmail = session?.user.email;
      case AuthChangeEvent.userUpdated:
        newEmail = null;
      case AuthChangeEvent.userDeleted:
      case AuthChangeEvent.mfaChallengeVerified:
        return; // No state change needed
    }

    // 状態が変わった場合のみ setState を実行
    if (_email != newEmail || _isLoading != newIsLoading) {
      if (mounted) {
        setState(() {
          _email = newEmail;
          _isLoading = newIsLoading;
        });
      }
    }
  }

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      setState(() {
        _isLoading = loading;
      });
    }
  }

  /// 指紋認証成功時のログイン処理
  Future<void> _performBiometricLogin() async {
    try {
      final credentials = await _getStoredCredentials();
      if (credentials == null) {
        _showSnackBar('保存されている認証情報が見つかりません');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // 保存されている認証情報でログイン
      if (credentials['type'] == 'email') {
        await _authService.signInWithEmailAndPassword(
          credentials['email']!,
          credentials['password']!,
        );
      } else if (credentials['type'] == 'google') {
        // Google認証の場合は軽量認証を試行
        await _authService.initializeGoogleSignIn();
        if (!_authService.isAuthenticated()) {
          // 軽量認証に失敗した場合は完全なGoogle認証
          await _authService.signInWithGoogle();
        }
      }

      await _navigateToHome();
    } catch (e) {
      LoggerService.warn('指紋認証ログイン失敗: $e');
      _showSnackBar('自動ログインに失敗しました。手動でログインしてください。');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 認証情報をセキュアストレージに保存
  Future<void> _storeCredentials(String type, {String? email, String? password}) async {
    try {
      final credentials = {
        'type': type,
        if (email != null) 'email': email,
        if (password != null) 'password': password,
      };
      await _storage.write(key: _credentialsKey, value: jsonEncode(credentials));
      await _storage.write(key: _biometricEnabledKey, value: 'true');
    } catch (e) {
      LoggerService.warn('認証情報保存エラー: $e');
    }
  }

  /// 保存された認証情報を取得
  Future<Map<String, String>?> _getStoredCredentials() async {
    try {
      final credentialsJson = await _storage.read(key: _credentialsKey);
      if (credentialsJson != null) {
        return Map<String, String>.from(jsonDecode(credentialsJson) as Map<String, dynamic>);
      }
    } catch (e) {
      LoggerService.warn('認証情報取得エラー: $e');
    }
    return null;
  }

  /// 保存された認証情報が存在するかチェック
  Future<bool> _hasStoredCredentials() async {
    return _storage.containsKey(key: _credentialsKey);
  }

  /// 指紋認証が有効化されているかチェック
  Future<bool> _isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// 指紋認証の有効/無効を切り替え
  Future<void> _toggleBiometricAuth(bool enable) async {
    if (enable) {
      // 指紋認証を有効にする前に指紋認証テスト
      final authenticated = await auth.authenticate(
        localizedReason: '指紋認証を有効にするために認証してください',
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        await _storage.write(key: _biometricEnabledKey, value: 'true');
        _showSnackBar('指紋認証が有効になりました');
      } else {
        _showSnackBar('指紋認証に失敗しました');
      }
    } else {
      await _storage.delete(key: _biometricEnabledKey);
      await _storage.delete(key: _credentialsKey);
      _showSnackBar('指紋認証が無効になりました');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // キーボードが画面コンテンツの上にかぶせる（OverPixel防止にもなる）
      appBar: AppBar(
        scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐオプション
        backgroundColor: _isLoading ? Colors.black38 : Color(0xFFFFFFFF),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          _buildAuthenticationBody(),
          _Header(),
          if (_isLoading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(
                  child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationBody() {
    if (_isAuthenticating) {
      return const Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
            SizedBox(height: 16),
            MyCustomText(text: '指紋認証を行っています...', fontSize: 16),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            // 分割したEmailログインウィジェット
            EmailPasswordLoginForm(
              authService: _authService,
              onLoginSuccess: (email, password) async {
                // 指紋認証が利用可能な場合、認証情報を保存するか確認
                if (_isBiometricAvailable && email != null && password != null) {
                  await _promptToEnableBiometricAuth('email', email: email, password: password);
                } else if (!_isBiometricAvailable && email != null && password != null) {
                  // 指紋認証が利用できない場合でも認証情報保存を提案
                  await _promptToSaveCredentialsForNonBiometric(
                    'email',
                    email: email,
                    password: password,
                  );
                }
                await _navigateToHome();
              },
              onLoadingStateChanged: setLoading,
              showSnackBar: _showSnackBar,
            ),
            const SizedBox(height: 15),
            const Divider(color: MyColors.settingDivider, thickness: 2),
            const SizedBox(height: 15),
            // 分割したGoogleログインウィジェット
            GoogleLoginButton(
              authService: _authService,
              isLoading: _isLoading,
              email: _email,
              onLoginSuccess: () async {
                // 指紋認証が利用可能な場合、Google認証情報を保存するか確認
                if (_isBiometricAvailable) {
                  await _promptToEnableBiometricAuth('google');
                } else if (!_isBiometricAvailable) {
                  // 指紋認証が利用できない場合でもGoogle認証情報保存を提案
                  await _promptToSaveCredentialsForNonBiometric('google');
                }
                await _navigateToHome();
              },
              onLoadingStateChanged: setLoading,
              showSnackBar: _showSnackBar,
            ),
            const SizedBox(height: 15),
            // 指紋認証ボタン（利用可能な場合のみ表示）
            if (_isBiometricAvailable) ...[
              const Divider(color: MyColors.settingDivider, thickness: 2),
              const SizedBox(height: 15),
              _buildBiometricLoginButton(),
              const SizedBox(height: 15),
            ],
          ],
        ),
      ),
    );
  }

  /// 指紋認証ログインボタン
  Widget _buildBiometricLoginButton() {
    return SizedBox(
      height: 50,
      width: 200,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _authenticateWithBiometrics,
        icon: const Icon(Icons.fingerprint, size: 24),
        label: const MyCustomText(text: '指紋認証', fontSize: 16, fontWeight: FontWeight.w600),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.backgroundGold,
          foregroundColor: Colors.white,
          padding: const .all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // より丸みを持たせる
          ),
        ),
      ),
    );
  }

  /// 指紋認証有効化を促すダイアログ
  Future<void> _promptToEnableBiometricAuth(String type, {String? email, String? password}) async {
    final biometricEnabled = await _isBiometricEnabled();
    if (biometricEnabled) {
      return;
    }

    if (!mounted) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('指紋認証を有効にしますか？'),
        content: const Text('次回から指紋認証でログインできるようになります。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('後で')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('有効にする')),
        ],
      ),
    );

    if (result ?? false) {
      await _storeCredentials(type, email: email, password: password);
      await _toggleBiometricAuth(true);
    }
  }

  /// 指紋認証未対応端末向け：認証情報保存を促すダイアログ
  Future<void> _promptToSaveCredentialsForNonBiometric(
    String type, {
    String? email,
    String? password,
  }) async {
    final hasStoredCredentials = await _hasStoredCredentials();
    if (hasStoredCredentials) {
      return;
    }

    if (!mounted) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('認証情報を保存しますか？'),
        content: const Text('次回ログイン時に入力の手間を省けます。\n認証情報は端末に安全に保存されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('いいえ')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('保存する')),
        ],
      ),
    );

    if (result ?? false) {
      await _storeCredentials(type, email: email, password: password);
      _showSnackBar('認証情報を保存しました');
    }
  }

  /// 指紋認証未対応端末向け：保存された認証情報の利用を促すダイアログ
  Future<void> _promptToUseSavedCredentials() async {
    if (!mounted) {
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存された認証情報でログインしますか？'),
        content: const Text('前回保存した認証情報を使用してログインできます。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('手動入力')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('保存情報でログイン'),
          ),
        ],
      ),
    );

    if (result ?? false) {
      await _performSavedCredentialsLogin();
    }
  }

  /// 保存された認証情報でのログイン処理（指紋認証なし）
  Future<void> _performSavedCredentialsLogin() async {
    try {
      final credentials = await _getStoredCredentials();
      if (credentials == null) {
        _showSnackBar('保存されている認証情報が見つかりません');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // 保存されている認証情報でログイン
      if (credentials['type'] == 'email') {
        await _authService.signInWithEmailAndPassword(
          credentials['email']!,
          credentials['password']!,
        );
      } else if (credentials['type'] == 'google') {
        // Google認証の場合は軽量認証を試行
        await _authService.initializeGoogleSignIn();
        if (!_authService.isAuthenticated()) {
          // 軽量認証に失敗した場合は完全なGoogle認証
          await _authService.signInWithGoogle();
        }
      }

      await _navigateToHome();
    } catch (e) {
      LoggerService.warn('保存認証情報ログイン失敗: $e');
      _showSnackBar('自動ログインに失敗しました。手動でログインしてください。');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// ヘッダー
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // 少し浮かせる
    return Material(
      elevation: 1.0,
      child: Container(
        width: double.infinity,
        color: Color(0xFFFFFFFF),
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: const MyCustomText(text: '会員ログイン', fontSize: 28),
      ),
    );
  }
}

/// メールアドレスとパスワードによるログインフォーム
class EmailPasswordLoginForm extends StatefulWidget {
  const EmailPasswordLoginForm({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
    required this.onLoadingStateChanged,
    required this.showSnackBar,
  });
  final AuthService authService;
  final Future<void> Function(String?, String?) onLoginSuccess;
  final void Function(bool) onLoadingStateChanged;
  final void Function(String) showSnackBar;

  @override
  State<EmailPasswordLoginForm> createState() => _EmailPasswordLoginFormState();
}

class _EmailPasswordLoginFormState extends State<EmailPasswordLoginForm> {
  bool _isHiddenPassword = true; // パスワードの表示・非表示

  // メールアドレス・パスワード
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    // フォームの値が変更されるたびに検証
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // フォームのバリデーションを実行
  void _validateForm() {
    final newFormValid =
        _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        // ignore: use_if_null_to_convert_nulls_to_bools
        _formKey.currentState?.validate() == true;

    // 状態が変わった場合のみ setState を実行
    if (_isFormValid != newFormValid) {
      setState(() {
        _isFormValid = newFormValid;
      });
    }
  }

  /// パスワードの表示・非表示切り替え
  void _togglePasswordView() {
    setState(() {
      _isHiddenPassword = !_isHiddenPassword;
    });
  }

  /// Email、パスワードによる認証処理
  Future<void> _handleAuthenticationByEmailAndPassword() async {
    // キーボードを閉じる
    FocusScope.of(context).unfocus();

    widget.onLoadingStateChanged(true);

    final String? userData = await widget.authService.retrieveLoginUser();
    try {
      if (userData != null) {
        await widget.authService.signOutWithEmailAndPassword();
        widget.showSnackBar('サインアウトしました。');
      } else {
        await widget.authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
      }

      // 遷移前にローディングを解除
      if (mounted) {
        widget.onLoadingStateChanged(false);
      }

      // メイン画面への遷移（認証情報を渡す）
      await widget.onLoginSuccess(_emailController.text, _passwordController.text);
    } on PlatformException catch (e) {
      if (mounted) {
        widget.onLoadingStateChanged(false);
      }

      if (kDebugMode) {
        LoggerService.warn('ログイン処理でエラー発生: $e');
      }
      widget.showSnackBar('認証処理に失敗しました(メールアドレス)');
    } catch (err) {
      if (mounted) {
        widget.onLoadingStateChanged(false);
      }
      widget.showSnackBar('$err:認証処理に失敗(メールアドレス)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAuthByEmailAndPasswordForm(),
        const SizedBox(height: 20),
        _buildEmailAndPasswordLoginFabButton(),
        const SizedBox(height: 10),
        ResetPasswordLink(),
      ],
    );
  }

  Widget _buildEmailAndPasswordLoginFabButton() {
    return SizedBox(
      height: 50,
      width: 150,
      child: FilledButton(
        onPressed: _isFormValid
            ? () {
                if (_formKey.currentState!.validate()) {
                  _handleAuthenticationByEmailAndPassword();
                }
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: _isFormValid ? MyColors.greenButton : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: const MyCustomText(
          text: 'ログイン',
          textColor: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Email, Passwordによるログインフォーム
  Widget _buildAuthByEmailAndPasswordForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Column(
          spacing: 10,
          crossAxisAlignment: .start,
          children: [
            TextFormField(
              key: Key('login_form_email'),
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'メールアドレス',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: MyColors.loginFormField),
                ),
              ),
              cursorColor: MyColors.loginFormField,
              keyboardType: TextInputType.emailAddress,
              keyboardAppearance: Brightness.light,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'メールアドレスを入力してください';
                }
                return null;
              },
            ),

            TextFormField(
              key: Key('login_form_password'),
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'パスワード',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: MyColors.loginFormField),
                ),
                suffixIcon: GestureDetector(
                  onTap: _togglePasswordView,
                  child: Icon(_isHiddenPassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              cursorColor: MyColors.loginFormField,
              obscureText: _isHiddenPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'パスワードを入力してください';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Googleアカウントによるログインボタン
class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({
    super.key,
    required this.authService,
    required this.isLoading,
    required this.email,
    required this.onLoginSuccess,
    required this.onLoadingStateChanged,
    required this.showSnackBar,
  });
  final AuthService authService;
  final bool isLoading;
  final String? email;
  final Future<void> Function() onLoginSuccess;
  final void Function(bool) onLoadingStateChanged;
  final void Function(String) showSnackBar;

  /// Googleアカウントによる認証処理
  Future<void> _handleAuthenticationByGoogle(BuildContext context) async {
    onLoadingStateChanged(true);
    try {
      if (email != null) {
        await authService.signOutWithGoogle();
        showSnackBar('サインアウトしました。');
      } else {
        // Sign in logic
        await authService.signInWithGoogle();
        await onLoginSuccess();
      }
    } on PlatformException catch (e) {
      if (context.mounted) {
        onLoadingStateChanged(false);
      }

      if (kDebugMode) {
        LoggerService.warn(email != null ? 'ログアウト処理でエラー発生: $e' : 'ログイン処理でエラー発生: $e');
      }
      showSnackBar('認証処理に失敗しました(PlatformException)');
    } catch (err) {
      if (context.mounted) {
        onLoadingStateChanged(false);
      }
      showSnackBar('$err:認証処理に失敗しました(OtherException)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: isLoading ? null : () => _handleAuthenticationByGoogle(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/google_logo.png', height: 24),
          const SizedBox(width: 15),
          Text(email != null ? '' : 'Googleログイン', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

/// パスワードリセットへ遷移するリンク
class ResetPasswordLink extends StatelessWidget {
  const ResetPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchURL(Uri.parse(AppConstants.starbucksWebUrl));
      },
      child: Text(
        'パスワードをお忘れの方',
        style: TextStyle(decoration: TextDecoration.underline, color: Color(0xFF9B9B9B)),
      ),
    );
  }
}
