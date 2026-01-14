import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/my_colors.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

///仮会員登録完了画面
class PreSignUpCompletion extends StatelessWidget {
  const PreSignUpCompletion({super.key});
  static String routeName = '/starbucks_pre_signup_completed_page';

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final String email = extra?['email'] as String? ?? '';

    return FixedHeaderCommonComponent(
      isLeadingIcon: false,
      headerText: '仮会員登録完了',
      isFab: true,
      fabWidget: _ButtonGoTopPage(),
      body: _Contents(email: email),
    );
  }
}

//表示コンテンツ
class _Contents extends StatelessWidget {
  const _Contents({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          // イラスト
          const MyCustomText(text: '確認メールを送信しました。\nメールに記載のURLから本登録を行ってください。'),
          const SizedBox(height: 16),
          const MyCustomText(text: 'お送りしたメールアドレス', textColor: MyColors.greyText),
          const SizedBox(height: 8),
          MyCustomText(text: email, fontWeight: FontWeight.bold, fontSize: 18),
          const SizedBox(height: 16),
          const MyCustomText(
            text: '※メール内URLの有効期間は30分です。',
            textColor: MyColors.greyText,
            fontSize: 12,
          ),
          const MyCustomText(
            text: '※30分以内に会員登録のご案内メールが届かない場合、ご入力されたメールアドレスに誤りがある可能性があります。もう一度はじめから会員登録をしてください。',
            textColor: MyColors.greyText,
            fontSize: 12,
            softwrap: true,
          ),
          const MyCustomText(
            text: '※「mx.starbucks.co.jp」からのメールが受け取れる設定であることをご確認ください。',
            textColor: MyColors.greyText,
            fontSize: 12,
            softwrap: true,
          ),
        ],
      ),
    );
  }
}

//トップ画面に遷移するボタン
class _ButtonGoTopPage extends StatelessWidget {
  const _ButtonGoTopPage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 100,
      child: FloatingActionButton(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: MyColors.fabGreenButton,
        child: MyCustomText(text: '閉じる', textColor: Colors.white, fontSize: 18),
        onPressed: () {
          //トップ画面へ遷移
          context.go('/home/tab1');
        },
      ),
    );
  }
}
