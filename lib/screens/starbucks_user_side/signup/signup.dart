import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/my_colors.dart';
import '../../../constants/supabase_tables.dart';
import '../../../core/models/postal_code.dart';
import '../../../core/models/pre_signup_user.dart';
import '../../../core/models/user_mail_settings.dart';
import '../../../core/models/user_profile_details.dart';
import '../../../core/services/logger_service.dart';
import '../../../provider/selected_tab_provider.dart';
import '../../../shared/widgets/dialogs/error_dialog.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import '../home/main.dart';
import 'signup_completion.dart';
import 'signup_error.dart';

final preSignupUserProvider = FutureProvider.family<PreSignupUser?, String>((ref, token) async {
  if (token.isEmpty) {
    return null;
  }

  // トークン値を元に仮会員情報を取得
  try {
    final SupabaseClient supabase = Supabase.instance.client;
    final response = await supabase
        .from(Tables.preSignupUsers)
        .select()
        .eq('token', token)
        .maybeSingle();
    return response != null ? PreSignupUser.fromJson(response) : null;
  } catch (e) {
    if (kDebugMode) {
      LoggerService.warn('Error fetching pre-signup user: $e');
    }
    return null;
  }
});

///会員情報入力画面(ディープリンク経由でトークン値からメールアドレスを取得)
class SignUp extends ConsumerWidget {
  const SignUp({super.key});
  static String routeName = '/starbucks_signup_page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // トークン情報を元に、DBテーブルからメールアドレスを取得
    final Map<String, dynamic>? extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String token = extra?['token'] as String? ?? '';
    if (kDebugMode) {
      LoggerService.info('token:$token');
    }

    final preSignupUserAsync = ref.watch(preSignupUserProvider(token));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // Home画面に戻る
        context.go(Home.routeName);
      },
      child: Scaffold(
        // この行を変更: キーボードによる画面のリサイズを有効化
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐオプション
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              ref.read(selectedTabProvider.notifier).setTab(0);
              // Home画面に戻る
              context.go(Home.routeName);
            },
          ),
        ),
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: preSignupUserAsync.when(
            data: (userData) {
              if (userData == null) {
                // データなしの場合 または トークン期限切れの場合
                // 登録失敗画面へ遷移
                return const SignUpError();
              }
              return Column(
                children: [
                  _Header(),
                  _Form(preSignupUser: userData),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
            ),
            error: (error, stackTrace) => _ErrorView(error: error.toString()),
          ),
        ),
      ),
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

// パスワード検証のためのExtension
extension PasswordValidators on String {
  // パスワードの各要件を確認するゲッター
  bool get isLengthValid => RegExp(r'^.{6,20}$').hasMatch(this);
  bool get hasNumberOrSymbol => RegExp("[0-9!\"#\$%&'()*+\\-./:;<=>?@_`\\[\\]{}]").hasMatch(this);
  bool get hasLowercase => RegExp(r'[a-z]').hasMatch(this);
  bool get hasUppercase => RegExp(r'[A-Z]').hasMatch(this);

  // パスワードが全ての要件を満たしているか確認
  bool get isValidPassword => isLengthValid && hasNumberOrSymbol && hasLowercase && hasUppercase;

  // パスワードのバリデーションエラーメッセージを返す
  String? get passwordError => isValidPassword || isEmpty ? null : '不正なパスワード';

  // 各検証要件の状態を返すマップ
  Map<String, bool> get passwordRequirements => {
    'length': isLengthValid,
    'numberSymbol': hasNumberOrSymbol,
    'lowercase': hasLowercase,
    'uppercase': hasUppercase,
  };
}

//　フォーム
class _Form extends StatefulWidget {
  const _Form({required this.preSignupUser});
  final PreSignupUser preSignupUser;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool _isHiddenPassword = true; // パスワードの表示・非表示
  // パスワードの各制約
  bool _lengthCheck = false; // 6～20字以内の半角文字
  bool _numberSymbolCheck = false; // 1文字以上の数字か記号を含むこと
  bool _lowercaseCheck = false; // 1文字以上の小文字を含むこと
  bool _uppercaseCheck = false; // 1文字以上の大文字を含むこと
  String? _passwordError;

