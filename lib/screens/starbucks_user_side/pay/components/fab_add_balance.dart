// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import 'custom_dropdown.dart';
import 'loading_overlay.dart';

///入金ボタン
class PayAddBalanceFloatingButton extends StatelessWidget {
  const PayAddBalanceFloatingButton({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: FloatingActionButton(
        elevation: 2,
        heroTag: null,
        onPressed: () {
          showModalBottomSheet<void>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)), //角丸を削除
            context: context,
            isScrollControlled: true,
            builder: (context) => const BottomSheetContent(),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: Colors.white,
        child: const MyCustomText(text: '入金', fontSize: 18),
      ),
    );
  }
}

//カードの選択肢
final List<String> _cards = ['カード1', 'カード2'];

//入金額候補
final List<String> _depositAmountchoices = ['¥1,000', '¥3,000', '¥5,000', '¥10,000', '自由に'];

//支払い方法候補
final List<String> _payWaychoices = ['････ 1234-有効期限 2029/01', 'クレジットカード2', 'PayPay', '追加'];

/// BottomSheetの内容
class BottomSheetContent extends StatefulWidget {
  const BottomSheetContent({super.key});
  @override
  State<BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isHiddenPassword = true; // パスワードの表示・非表示
  String? _card;
  String? _depositAmount;
  String? _payWay;
  bool _isPassAuth = false; // パスワードの表示・非表示
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // 初期値設定
    _card = _cards[0];
    _depositAmount = _depositAmountchoices[0];
    _payWay = _payWaychoices[0];
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  /// パスワードの表示・非表示切り替え
  void _togglePasswordView() {
    setState(() {
      _isHiddenPassword = !_isHiddenPassword;
    });
  }

