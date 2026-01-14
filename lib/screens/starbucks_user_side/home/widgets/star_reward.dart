import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/my_colors.dart';
import '../../../../constants/supabase_rpcs.dart';
import '../../../../provider/auth_state_provider.dart';
import '../../../../services/home/star_points_cache_service.dart';
import '../../../../shared/widgets/splash_screen.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../rewards/rewards_screen.dart';
import '../../star_reward_exchange/main.dart';

final values = ['25', '90', '130', '190', '400'];

///Section:スターリワード
class HomeStarRewardSection extends ConsumerWidget {
  const HomeStarRewardSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    return authAsync.when(
      loading: () => SplashScreen(),
      error: (error, _) => SizedBox(),
      data: (user) => user != null ? _SectionCurrentStarPoints() : SizedBox(),
    );
  }
}

/// 現在のスター数表示エリア
class _SectionCurrentStarPoints extends StatelessWidget {
  const _SectionCurrentStarPoints();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: _ColumnGaugePoint(),
    );
  }
}

///ポイントのゲージ表示
class _ColumnGaugePoint extends StatefulWidget {
  const _ColumnGaugePoint();

  @override
  State<_ColumnGaugePoint> createState() => _ColumnGaugePointState();
}

class _ColumnGaugePointState extends State<_ColumnGaugePoint> {
  double _starPoints = 0;
  bool _isLoading = true;
  bool _hasError = false; // エラーフラグを追加
  final StarPointsCacheService _starPointscacheService = StarPointsCacheService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(_ColumnGaugePoint oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 初回以外の場合、キャッシュを無視してDB値を取得
    if (_isInitialized) {
      _loadData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData({bool isForceIgnoreCache = true}) async {
    try {
      // スターポイント数を取得(キャッシュがあればキャッシュから、強制更新時はDBから)
      final double fetchedStarPoints = await _starPointscacheService.getDataViaFunction(
        Rpcs.getTotalPointsWithExpirationFlagZero,
        isForceIgnoreCache: isForceIgnoreCache,
      );
      if (mounted) {
        setState(() {
          _starPoints = fetchedStarPoints;
          _isLoading = false;
          _hasError = false; // 成功時はエラーフラグをリセット
        });
      }
    } catch (e) {
      // エラー処理 - エラーフラグを立てる
      debugPrint('Error loading star points: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true; // エラーフラグを立てる
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // エラーまたはローディング中の場合はSizedBoxを返す
    if (_hasError || _isLoading) {
      return const SizedBox(height: 0);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: const [
            MyCustomText(
              text: 'STARBUCKS® REWARDS',
              fontWeight: FontWeight.bold,
              useEnglishFont: true,
            ),
            Row(
              children: [
                MyCustomText(
                  text: 'Gold会員',
                  fontWeight: FontWeight.bold,
                  textColor: MyColors.starGaugeColor,
                ),
                Icon(Icons.star_outline_sharp, color: MyColors.starGaugeColor, size: 20),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Row(
              crossAxisAlignment: .baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MyCustomText(
                  text: _starPoints.toStringAsFixed(1).split('.')[0],
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                MyCustomText(
                  text: '.${((_starPoints - _starPoints.floor()) * 10).toInt()}',
                  fontSize: 20, // 小数点以下のフォントサイズ
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(width: 5),
            const Icon(Icons.star, color: MyColors.starGaugeColor, size: 32),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            children: [
              LinearProgressIndicator(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                minHeight: 10,
                value: _starPoints / 450,
                valueColor: AlwaysStoppedAnimation<Color>(MyColors.starGaugeColor), // ポイント部分の色
                backgroundColor: Colors.grey[200], // ポイントがない部分の色
              ),
              Row(
                children: [
                  const SizedBox(width: 5),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: .spaceAround,
                      children: List.generate(
                        5,
                        (index) => Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              const SizedBox(width: 5),
              Expanded(
                child: Row(
                  mainAxisAlignment: .spaceAround,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: index > 0
                          ? index > 2
                                ? const EdgeInsets.only(left: 7)
                                : const EdgeInsets.only(left: 15)
                          : const EdgeInsets.only(left: 3),
                      child: MyCustomText(
                        text: values[index],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // スターリワード交換とスターリワード詳細確認
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 15,
          children: [
            _ExChangeStarRewardContainer(starPoints: _starPoints),
            const _CheckDetailContainer(),
          ],
        ),
      ],
    );
  }
}

///スターリワード交換ボタン
class _ExChangeStarRewardContainer extends StatelessWidget {
  const _ExChangeStarRewardContainer({required this.starPoints});
  final double starPoints;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: FilledButton(
        onPressed: () {
          context.push(ExchangeStarReward.routeName, extra: {'starPoints': starPoints});
        },
        style: FilledButton.styleFrom(
          backgroundColor: MyColors.darkGreenButton,
          side: const BorderSide(color: MyColors.darkGreenButton),
          minimumSize: const Size(0, 32),
        ),
        child: const MyCustomText(
          text: 'スターリワードに交換',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          textColor: Colors.white,
        ),
      ),
    );
  }
}

///スターリワードのポイント数と詳細確認ボタン
class _CheckDetailContainer extends StatelessWidget {
  const _CheckDetailContainer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: OutlinedButton(
        onPressed: () {
          context.push(Rewards.routeName);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: MyColors.darkGreenButton,
          side: const BorderSide(color: MyColors.darkGreenButton),
          minimumSize: Size(0, 32),
          splashFactory: InkSplash.splashFactory,
        ),
        child: const MyCustomText(text: 'もっと見る', fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
