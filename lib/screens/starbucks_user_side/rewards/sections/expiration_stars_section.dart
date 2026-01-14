import 'package:flutter/material.dart';
import '../../../../constants/my_colors.dart';
import '../../../../services/home/star_aggregations_cache_service.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../../../shared/widgets/wrap_sliver_to_box_adapter.dart';

///有効期限付き星集計データ表示ウィジェット
class RewardsExpirationDateRetainedStars extends StatefulWidget {
  const RewardsExpirationDateRetainedStars({super.key});

  @override
  State<RewardsExpirationDateRetainedStars> createState() =>
      _RewardsExpirationDateRetainedStarsState();
}

class _RewardsExpirationDateRetainedStarsState extends State<RewardsExpirationDateRetainedStars> {
  bool isCheckMorePast = false;
  bool isLoading = true;
  List<Map<String, dynamic>> starAggregations = [];
  final _cacheService = StarAggregationsCacheService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // データを読み込む
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await _cacheService.getStarAggregations();
      setState(() {
        starAggregations = data;
        isLoading = false;
      });
    } catch (e) {
      // Handled silently - no need to log this common cache miss
      setState(() {
        isLoading = false;
      });
    }
  }

  // 日付を整形する関数
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '無効な日付';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 表示する項目数を決定
    final itemCount = isCheckMorePast
        ? (starAggregations.length)
        : (starAggregations.length > 3 ? 3 : starAggregations.length);

    return WrapSliverToBoxAdapter(
      body: Column(
        children: [
          if (isLoading)
            const Center(
              child: Padding(
                padding: .all(20.0),
                child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor),
              ),
            )
          else if (starAggregations.isEmpty)
            const Padding(
              padding: .all(20.0),
              child: Center(
                child: MyCustomText(text: '星集計データがありません', textColor: Colors.grey),
              ),
            )
          else
            // ListView.builderの代わりにColumnを使用
            Column(
              children: List.generate(itemCount, (index) {
                final item = starAggregations[index];
                final points = item['total_points'] as num;
                final expiration = _formatDate(item['expiration_datetime'] as String);

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
                      child: Row(
                        children: [
                          Row(
                            crossAxisAlignment: .baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              MyCustomText(
                                text: points.toStringAsFixed(1).split('.')[0],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              MyCustomText(
                                text: '.${((points - points.floor()) * 10).toInt()}',
                                fontSize: 12, // 小数点以下のフォントサイズ
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          const SizedBox(width: 5),
                          const MyCustomText(text: 'Stars', textColor: Colors.grey, fontSize: 16),
                          const Spacer(),
                          const MyCustomText(text: '有効期限', textColor: Colors.grey, fontSize: 16),
                          const SizedBox(width: 5),
                          MyCustomText(text: expiration, fontSize: 16),
                        ],
                      ),
                    ),
                    const Divider(color: MyColors.horizontalDivider, thickness: 0.5),
                  ],
                );
              }),
            ),

          // もっと見るボタン（データが3件以上ある場合のみ表示）
          if (starAggregations.length > 3)
            GestureDetector(
              onTap: () {
                setState(() {
                  isCheckMorePast = !isCheckMorePast;
                });
              },
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  MyCustomText(
                    text: isCheckMorePast ? '少なく表示' : 'もっと見る',
                    textColor: MyColors.relatedRewardsHeaderColor,
                  ),
                  const SizedBox(width: 5),
                  Icon(isCheckMorePast ? Icons.remove : Icons.add, color: MyColors.darkGreenButton),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
