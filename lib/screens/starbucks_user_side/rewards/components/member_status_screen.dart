import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

///会員ステータス
class StarRewardMemberStatus extends StatelessWidget {
  const StarRewardMemberStatus({super.key});
  static String routeName = 'starbucks_rewards_member_status_page';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: true,
      icon: Icon(Icons.close, color: Colors.white),
      onIconPressed: () {
        context.pop();
      },
      headerText: '会員Statusについて',
      headerTextColor: Colors.white,
      appBarBackgroundColor: MyColors.relatedRewardsHeaderColor,
      isFab: false,
      body: const Column(children: [_MemberStatusPageScrollSection()]),
    );
  }
}

///スクロール可能なセクション
class _MemberStatusPageScrollSection extends StatelessWidget {
  const _MemberStatusPageScrollSection();

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            sliver: SliverToBoxAdapter(child: _Contents()),
          ),
        ],
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      crossAxisAlignment: .start,
      children: const [
        SizedBox(height: 3),
        MyCustomText(text: 'スタンダード会員', fontSize: 18, fontWeight: FontWeight.bold),
        MyCustomText(text: '参加するとスタンダード会員になります。会員になった日を起点に、1年ごとに更新日があります。', softwrap: true),
        SizedBox(height: 10),
        MyCustomText(text: 'プレミアム会員', fontSize: 18, fontWeight: FontWeight.bold),
        MyCustomText(text: '年間に250ポイントためると、更新日から翌1年間もプレミアム会員としてご利用いただけます。', softwrap: true),
      ],
    );
  }
}
