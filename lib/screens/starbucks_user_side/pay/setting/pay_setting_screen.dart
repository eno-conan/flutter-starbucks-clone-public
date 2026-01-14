import 'package:flutter/material.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import 'card_number_dialog.dart';
import 'unregister_card_dialog.dart';

/// Pay > 設定ボタンで表示する画面
class PaySettingPage extends StatelessWidget {
  const PaySettingPage({super.key});
  static String routeName = '/pay_setting_page';

  @override
  Widget build(BuildContext context) {
    return SlidingNavBarExample();
  }
}

class SlidingNavBarExample extends StatelessWidget {
  const SlidingNavBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            expandedHeight: 75, // 最大の高さ
            floating: true, // trueにするとスクロールを戻したときにすぐに表示される
            pinned: true, // trueにするとヘッダーの一部が常に表示される
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            ),
            actions: const [
              PaySettingPageDialogCardNumber(), //カード番号
            ],
          ),
          // 2段目: 折りたたまれるヘッダー
          SliverPersistentHeader(
            // pinned: false, // 完全に折りたたまれる
            delegate: _SliverHeaderDelegate(
              minHeight: 0, // 最小の高さ（完全に消える）
              maxHeight: 80, // 2段目の最大の高さ
              child: Container(
                color: Colors.white,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: Text(
                    '2段目（スクロールで折りたたまれる）',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          // リストコンテンツ
          SliverToBoxAdapter(child: _Contents()),
        ],
      ),
    );
  }
}

// コンテンツ
class _Contents extends StatelessWidget {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: .start,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
            child: Row(
              children: [
                MyCustomText(text: '￥1,772', fontSize: 20),
                Spacer(),
                Column(
                  crossAxisAlignment: .end,
                  children: [
                    MyCustomText(text: '残高更新', textColor: MyColors.greenText, fontSize: 16),
                    MyCustomText(
                      text: '2025/03/02 12:43',
                      textColor: MyColors.headerLeadingIcon,
                      fontSize: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: MyColors.settingDivider),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              spacing: 25,
              children: [
                Icon(Icons.credit_card, color: MyColors.headerLeadingIcon),
                MyCustomText(text: 'メインカード設定'),
              ],
            ),
          ),
          Divider(color: MyColors.settingDivider),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              spacing: 10,
              children: [
                Row(
                  spacing: 25,
                  crossAxisAlignment: .start,
                  children: [
                    Icon(Icons.attach_money_rounded, color: MyColors.headerLeadingIcon),
                    Column(
                      crossAxisAlignment: .start,
                      children: [
                        MyCustomText(text: 'オートチャージ設定', fontSize: 16),
                        SizedBox(height: 10),
                        MyCustomText(
                          text: 'オートチャージ￥3,000',
                          fontSize: 14,
                          textColor: MyColors.headerLeadingIcon,
                        ),
                        MyCustomText(
                          text: '入金条件：残高が￥1,000未満',
                          fontSize: 14,
                          textColor: MyColors.headerLeadingIcon,
                        ),
                      ],
                    ),
                    Spacer(),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: MyColors.settingDivider),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              spacing: 25,
              children: [
                Icon(Icons.change_circle_outlined, color: MyColors.headerLeadingIcon),
                MyCustomText(
                  text: '残高移行',
                  textColor: MyColors.headerLeadingIcon,
                ), //他にカードがない場合は非活性状態、っぽい。
              ],
            ),
          ),
          Divider(color: MyColors.settingDivider),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              spacing: 25,
              children: [
                Icon(Icons.summarize_outlined),
                MyCustomText(text: '利用履歴'),
              ],
            ),
          ),
          PaySettingPageDialogUnregisterCard(), //カード登録解除
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Row(
              spacing: 25,
              children: [
                Icon(Icons.warning_amber_outlined),
                MyCustomText(text: '紛失届・利用停止'),
              ],
            ),
          ),
          Divider(color: MyColors.settingDivider),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 3,
              children: [
                MyCustomText(text: 'メインカードに設定されています', textColor: MyColors.headerLeadingIcon),
                MyCustomText(text: 'XXXの利用状態は有効です', textColor: MyColors.headerLeadingIcon),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// SliverPersistentHeaderのカスタムヘッダー
class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
