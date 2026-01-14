import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/my_colors.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

///会員登録完了画面
class SignUpCompletion extends StatelessWidget {
  const SignUpCompletion({super.key});
  static String routeName = '/starbucks_signup_completion_page';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: false,
      headerText: '会員登録完了',
      isFab: true,
      fabWidget: _ButtonGoTopPage(),
      body: _Contents(),
    );
  }
}

//表示コンテンツ
class _Contents extends StatelessWidget {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: .start,
        children: const [
          // イラスト
          MyCustomText(text: '会員登録が完了しました。'),
          SizedBox(height: 16),
          MyCustomText(
            text: 'スターバックス カードの登録・入金は、お好きなときに、アプリのPay画面から行えます。',
            textColor: MyColors.greyText,
            softwrap: true,
          ),
          SizedBox(height: 8),
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
      width: 120,
      child: FloatingActionButton(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: MyColors.fabGreenButton,
        child: MyCustomText(text: 'Home画面へ', textColor: Colors.white, fontSize: 18),
        onPressed: () {
          //トップ画面へ遷移
          context.go('/home/tab1');
        },
      ),
    );
  }
}
