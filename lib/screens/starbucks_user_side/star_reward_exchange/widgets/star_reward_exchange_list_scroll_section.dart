import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../../constants/my_colors.dart';
import '../../../../constants/supabase_rpcs.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../provider/stores_provider.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../e_ticket/main.dart';

///SVGのパス
const String points30SvgPath = 'assets/starbucks/svg/30points.svg';
const String points100SvgPath = 'assets/starbucks/svg/100points.svg';
const String points150SvgPath = 'assets/starbucks/svg/150points.svg';
const String points400SvgPath = 'assets/starbucks/svg/400points.svg';

///スターリワード交換候補一覧：スクロールエリア
class ExchangeStarRewardScrollSection extends StatelessWidget {
  const ExchangeStarRewardScrollSection({super.key, required this.starPoints});
  final double starPoints;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomScrollView(
        slivers: <Widget>[
          _CurrentStarSection(starPoints: starPoints),
          _ExchangeItems(starPoints: starPoints), //交換候補一覧
        ],
      ),
    );
  }
}

class _CurrentStarSection extends StatelessWidget {
  const _CurrentStarSection({required this.starPoints});
  final double starPoints;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
      key: const ValueKey('star_reward_exchange_list_current_star_section'),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            const MyCustomText(
              text: '保有Star',
              fontSize: 12,
              textColor: Color(0xFF5F5F5F),
              fontWeight: FontWeight.bold,
            ),
            Row(
              children: [
                Row(
                  crossAxisAlignment: .baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    MyCustomText(
                      text: starPoints.toStringAsFixed(1).split('.')[0],
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    MyCustomText(
                      text: '.${((starPoints - starPoints.floor()) * 10).toInt()}',
                      fontSize: 20, // 小数点以下のフォントサイズ
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                const SizedBox(width: 5),
                const Icon(Icons.star, color: MyColors.starGaugeColor, size: 32),
              ],
            ),
            const _GoAvailableETicketPage(),
          ],
        ),
      ),
    );
  }
}

/// 利用可能なeTicketへの遷移ボタン
class _GoAvailableETicketPage extends StatelessWidget {
  const _GoAvailableETicketPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        child: OutlinedButton(
          key: Key('star_reward_exchange_list_go_available_eticket'),
          onPressed: () {
            context.go('/home/tab1/${ETicket.routeName}');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: MyColors.darkGreenButton,
            side: const BorderSide(color: MyColors.darkGreenButton),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: const Size(0, 34), //垂直方向の余白調整
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyCustomText(
                text: '利用可能な',
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
                textColor: MyColors.darkGreenText,
              ),
              MyCustomText(
                text: 'eTicket',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                textColor: MyColors.darkGreenText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

///各メニューのタイル
class _ExchangeItems extends StatelessWidget {
  const _ExchangeItems({required this.starPoints});
  final double starPoints;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _BuildEachListTile(
            exchangeStarReward: ExchangeStarReward(
              id: 1,
              text: 'カスタマイズ',
              svgFilePath: points30SvgPath,
              essentialPoint: 30,
              starPoints: starPoints,
            ),
          ),
          _BuildEachListTile(
            exchangeStarReward: ExchangeStarReward(
              id: 2,
              text: 'フード 300',
              svgFilePath: points100SvgPath,
              essentialPoint: 90,
              starPoints: starPoints,
            ),
          ),
          _BuildEachListTile(
            exchangeStarReward: ExchangeStarReward(
              id: 3,
              text: 'フード 500',
              svgFilePath: points150SvgPath,
              essentialPoint: 130,
              starPoints: starPoints,
            ),
          ),
          _BuildEachListTile(
            exchangeStarReward: ExchangeStarReward(
              id: 4,
              text: 'ドリンク 800',
              svgFilePath: points150SvgPath,
              essentialPoint: 190,
              starPoints: starPoints,
            ),
          ),
          _BuildEachListTile(
            exchangeStarReward: ExchangeStarReward(
              id: 5,
              text: 'コーヒー豆 1900',
              svgFilePath: points400SvgPath,
              essentialPoint: 400,
              starPoints: starPoints,
            ),
          ),
          _BuildEachListTile(
            exchangeStarReward: ExchangeStarReward(
              id: 6,
              text: 'オリジナルグッズ',
              svgFilePath: points400SvgPath,
              essentialPoint: 400,
              starPoints: starPoints,
            ),
          ),
        ]),
      ),
    );
  }
}

///各メニュー
class _BuildEachListTile extends StatelessWidget {
  const _BuildEachListTile({required this.exchangeStarReward});
  final ExchangeStarReward exchangeStarReward;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.15,
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: MyColors.settingDivider, // 枠線の色
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        titleAlignment: ListTileTitleAlignment.top,
        contentPadding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
        title: Row(
          children: [
            VectorGraphic(
              loader: AssetBytesLoader(exchangeStarReward.svgFilePath),
              height: MediaQuery.sizeOf(context).height * 0.10,
              // width: 80,
            ),
            const SizedBox(width: 15),
            _ExchangeItem(text: exchangeStarReward.text),
            const Spacer(),
            _ExchageFilledButton(exchangeStarReward: exchangeStarReward),
          ],
        ),
        // trailing:
      ),
    );
  }
}