  void _authorize(BuildContext dialogContext) {
    if (_formKey.currentState!.validate()) {
      // ここで選択された値を処理

      // まずダイアログを閉じる
      Navigator.of(dialogContext).pop();
      setState(() {
        _isPassAuth = true;
      });
      // 次にモーダルボトムシートを閉じる
      // Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 25,
        right: 10,
        top: 20,
      ),
      child: _isPassAuth
          ? _CertifiedBottomSheet(
              selectedCard: _card!,
              selectedDepositAmount: _depositAmount!,
              selectedPayWay: _payWay!,
              successDialog: () => _showDepositSuccessDialog(context),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const RepaintBoundary(child: RowBottomSheetTitle()),
                  const SizedBox(height: 30),
                  const Row(
                    children: [
                      Column(
                        crossAxisAlignment: .start,
                        spacing: 5,
                        children: [
                          MyCustomText(
                            text: 'オートチャージ設定',
                            fontSize: 16,
                            textColor: MyColors.greyText,
                          ),
                          MyCustomText(
                            text: '¥3,000(入金条件：残高が¥1,000未満)',
                            textColor: MyColors.greyText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // ドロップダウン1
                  const SizedBox(height: 10),
                  CustomDropdownFormField<String>(
                    value: _card,
                    items: _cards,
                    labelText: 'アカウント名',
                    onChanged: (value) {
                      setState(() {
                        _card = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  // ドロップダウン2
                  CustomDropdownFormField<String>(
                    value: _depositAmount,
                    items: _depositAmountchoices,
                    labelText: '入金額',
                    onChanged: (value) {
                      setState(() {
                        _depositAmount = value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  // ドロップダウン3
                  CustomDropdownFormField<String>(
                    value: _payWay,
                    items: _payWaychoices,
                    labelText: '支払い方法',
                    itemBuilder: (option) => _ComposePayChoiceLayout(option: option),
                    onChanged: (value) {
                      setState(() {
                        _payWay = value;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  RepaintBoundary(
                    child: ButtonDoCertify(
                      showPasswordDialog: () => _showDialogInputPassword(context),
                    ),
                  ), //認証処理に進むボタン
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Removed _buildDropdownDecoration method as it's no longer used

  // 疑似的な入金処理
  void _showDepositSuccessDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('入金完了'),
        content: Text('$_depositAmount の入金が正常に処理されました。'),
        actions: [
          TextButton(
            onPressed: () => {Navigator.of(context).pop(), LoadingOverlay.hide(context)},
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// パスワード入力のダイアログ表示
  void _showDialogInputPassword(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルトの40から縮小
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: .start,
              children: [
                const SizedBox(height: 5),
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
                const SizedBox(height: 15),
                Row(
                  spacing: 20,
                  mainAxisAlignment: .end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyColors.greenButton,
                        // backgroundColor: Colors.white,
                        side: const BorderSide(color: MyColors.greenButton),
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        minimumSize: const Size(0, 35), //これで垂直方向の余白を狭くできた
                      ),
                      child: const MyCustomText(
                        text: 'キャンセル',
                        textColor: MyColors.greenText,
                        // fontWeight: FontWeight.w700,
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        _authorize(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: MyColors.greenButton,
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        minimumSize: const Size(0, 35), //これで垂直方向の余白を狭くできた
                      ),
                      child: const MyCustomText(
                        text: 'OK',
                        textColor: Colors.white,
                        // fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 認証へ進むボタン
class ButtonDoCertify extends StatelessWidget {
  const ButtonDoCertify({super.key, required this.showPasswordDialog});
  final VoidCallback showPasswordDialog;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.85,
      child: Row(
        mainAxisAlignment: .end,
        children: [
          SizedBox(
            width: 90,
            height: 60,
            child: FilledButton(
              onPressed: showPasswordDialog, //ダイアログ表示
              style: FilledButton.styleFrom(
                elevation: 3,
                backgroundColor: MyColors.greenButton,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const MyCustomText(text: '次へ', textColor: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

///認証後のBottomSheet表示内容
class _CertifiedBottomSheet extends StatelessWidget {
  const _CertifiedBottomSheet({
    required this.selectedCard,
    required this.selectedDepositAmount,
    required this.selectedPayWay,
    required this.successDialog,
  });
  final String selectedCard;
  final String selectedDepositAmount;
  final String selectedPayWay;
  final VoidCallback successDialog;

  // 非同期処理を分離
  Future<void> _performDeposit(BuildContext context) async {
    try {
      // ローディングオーバーレイを表示
      LoadingOverlay.show(context);

      // 非同期処理をシミュレート（実際のアプリでは実際の入金処理に置き換える）
      await Future<void>.delayed(const Duration(seconds: 2));

      // 成功ダイアログ表示
      successDialog();

      // ボトムシートを閉じる
      Navigator.of(context).pop();
    } catch (e) {
      // エラーハンドリング
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('入金処理中にエラーが発生しました: $e')));
    } finally {
      // ローディングオーバーレイを必ず非表示
      LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: .start,
      children: [
        const RowBottomSheetTitle(),
        const SizedBox(height: 15),
        Row(
          children: [
            Column(crossAxisAlignment: .start, children: const [SizedBox(width: 50)]),
            Column(
              crossAxisAlignment: .start,
              children: [
                const SizedBox(width: 100),
                const MyCustomText(text: 'アカウント名', fontSize: 12, textColor: MyColors.greyText),
                MyCustomText(text: selectedCard),
                const SizedBox(height: 20),
                const MyCustomText(text: '入金額', fontSize: 12, textColor: MyColors.greyText),
                MyCustomText(text: selectedDepositAmount),
                const SizedBox(height: 20),
                const MyCustomText(text: '支払い方法', fontSize: 12, textColor: MyColors.greyText),
                MyCustomText(text: selectedPayWay),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 送信ボタン
        Row(
          spacing: 5,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.35,
              child: Row(
                mainAxisAlignment: .end,
                children: [
                  SizedBox(
                    width: 120,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        elevation: 1,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const MyCustomText(
                        text: 'キャンセル',
                        textColor: Colors.black,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.5,
              child: Row(
                mainAxisAlignment: .end,
                children: [
                  SizedBox(
                    width: 175,
                    height: 50,
                    child: FilledButton(
                      onPressed: () => _performDeposit(context),
                      style: FilledButton.styleFrom(
                        elevation: 1,
                        backgroundColor: MyColors.greenButton,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: MyCustomText(
                        text: '$selectedDepositAmount 入金',
                        textColor: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
      ],
    );
  }
}

///BottomSheetTitleの見出し
class RowBottomSheetTitle extends StatelessWidget {
  const RowBottomSheetTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 25,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.close, color: MyColors.headerLeadingIcon),
        ),
        const MyCustomText(text: '入金', fontSize: 16, textColor: MyColors.greyText),
      ],
    );
  }
}

///支払い方法の表示をカスタマイズ
class _ComposePayChoiceLayout extends StatelessWidget {
  const _ComposePayChoiceLayout({required this.option});
  final String option;

  @override
  Widget build(BuildContext context) {
    if (option.contains('-')) {
      return Row(
        children: [
          MyCustomText(text: option.split('-')[0], fontSize: 16),
          const SizedBox(width: 10),
          MyCustomText(text: option.split('-')[1], fontSize: 12, textColor: MyColors.greyText),
        ],
      );
    }
    return MyCustomText(text: option, fontSize: 14);
  }
}
