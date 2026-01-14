import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../constants/my_colors.dart';
import '../../../../core/models/purchase_history.dart';
import '../../../../services/rewards/star_history_service.dart';
import '../../../../shared/widgets/headers/fixed_header.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../../../shared/widgets/wrap_sliver_to_box_adapter.dart';

///Star獲得・交換・失効履歴
class StarRewardExpirationDateRetainedStarsHistories extends StatelessWidget {
  const StarRewardExpirationDateRetainedStarsHistories({super.key});
  static String routeName = 'starbucks_star_reward_expiration_date_retained_stars_histories';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: true,
      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
      onIconPressed: () {
        context.pop();
      },
      headerText: 'スター獲得・交換・失効履歴',
      headerTextColor: Colors.white,
      appBarBackgroundColor: MyColors.relatedRewardsHeaderColor,
      isFab: false,
      body: _ScrollContents(),
    );
  }
}

class _ScrollContents extends StatelessWidget {
  const _ScrollContents();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: const <Widget>[PurchaseHistoryScreen()]);
  }
}

// 購入履歴を表示するウィジェット
class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final _purchaseHistoryService = StarRewardExpirationDateRetainedStarsHistoriesService(
    Supabase.instance.client,
  );
  late Future<List<MonthlyPurchaseHistory>> _purchaseHistoryFuture;

  @override
  void initState() {
    super.initState();
    _purchaseHistoryFuture = _purchaseHistoryService.getPurchaseHistory();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonthlyPurchaseHistory>>(
      future: _purchaseHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return WrapSliverToBoxAdapter(
            body: const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
          return WrapSliverToBoxAdapter(
            body: SizedBox(
              height: 100,
              child: Center(child: Text('エラーが発生しました: ${snapshot.error}')),
            ),
          );
        }

        final monthlyPurchaseHistory = snapshot.data!;

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final monthHistory = monthlyPurchaseHistory[index];
            return Column(
              crossAxisAlignment: .start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: MyCustomText(
                    text: '${monthHistory.month.year}年${monthHistory.month.month}月',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(thickness: 4, color: Color(0xFFE7E5E5)),
                ...monthHistory.purchases.map(
                  (purchase) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        child: Row(
                          mainAxisAlignment: .spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: .start,
                              children: [
                                Row(
                                  children: [
                                    MyCustomText(
                                      text: '+ ${purchase.starPoints} ',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    MyCustomText(text: 'Stars', textColor: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                MyCustomText(text: purchase.storeName, textColor: Colors.grey),
                                MyCustomText(
                                  text: 'カード番号末尾(${purchase.cardNumber.split('-').last})',
                                  textColor: Colors.grey,
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                MyCustomText(
                                  text: purchase.formattedPurchaseDate,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(thickness: 0.5, color: MyColors.horizontalDivider),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            );
          }, childCount: monthlyPurchaseHistory.length),
        );
      },
    );
  }
}