class _ExchangeItem extends StatelessWidget {
  const _ExchangeItem({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .start,
      children: [
        MyCustomText(text: text, fontWeight: FontWeight.bold, fontSize: 12),
        const MyCustomText(text: 'eTicket', fontWeight: FontWeight.bold, fontSize: 12),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: .center,
          children: [
            MyCustomText(
              text: '詳しく見る',
              textColor: Color(0xD4283631),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            Icon(Icons.arrow_forward_ios, size: 12),
          ],
        ),
      ],
    );
  }
}

///交換するボタン
class _ExchageFilledButton extends StatelessWidget {
  const _ExchageFilledButton({required this.exchangeStarReward});
  final ExchangeStarReward exchangeStarReward;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.04,
      child: FilledButton(
        key: const ValueKey('star_reward_exchange_scroll_section_exchange_button'),
        onPressed: () => _showConfirmExchangeModal(context, exchangeStarReward),
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: MyColors.darkGreenButton,
          foregroundColor: MyColors.darkGreenButton,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MyCustomText(
              text: '交換する',
              textColor: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      ),
    );
  }
}

/// ポイント交換確認用のダイアログを表示。
///
/// パラメータ:
/// - [context]: ビルドコンテキスト
/// - [essentialPoint]: 交換に必要なポイント数
/// - [starPoints]: 現在のスターポイント数
///
/// 交換後の残りポイント数は [remainingPoints] として計算
void _showConfirmExchangeModal(BuildContext context, ExchangeStarReward exchangeStarReward) {
  final double remainingPoints =
      exchangeStarReward.starPoints - exchangeStarReward.essentialPoint; //残ポイント数算出
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルトの40から縮小
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Padding(
            padding: const .all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: .start,
              children: [
                const MyCustomText(
                  text: 'このeTicketに交換しますか？',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 15),
                const SizedBox(height: 75, child: MyCustomText(text: 'ここに画像を追加')),
                const SizedBox(height: 15),
                const MyCustomText(
                  text: 'XXXを1点無料でお楽しみいただけます。\n※eTicketの有効期限は交換から30日間です。',
                  fontSize: 12,
                  softwrap: true,
                ),
                const SizedBox(height: 15),
                const Divider(color: MyColors.horizontalDivider, height: 0.25),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 左側のラベル列
                    const Column(
                      spacing: 35,
                      crossAxisAlignment: .start,
                      children: [
                        MyCustomText(
                          text: '保有Star',
                          textColor: MyColors.greyText,
                          fontWeight: FontWeight.bold,
                        ),
                        MyCustomText(
                          text: '交換後の保有Star',
                          textColor: MyColors.greyText,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 右側の数値列と矢印
                    Column(
                      children: [
                        MyCustomText(
                          text: exchangeStarReward.starPoints.toString(),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        Icon(Icons.arrow_drop_down, size: 32, color: MyColors.greyText),
                        MyCustomText(
                          text: remainingPoints.toString(),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ],
                    ),
                    const SizedBox(width: 5),
                    Column(
                      spacing: 35,
                      children: const [
                        MyCustomText(
                          text: 'stars',
                          textColor: MyColors.greyText,
                          fontWeight: FontWeight.bold,
                        ),
                        MyCustomText(
                          text: 'stars',
                          textColor: MyColors.greyText,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: MyColors.horizontalDivider, height: 0.25),
                const SizedBox(height: 10),
                const MyCustomText(
                  text: 'eTicketの交換した場合、戻すことはできません。',
                  fontSize: 12,
                  textColor: MyColors.greyText,
                  softwrap: true,
                ),
                const MyCustomText(
                  text: '有効期限から近いものから交換されます',
                  fontSize: 12,
                  textColor: MyColors.greyText,
                  softwrap: true,
                ),
                const SizedBox(height: 30),
                Row(
                  spacing: 15,
                  mainAxisAlignment: .end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyColors.darkGreenButton,
                        side: BorderSide(color: MyColors.darkGreenButton, width: 0.8),
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: Size(0, 33),
                        splashFactory: InkSplash.splashFactory,
                      ),
                      child: const MyCustomText(text: 'キャンセル', textColor: MyColors.darkGreenButton),
                    ),
                    FilledButton(
                      key: const ValueKey('star_reward_exchange_scroll_section_exchange_button'),
                      onPressed: () async {
                        final userId = supabase.auth.currentUser?.id;
                        try {
                          // 関数:use_star_pointsを呼び出し
                          await supabase.rpc<void>(
                            Rpcs.useStarPoints,
                            params: {
                              'p_user_id': userId,
                              'p_order_id': 'order_id',
                              'p_exchange_item_id': exchangeStarReward.id,
                              'p_point_used': exchangeStarReward.essentialPoint,
                            },
                          );
                          if (kDebugMode) {
                            LoggerService.info('Star points exchanged successfully');
                          }
                          // ignore: use_build_context_synchronously
                          context.pop(); // ダイアログを閉じる
                        } catch (e) {
                          if (kDebugMode) {
                            // エラーハンドリング
                            LoggerService.warn('Error: $e');
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: MyColors.darkGreenButton,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: const Size(0, 33),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MyCustomText(
                            text: '交換する',
                            textColor: Colors.white,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ExchangeStarReward {
  ExchangeStarReward({
    required this.id,
    required this.text,
    required this.svgFilePath,
    required this.essentialPoint,
    required this.starPoints,
  });
  final int id;
  final String text;
  final String svgFilePath;
  final double essentialPoint;
  final double starPoints;
}
