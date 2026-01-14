import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../history/star_history_screen.dart';
import '../rewards_screen.dart';

/// Star獲得・交換・失効履歴ボタン
class RewardsButtonCheckGetExchangeRevocation extends StatelessWidget {
  const RewardsButtonCheckGetExchangeRevocation({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: .end,
          children: [
            OutlinedButton(
              onPressed: () {
                context.go(
                  '/home/tab1/${Rewards.routeName}/${StarRewardExpirationDateRetainedStarsHistories.routeName}',
                );
                // final fullPath = RouteFinder.getFullPath(
                //   StarRewardExpirationDateRetainedStarsHistories.routeName,
                // );
                // context.push(fullPath.join());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.darkGreenButton,
                side: BorderSide(color: MyColors.darkGreenButton),
                padding: EdgeInsets.symmetric(horizontal: 15),
                minimumSize: Size(0, 35),
                splashFactory: InkSplash.splashFactory,
              ),
              child: const MyCustomText(
                text: 'Star獲得・交換・失効履歴',
                textColor: MyColors.darkGreenButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
