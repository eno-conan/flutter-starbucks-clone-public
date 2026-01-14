// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/my_colors.dart';
import '../../../constants/supabase_rpcs.dart';
import '../../../constants/supabase_tables.dart';
import '../../../core/models/pre_signup_users.dart';
import '../../../core/services/logger_service.dart';
import '../../../shared/widgets/indicators/circular_progress_indicator.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'pre_signup_completion.dart';

/// 新規会員登録の仮登録メール送信フォーム
class PreSignUp extends StatefulWidget {
  const PreSignUp({super.key});
  static String routeName = '/starbucks_pre_signup_page';

  @override
  State<PreSignUp> createState() => _PreSignUpState();
}

class _PreSignUpState extends State<PreSignUp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // キーボードが画面コンテンツの上にかぶせる（OverPixel防止にもなる）
      appBar: AppBar(
        scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐオプション
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(child: Column(children: const [_Header(), _Form()])),
    );
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
        color: Colors.white,
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 10),
        child: const MyCustomText(text: '会員登録', fontSize: 28),
      ),
    );
  }
}

//　フォーム
class _Form extends StatefulWidget {
  const _Form();

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isAgreed = false;
  String? _emailError;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    setState(() {
      // フォームが有効かどうかをチェック（メールアドレスの形式が正しく、利用規約に同意している）
      _isFormValid = _isEmailValid(_emailController.text) && _isAgreed;
    });
  }

  bool _isEmailValid(String email) {
    // 簡単な正規表現でメールアドレスを検証
    return RegExp(r'^.+@.+\..+$').hasMatch(email);
  }

  void _validateEmail() {
    if (!_isEmailValid(_emailController.text) && _emailController.text.isNotEmpty) {
      setState(() {
        _emailError = '不正なメールアドレス';
      });
    } else {
      setState(() {
        _emailError = null;
      });
    }
    _updateFormValidity();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'メールによる本人確認を行います。\nこのメールアドレスはMy Starbucksのログインに必要になります。',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Text('メールアドレス', style: TextStyle(fontSize: 16)),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                focusColor: MyColors.greenText,
                fillColor: MyColors.greenText,
                hoverColor: MyColors.greenText,
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: MyColors.greenText),
                ),
                errorText: _emailError,
                errorStyle: TextStyle(color: Colors.red),
              ),
              keyboardType: TextInputType.emailAddress,
              cursorColor: MyColors.greenText,
              onChanged: (value) {
                setState(() {}); // リアルタイムで表示を更新
              },
              onFieldSubmitted: (value) => _validateEmail(),
              onTap: () {
                // 必要に応じて処理を追加
              },
              onEditingComplete: () => _validateEmail(),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                '受信設定をされている場合は、「starbucks.co.jp」からのメールが受け取れる設定であることを事前にご確認ください。',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text('利用規約', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Transform.scale(
                  scale: 1.6,
                  child: Checkbox(
                    value: _isAgreed,
                    onChanged: (value) {
                      setState(() {
                        _isAgreed = value ?? false;
                        _updateFormValidity();
                      });
                    },
                    side: BorderSide(color: MyColors.greenButton, width: 0.8),
                    activeColor: MyColors.greenButton,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const Expanded(child: Text('以下の利用規約に同意する', style: TextStyle(fontSize: 16))),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: Text('My Starbucks利用規約', style: TextStyle(fontSize: 16, color: Colors.green)),
            ),
            const SizedBox(height: 24),
            const Text('こちらでよろしいでしょうか', style: TextStyle(fontSize: 14)),
            if (_emailController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: MyCustomText(
                  text: _emailController.text,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 32),
            _ButtonSendEmail(isFormValid: _isFormValid, email: _emailController.text), // メール送信ボタン
          ],
        ),
      ),
    );
  }
}

//32桁のトークン値を作成
String craeteTokenValue() {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random.secure();
  return List.generate(32, (index) => chars[rand.nextInt(chars.length)]).join();
}

// メール送信ボタン
class _ButtonSendEmail extends StatelessWidget {
  const _ButtonSendEmail({required this.isFormValid, required this.email});
  final bool isFormValid;
  final String email;

  // 登録済メールアドレスを検索し、同一のアドレスが存在するか判定
  Future<bool> _isUniqueEmailAddress(BuildContext context) async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final response = await supabase.rpc<bool>(
        Rpcs.checkSignupEmailExists,
        params: {'input_email': email},
      );
      return !response;
    } catch (e) {
      if (kDebugMode) {
        LoggerService.warn('Error checking email: $e');
      }
      // エラー処理
      return false;
    }
  }

  //仮会員として、テーブルへ情報登録
  Future<void> _handleSendEmail(BuildContext context) async {
    // テーブルへデータを登録(登録をトリガーにしてメール送信)
    final preSignupUsers = PreSignupUsers(token: craeteTokenValue(), email: email);
    final SupabaseClient supabase = Supabase.instance.client;
    final response = await supabase
        .from(Tables.preSignupUsers)
        .insert(preSignupUsers.toJson())
        .select()
        .single();
    if (kDebugMode) {
      LoggerService.info('仮会員登録完了: $response');
    }
    // throw Exception('メール送信に失敗しました'); // デバッグ用の例外
  }

  void navigateToCompletePage(BuildContext context) {
    context.push(PreSignUpCompletion.routeName, extra: {'email': email});
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: isFormValid
            ? () async {
                showCircularProgressIndicator(context);
                try {
                  final isUnique = await _isUniqueEmailAddress(context);
                  if (isUnique) {
                    await _handleSendEmail(context);
                    navigateToCompletePage(context);
                  } else {
                    context.pop();
                    _showAlreadyInputRegisteredEmailAddressDialog(context);
                  }
                } catch (e) {
                  context.pop();
                  if (kDebugMode) {
                    LoggerService.warn('仮会員登録処理でエラーが発生しました。: $e');
                  }
                }
              }
            : null,
        style: FilledButton.styleFrom(
          backgroundColor: isFormValid ? MyColors.greenButton : Color(0xFF999999),
          minimumSize: const Size(0, 60),
          padding: const EdgeInsets.symmetric(horizontal: 25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const MyCustomText(
          text: '送信する',
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          textColor: Colors.white,
        ),
      ),
    );
  }
}

// 登録済メールアドレスが入力された場合のダイアログ表示
void _showAlreadyInputRegisteredEmailAddressDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルト:40
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const MyCustomText(text: 'エラーが発生しました。', fontSize: 24),
              const SizedBox(height: 10),
              const MyCustomText(text: 'ご入力されたメールアドレスは既に登録されています。', fontSize: 14, softwrap: true),
              const SizedBox(height: 30),
              Align(
                // ← 追加
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: MyColors.greenButton,
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    minimumSize: const Size(0, 35), //垂直方向の余白調整
                  ),
                  child: const MyCustomText(text: 'OK', fontSize: 16, textColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
