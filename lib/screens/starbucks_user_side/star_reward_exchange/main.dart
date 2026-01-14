import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/my_colors.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'widgets/star_reward_exchange_list_scroll_section.dart';

///スターリワード交換候補一覧
class ExchangeStarReward extends StatelessWidget {
  const ExchangeStarReward({super.key});
  static String routeName = '/starbucks_reward_exchange_list_page';

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final double starPoints = extra?['starPoints'] as double? ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.relatedRewardsHeaderColor,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const _Header(),
          ExchangeStarRewardScrollSection(starPoints: starPoints),
        ],
      ),
    );
  }
}

///ヘッダー
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      color: MyColors.relatedRewardsHeaderColor,
      child: const MyCustomText(text: 'スター リワード 交換', fontSize: 28, textColor: Colors.white),
    );
  }
}
