import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/my_colors.dart';
import '../../../constants/supabase_rpcs.dart';
import '../../../core/services/logger_service.dart';
import '../../../services/home/star_points_cache_service.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import '../../../shared/widgets/wrap_sliver_to_box_adapter.dart';
import '../star_reward_exchange/main.dart';
import 'components/dialog_star_expiration.dart';
import 'components/member_status_screen.dart';
import 'sections/expiration_stars_section.dart';
import 'sections/history_button_section.dart';

///スターリワードトップ画面
class Rewards extends StatelessWidget {
  const Rewards({super.key});
  static String routeName = '/starbucks_rewards_page';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: true,
      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
      onIconPressed: () {
        context.pop();
      },
      headerText: 'Rewards',
      headerTextColor: Colors.white,
      appBarBackgroundColor: MyColors.relatedRewardsHeaderColor,
      bodyBackgroundColor: MyColors.relatedRewardsHeaderColor,
      isFab: false,
      actions: const [
        MyCustomText(text: 'ご利用ガイド', fontSize: 16, textColor: Colors.white),
        SizedBox(width: 10),
      ],
      body: const Column(children: [_StarRewardPageScrollSection()]),
    );
  }
}

///スクロール可能なセクション
class _StarRewardPageScrollSection extends StatelessWidget {
  const _StarRewardPageScrollSection();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: CustomScrollView(
        slivers: <Widget>[
          _MessageGetStar(),
          _ExchangeStarRewardButton(),
          _ExpirationStarSectionTitle(),
          // 月ごとの情報を表示
          WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider, thickness: 0.5)),
          RewardsExpirationDateRetainedStars(),
          RewardsButtonCheckGetExchangeRevocation(), // Star獲得・交換・失効履歴ボタン
          _MemberStatusSectionTitle(), // 会員ステータス
          // _CurrentStarSection()
        ],
      ),
    );
  }
}

/// スターリワード交換ボタン
class _ExchangeStarRewardButton extends StatefulWidget {
  const _ExchangeStarRewardButton();

  @override
  State<_ExchangeStarRewardButton> createState() => _ExchangeStarRewardButtonState();
}

class _ExchangeStarRewardButtonState extends State<_ExchangeStarRewardButton> {
  double _starPoints = 0;
  final StarPointsCacheService _starPointscacheService = StarPointsCacheService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // スターポイント数を取得（キャッシュがあればキャッシュから）
      final double fetchedStarPoints = await _starPointscacheService.getDataViaFunction(
        Rpcs.getTotalPointsWithExpirationFlagZero,
        isForceIgnoreCache: true,
      );
      if (mounted) {
        setState(() {
          _starPoints = fetchedStarPoints;
        });
      }
    } catch (e) {
      if (e is PostgrestException) {}
      // エラー処理
      LoggerService.warn('Error loading products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            FilledButton(
              onPressed: () {
                context.push(
                  '/home/tab1/${ExchangeStarReward.routeName}',
                  extra: {'starPoints': _starPoints},
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: MyColors.relatedRewardsHeaderColor,
                padding: EdgeInsets.symmetric(horizontal: 15),
                minimumSize: Size(0, 35),
                splashFactory: InkSplash.splashFactory,
              ),
              child: const MyCustomText(text: 'スターリワードに交換', textColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// N円で1pポイントの説明表示欄
class _MessageGetStar extends StatelessWidget {
  const _MessageGetStar();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ColoredBox(
        color: Color(0xFFF9F1E4),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: .center,
            children: const [MyCustomText(text: 'お買い物54円(税込)あたり、starが1つたまります。', fontSize: 12)],
          ),
        ),
      ),
    );
  }
}

/// 保有Starの有効期限
class _ExpirationStarSectionTitle extends StatelessWidget {
  const _ExpirationStarSectionTitle();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          spacing: 5,
          children: const [
            MyCustomText(
              text: '保有Starの有効期限',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              textColor: Color(0xFF6D6D6D),
            ),
            RewardsIconDialogExpiration(),
          ],
        ),
      ),
    );
  }
}

/// 会員ステータス
class _MemberStatusSectionTitle extends StatelessWidget {
  const _MemberStatusSectionTitle();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: Row(
          spacing: 5,
          children: [
            const MyCustomText(
              text: '会員ステータス',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              textColor: Color(0xFF6D6D6D),
            ),
            GestureDetector(
              onTap: () {
                context.go('/home/tab1/${Rewards.routeName}/${StarRewardMemberStatus.routeName}');
                // final fullPath = RouteFinder.getFullPath(StarRewardMemberStatus.routeName);
                // context.push(fullPath.join());
              },
              child: Icon(Icons.info_outline),
            ),
          ],
        ),
      ),
    );
  }
}