  // メール通知設定関係
  bool _isRelatedInfo = true;
  bool _isLatestProductInfo = true;
  bool _isApplyHtml = true;
  // ユーザ情報----------------------------
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameKanaController = TextEditingController();
  final TextEditingController _firstNameKanaController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  DateTime selectedDate = DateTime(1990);
  int selectedYear = 1990;
  int selectedMonth = 1;
  int selectedDay = 1;
  final List<int> years = List.generate(100, (index) => 1905 + index);
  final List<int> months = List.generate(12, (index) => index + 1);
  final List<int> days = List.generate(31, (index) => index + 1);
  // 性別
  String? _selectedGender = '未選択'; // 初期値
  final List<String> _genderOptions = ['未選択', '男性', '女性', 'その他'];
  // 電話番号
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _phone3Controller = TextEditingController();
  final FocusNode _phone1Focus = FocusNode();
  final FocusNode _phone2Focus = FocusNode();
  final FocusNode _phone3Focus = FocusNode();
  // 郵便番号
  final TextEditingController _postalCodeController = TextEditingController();
  bool _isFormatting = false;
  // 都道府県
  final TextEditingController _prefectureIdController = TextEditingController();
  // 市区町村
  final TextEditingController _cityController = TextEditingController();
  // 番地
  final TextEditingController _blockNumberController = TextEditingController();
  // アパートマンション名
  final TextEditingController _apartmentController = TextEditingController();
  // 送信可能か
  bool _isFormValid = false;
  // フォーム検証用のタイマー（デバウンシング）
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateFormValidity);

    // 必須フィールドの変更を監視してフォーム有効性を更新
    _lastNameController.addListener(_updateFormValidity);
    _firstNameController.addListener(_updateFormValidity);
    _lastNameKanaController.addListener(_updateFormValidity);
    _firstNameKanaController.addListener(_updateFormValidity);
    _prefectureIdController.addListener(_updateFormValidity);

    _birthdayController.text = '$selectedYear年$selectedMonth月$selectedDay日';

    // 電話番号の1つ目の4桁入力を検知し、次の入力欄へ
    _phone1Controller.addListener(() {
      _updateFormValidity();
      if (_phone1Controller.text.length == 4) {
        FocusScope.of(context).requestFocus(_phone2Focus);
      }
    });

    // 電話番号の2つ目の4桁入力を検知し、次の入力欄へ
    _phone2Controller.addListener(() {
      _updateFormValidity();
      if (_phone2Controller.text.length == 4) {
        FocusScope.of(context).requestFocus(_phone3Focus);
      }
    });

    // 電話番号の3つ目の変更を監視
    _phone3Controller.addListener(_updateFormValidity);

    // 郵便番号の入力時の入力状態を監視
    _postalCodeController.addListener(_onPostalCodeChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _passwordController.dispose();
    _lastNameController.dispose();
    _firstNameController.dispose();
    _lastNameKanaController.dispose();
    _firstNameKanaController.dispose();
    _birthdayController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _phone3Controller.dispose();
    _postalCodeController.dispose();
    _prefectureIdController.dispose();
    _cityController.dispose();
    _blockNumberController.dispose();
    _apartmentController.dispose();

    _phone1Focus.dispose();
    _phone2Focus.dispose();
    _phone3Focus.dispose();
    super.dispose();
  }

  /// パスワードの表示・非表示切り替え
  void _togglePasswordView() {
    if (mounted) {
      setState(() {
        _isHiddenPassword = !_isHiddenPassword;
      });
    }
  }

  void _updateFormValidity() {
    // デバウンシングでパフォーマンス向上
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _performFormValidation);
  }

  void _performFormValidation() {
    if (!mounted) return;

    final password = _passwordController.text;

    // パスワードの各要件をチェック
    final lengthCheck = password.isLengthValid;
    final numberSymbolCheck = password.hasNumberOrSymbol;
    final lowercaseCheck = password.hasLowercase;
    final uppercaseCheck = password.hasUppercase;

    // パスワードの有効性チェック
    final bool isPasswordValid = password.isValidPassword;

    // 必須フィールドのチェック（市区町村、番地、アパートマンション名以外）
    final bool areRequiredFieldsFilled =
        _lastNameController.text.isNotEmpty &&
        _firstNameController.text.isNotEmpty &&
        _lastNameKanaController.text.isNotEmpty &&
        _firstNameKanaController.text.isNotEmpty &&
        _selectedGender != null &&
        _selectedGender != '未選択' &&
        _phone1Controller.text.isNotEmpty &&
        _phone2Controller.text.isNotEmpty &&
        _phone3Controller.text.isNotEmpty &&
        _postalCodeController.text.isNotEmpty &&
        _prefectureIdController.text.isNotEmpty;

    final newFormValid = isPasswordValid && areRequiredFieldsFilled;

    // 状態が変わった場合のみ setState を実行
    if (_lengthCheck != lengthCheck ||
        _numberSymbolCheck != numberSymbolCheck ||
        _lowercaseCheck != lowercaseCheck ||
        _uppercaseCheck != uppercaseCheck ||
        _isFormValid != newFormValid) {
      setState(() {
        _lengthCheck = lengthCheck;
        _numberSymbolCheck = numberSymbolCheck;
        _lowercaseCheck = lowercaseCheck;
        _uppercaseCheck = uppercaseCheck;
        _isFormValid = newFormValid;
      });
    }
  }

  void _validatePassword() {
    final newPasswordError = _passwordController.text.passwordError;
    if (_passwordError != newPasswordError) {
      setState(() {
        _passwordError = newPasswordError;
      });
    }
  }

  // 生年月日をクリアする関数(必要かな？)
  // void _clearBirthday() {
  // setState(() {
  // _birthdayController.clear();
  // });
  // }

  void _setBirthDayController() {
    setState(() {
      _birthdayController.text = '$selectedYear年$selectedMonth月$selectedDay日';
    });
  }

  void _showBirthDayDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('生年月日を選択'),
        content: SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              // 年ピッカー
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedYear = years[index];
                  },
                  controller: FixedExtentScrollController(initialItem: years.indexOf(selectedYear)),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= years.length) {
                        return null;
                      }
                      return Center(child: Text('${years[index]}年'));
                    },
                  ),
                ),
              ),
              // 月ピッカー
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedMonth = months[index];
                  },
                  controller: FixedExtentScrollController(initialItem: selectedMonth - 1),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= months.length) {
                        return null;
                      }
                      return Center(child: Text('${months[index]}月'));
                    },
                  ),
                ),
              ),
              // 日ピッカー
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selectedDay = days[index];
                  },
                  controller: FixedExtentScrollController(initialItem: selectedDay - 1),
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= days.length) {
                        return null;
                      }
                      return Center(child: Text('${days[index]}日'));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('キャンセル')),
          TextButton(
            onPressed: () {
              _setBirthDayController();
              _updateFormValidity(); // フォーム有効性を更新
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // 郵便番号の値更新時の処理
  void _onPostalCodeChanged() {
    if (_isFormatting) {
      return;
    }

    final raw = _postalCodeController.text.replaceAll('-', '');
    if (raw.length > 7) {
      return;
    }

    // ハイフンの自動挿入
    String formatted = raw;
    if (raw.length > 3) {
      formatted = '${raw.substring(0, 3)}-${raw.substring(3)}';
    }

    _isFormatting = true;
    _postalCodeController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormatting = false;
    _updateFormValidity(); // フォーム有効性を更新

    // ハイフン込みで8文字 (例: 123-4567) になったらAPI呼び出し
    if (formatted.length == 8) {
      _fetchAddress(formatted);
    } else {
      // 不完全な場合は住所を消す（仮）
      // setState(() {
      //   // _address = null;
      // });
    }
  }

  // 郵便番号から住所取得
  Future<void> _fetchAddress(String postalCode) async {
    if (kDebugMode) {
      LoggerService.info('Fetching address for postal code: $postalCode');
    }
    setState(() {
      _prefectureIdController.text = '';
      // 市区町村
      _cityController.text = '';
      // 番地
      _blockNumberController.text = '';
    });

    try {
      // 郵便番号の形式チェック（任意）
      if (!RegExp(r'^\d{3}-\d{4}$').hasMatch(postalCode)) {
        throw Exception('形式が正しくありません');
      }

      // API呼び出し処理を書く
      final String postalCodeWithoutHyphen = postalCode.replaceAll('-', '');
      final url = 'https://jp-postal-code-api.ttskch.com/api/v1/$postalCodeWithoutHyphen.json';
      final response = await http.get(Uri.parse(url));
      if (kDebugMode) {
        LoggerService.info(response.body);
      }
      final address = PostalCode.fromJson(json.decode(response.body) as Map<String, dynamic>);
      setState(() {
        _prefectureIdController.text = address.addresses[0].prefectureCode;
        // 市区町村
        _cityController.text = address.addresses[0].ja.address1;
        // 番地
        _blockNumberController.text = address.addresses[0].ja.address2;
      });
    } catch (e) {
      setState(() {});
    } finally {
      setState(() {
        // _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        // ScrollViewKeyboardDismissBehavior.onDrag : // スクロールを開始すると、キーボードがしまわれる。
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: .start,
              children: [
                // メールアドレスとパスワード
                const MyCustomText(
                  text: 'メールアドレスとパスワード',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 16),
                const MyCustomText(
                  text: 'メールアドレス(ログインに使用)',
                  fontSize: 14,
                  textColor: MyColors.greyText,
                ),
                const SizedBox(height: 8),
                MyCustomText(
                  text: widget.preSignupUser.email,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 16),
                const MyCustomText(text: 'パスワード', fontSize: 14, textColor: MyColors.greyText),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    focusColor: MyColors.greenText,
                    fillColor: MyColors.greenText,
                    hoverColor: MyColors.greenText,
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: MyColors.greenText),
                    ),
                    errorText: _passwordError,
                    errorStyle: TextStyle(color: Colors.red),
                    suffixIcon: GestureDetector(
                      onTap: _togglePasswordView,
                      child: Icon(_isHiddenPassword ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  cursorColor: MyColors.greenText,
                  onChanged: (value) {
                    _validatePassword();
                  },
                  // TextFormFieldのvalidatorを使う方法もある
                  // validator: (value) => value?.passwordError,
                  obscureText: _isHiddenPassword,
                  onFieldSubmitted: (value) => _validatePassword(),
                  onEditingComplete: () => _validatePassword(),
                  onTap: () {},
                ),
                _PasswordRequirementItem(isChecked: _lengthCheck, text: ' 6 ～ 20字以内の半角文字'),
                _PasswordRequirementItem(isChecked: _numberSymbolCheck, text: '1文字以上の数字か記号'),
                _PasswordRequirementItem(isChecked: _lowercaseCheck, text: ' 1文字以上の小文字'),
                _PasswordRequirementItem(isChecked: _uppercaseCheck, text: '1文字以上の大文字'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    '受信設定をされている場合は、「starbucks.co.jp」からのメールが受け取れる設定であることを事前にご確認ください。',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // メール配信設定
                const MyCustomText(text: 'メール配信設定', fontSize: 20, fontWeight: FontWeight.bold),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.6,
                      child: Checkbox(
                        value: _isRelatedInfo,
                        onChanged: (value) {
                          final newValue = value ?? false;
                          if (_isRelatedInfo != newValue) {
                            setState(() {
                              _isRelatedInfo = newValue;
                            });
                            _updateFormValidity();
                          }
                        },
                        side: BorderSide(color: MyColors.greenButton, width: 0.8),
                        activeColor: MyColors.greenButton,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const Expanded(child: Text('関連情報', style: TextStyle(fontSize: 16))),
                  ],
                ),
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.6,
                      child: Checkbox(
                        value: _isLatestProductInfo,
                        onChanged: (value) {
                          final newValue = value ?? false;
                          if (_isLatestProductInfo != newValue) {
                            setState(() {
                              _isLatestProductInfo = newValue;
                            });
                            _updateFormValidity();
                          }
                        },
                        side: BorderSide(color: MyColors.greenButton, width: 0.8),
                        activeColor: MyColors.greenButton,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const Expanded(child: Text('商品先行告知', style: TextStyle(fontSize: 16))),
                  ],
                ),
                Row(
                  children: [
                    Transform.scale(
                      scale: 1.6,
                      child: Checkbox(
                        value: _isApplyHtml,
                        onChanged: (value) {
                          final newValue = value ?? false;
                          if (_isApplyHtml != newValue) {
                            setState(() {
                              _isApplyHtml = newValue;
                            });
                            _updateFormValidity();
                          }
                        },
                        side: BorderSide(color: MyColors.greenButton, width: 0.8),
                        activeColor: MyColors.greenButton,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const Expanded(child: Text('HTMLでのメール受け取り', style: TextStyle(fontSize: 16))),
                  ],
                ),
                const SizedBox(height: 16),
                const MyCustomText(text: '本人確認情報', fontSize: 20, fontWeight: FontWeight.bold),
                const SizedBox(height: 16),
                const MyCustomText(
                  text: '本人確認情報は、お問い合わせ時に本人確認項目として・・・',
                  fontSize: 14,
                  textColor: MyColors.greyText,
                  softwrap: true,
                ),
                //
                const SizedBox(height: 32),
                // 姓名フィールド
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              labelText: '姓', // 入力前はフォーム部分にあり、フォーカス時に上に移動
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: MyColors.greenText),
                              ),
                            ),
                            cursorColor: MyColors.greenText,
                            // キーボード表示時のスクロール対応のために追加
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              labelText: '名',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: MyColors.greenText),
                              ),
                            ),
                            cursorColor: MyColors.greenText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // フリガナフィールド
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          TextFormField(
                            controller: _lastNameKanaController,
                            decoration: InputDecoration(
                              labelText: 'セイ',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: MyColors.greenText),
                              ),
                            ),
                            cursorColor: MyColors.greenText,
                            // キーボード表示時のスクロール対応のために追加
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          TextFormField(
                            controller: _firstNameKanaController,
                            decoration: InputDecoration(
                              labelText: 'メイ',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: MyColors.greenText),
                              ),
                            ),
                            cursorColor: MyColors.greenText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 生年月日フィールド
                const SizedBox(height: 16),
                const MyCustomText(text: '生年月日', fontSize: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          TextFormField(
                            controller: _birthdayController,
                            readOnly: true, // 読み取り専用
                            onTap: () {
                              _showBirthDayDialog();
                            }, // タップ時の処理
                            decoration: InputDecoration(
                              border: UnderlineInputBorder(),
                              focusedBorder: UnderlineInputBorder(
                                // borderSide: BorderSide(color: Colors.teal),
                              ),
                              suffixIcon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                            ),
                            style: TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 性別フィールド
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  items: _genderOptions.map((String gender) {
                    return DropdownMenuItem<String>(value: gender, child: Text(gender));
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (_selectedGender != newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                      _updateFormValidity();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: '性別',
                    border: UnderlineInputBorder(borderSide: BorderSide(width: 0.5)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(width: 0.5)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 0.5)),
                  ),
                ),
                const SizedBox(height: 16),
                const MyCustomText(text: '電話番号', fontSize: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phone1Controller,
                        focusNode: _phone1Focus,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        cursorColor: MyColors.greenText,
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: MyColors.greenText),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phone2Controller,
                        focusNode: _phone2Focus,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        cursorColor: MyColors.greenText,
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: MyColors.greenText),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _phone3Controller,
                        focusNode: _phone3Focus,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        cursorColor: MyColors.greenText,
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: MyColors.greenText),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // 郵便番号フィールド
                Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width * 0.5,
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          TextFormField(
                            controller: _postalCodeController,
                            keyboardType: TextInputType.number,
                            maxLength: 8,
                            decoration: InputDecoration(
                              counterText: '',
                              labelText: '郵便番号',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: MyColors.greenText),
                              ),
                            ),
                            cursorColor: MyColors.greenText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: '市区町村',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: MyColors.greenText),
                        ),
                      ),
                      cursorColor: MyColors.greenText,
                      // キーボード表示時のスクロール対応のために追加
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    TextFormField(
                      controller: _blockNumberController,
                      decoration: InputDecoration(
                        labelText: '番地',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: MyColors.greenText),
                        ),
                      ),
                      cursorColor: MyColors.greenText,
                      // キーボード表示時のスクロール対応のために追加
                      onTap: () {},
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Column(
                  crossAxisAlignment: .start,
                  children: [
                    TextFormField(
                      controller: _apartmentController,
                      decoration: InputDecoration(
                        labelText: 'アパート・マンション名',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: MyColors.greenText),
                        ),
                      ),
                      cursorColor: MyColors.greenText,
                      // キーボード表示時のスクロール対応のために追加
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 100),
                // 登録するボタン
                _ButtonFinishSignUp(
                  isFormValid: _isFormValid,
                  preSignupUser: widget.preSignupUser,
                  password: _passwordController.text,
                  lastName: _lastNameController.text,
                  firstName: _firstNameController.text,
                  lastNameKana: _lastNameKanaController.text,
                  firstNameKana: _firstNameKanaController.text,
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  selectedDay: selectedDay,
                  selectedGender: _selectedGender ?? '未選択',
                  phone1: _phone1Controller.text,
                  phone2: _phone2Controller.text,
                  phone3: _phone3Controller.text,
                  postalCode: _postalCodeController.text,
                  prefectureId: _prefectureIdController.text,
                  city: _cityController.text,
                  blockNumber: _blockNumberController.text,
                  apartment: _apartmentController.text,
                  isRelatedInfo: _isRelatedInfo,
                  isLatestProductInfo: _isLatestProductInfo,
                  isApplyHtml: _isApplyHtml,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//登録ボタン
class _ButtonFinishSignUp extends StatelessWidget {
  const _ButtonFinishSignUp({
    required this.isFormValid,
    required this.preSignupUser,
    required this.password,
    required this.lastName,
    required this.firstName,
    required this.lastNameKana,
    required this.firstNameKana,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.selectedGender,
    required this.phone1,
    required this.phone2,
    required this.phone3,
    required this.postalCode,
    required this.prefectureId,
    required this.city,
    required this.blockNumber,
    required this.apartment,
    required this.isRelatedInfo,
    required this.isLatestProductInfo,
    required this.isApplyHtml,
  });
  final bool isFormValid;
  final PreSignupUser preSignupUser;
  final String password;
  final String lastName;
  final String firstName;
  final String lastNameKana;
  final String firstNameKana;
  final int selectedYear;
  final int selectedMonth;
  final int selectedDay;
  final String selectedGender;
  final String phone1;
  final String phone2;
  final String phone3;
  final String postalCode;
  final String prefectureId;
  final String city;
  final String blockNumber;
  final String apartment;
  final bool isRelatedInfo;
  final bool isLatestProductInfo;
  final bool isApplyHtml;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: isFormValid
            ? () async {
                // 処理開始に合わせて、ダイアログを表示
                showLoadingDialog(context);

                final SupabaseClient supabase = Supabase.instance.client;

                // Supabase認証でユーザーを登録
                final AuthResponse res = await supabase.auth.signUp(
                  email: preSignupUser.email,
                  password: password,
                );

                if (res.user?.id != null) {
                  // ユーザ情報の詳細をテーブルに登録
                  final String userId = res.user!.id;
                  if (userId.isEmpty) {
                    // ignore: use_build_context_synchronously
                    showErrorDialog(context, 'SignUp後、ユーザーIDを取得できず。。。');
                  }

                  // 生年月日をYYYYMMDD形式に変換
                  final String birthday =
                      '$selectedYear${selectedMonth.toString().padLeft(2, '0')}${selectedDay.toString().padLeft(2, '0')}';

                  // 性別を数値に変換（未選択=0, 男性=1, 女性=2, その他=3）
                  int genderValue = 0;
                  switch (selectedGender) {
                    case '男性':
                      genderValue = 1;
                    case '女性':
                      genderValue = 2;
                    case 'その他':
                      genderValue = 3;
                    default:
                      genderValue = 0;
                  }

                  // 電話番号を結合
                  final String phoneNumber = '$phone1$phone2$phone3';

                  // 都道府県IDを数値に変換
                  final int prefectureIdInt = int.tryParse(prefectureId) ?? 0;

                  // UserProfileDetailsオブジェクトを作成
                  try {
                    final UserProfileDetails userProfileDetails = UserProfileDetails(
                      userId: userId,
                      birthday: birthday,
                      sex: genderValue,
                      teleNum: phoneNumber,
                      postalCode: postalCode,
                      prefectureId: prefectureIdInt,
                      address1: city.isEmpty ? null : city,
                      address2: blockNumber.isEmpty ? null : blockNumber,
                    );

                    // user_profile_detailsテーブルにデータを挿入
                    await supabase
                        .from(Tables.userProfileDetails)
                        .insert(userProfileDetails.toJson());
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    showErrorDialog(context, 'ユーザープロフィールの登録に失敗しました: $e');
                  }

                  try {
                    final mailSettings = UserMailSettings(
                      userId: userId,
                      isSendRelatedRewards: isRelatedInfo, // 1: 送信する, 0: 送信しない
                      isSendAdvanceProductAnnounce: isLatestProductInfo, // 1: 送信する, 0: 送信しない
                      isHtmlMail: isApplyHtml, // 1: HTMLメール, 0: テキストメール
                    );

                    // user_mail_settingsテーブルにデータを挿入
                    await supabase.from(Tables.userMailSettings).insert(mailSettings.toJson());
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    showErrorDialog(context, 'ユーザーメール設定の登録に失敗しました: $e');
                  }

                  // 登録完了画面へ
                  // ignore: use_build_context_synchronously
                  context.go(SignUpCompletion.routeName);
                } else {
                  // ignore: use_build_context_synchronously
                  showErrorDialog(context, 'ユーザーIDが見つからず。。。');
                  return;
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
          text: '登録する',
          fontSize: 18.0,
          fontWeight: FontWeight.w500,
          textColor: Colors.white,
        ),
      ),
    );
  }
}

//パスワードの要件表示
class _PasswordRequirementItem extends StatelessWidget {
  const _PasswordRequirementItem({required this.isChecked, required this.text});
  final bool isChecked;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          spacing: 5,
          children: [
            if (isChecked) Icon(Icons.check, color: MyColors.greenText, size: 30) else SizedBox(),
            MyCustomText(text: text, fontSize: 14, textColor: MyColors.greyText),
          ],
        ),
      ],
    );
  }
}

void showLoadingDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Center(
        child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
      );
    },
  );
}

//エラー画面
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          const Text('エラーが発生しました', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(kDebugMode ? error : 'もう一度お試しください。'),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => context.go(Home.routeName), child: const Text('ホームに戻る')),
        ],
      ),
    );
  }
}
