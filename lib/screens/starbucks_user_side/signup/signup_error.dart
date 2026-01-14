import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/my_colors.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

///会員情報失敗画面（入力画面を表示しないケース）
class SignUpError extends ConsumerWidget {
  const SignUpError({super.key});
  static String routeName = '/starbucks_signup_failed_page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: Column(children: const [_Header(), _Contents()]));
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

class _Contents extends StatelessWidget {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        spacing: 20,
        crossAxisAlignment: .start,
        children: const [
          MyCustomText(text: 'エラーが発生しました', fontSize: 20, fontWeight: FontWeight.bold),
          MyCustomText(
            text: '既に会員登録済か、URLの有効期限切れです。もう一度はじめから会員登録をしてください。',
            fontSize: 14,
            textColor: MyColors.greyText,
            softwrap: true,
          ),
        ],
      ),
    );
  }
}
