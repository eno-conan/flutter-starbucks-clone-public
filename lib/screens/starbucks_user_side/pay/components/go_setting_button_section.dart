import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../setting/pay_setting_screen.dart';

/// 設定画面へ遷移するボタン
class PayButtonGoSettingPage extends StatelessWidget {
  const PayButtonGoSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            OutlinedButton(
              onPressed: () {
                context.push(PaySettingPage.routeName);
                // final fullPath = RouteFinder.getFullPath(PaySettingPage.routeName);
                // context.push(fullPath.join());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.greenButton,
                side: BorderSide(color: MyColors.greenButton, width: 0.8),
                padding: EdgeInsets.symmetric(horizontal: 25),
                minimumSize: Size(0, 35),
                splashFactory: InkSplash.splashFactory,
              ),
              child: const MyCustomText(text: '設定', textColor: MyColors.greenButton),
            ),
          ],
        ),
      ),
    );
  }
}
