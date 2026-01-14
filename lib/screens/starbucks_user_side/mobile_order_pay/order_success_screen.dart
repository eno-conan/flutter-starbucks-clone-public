import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/my_colors.dart';
import '../../../core/models/mobile_order_completion.dart';
import '../../../services/mobile_order_pay/store/tab_favorite_stores_service.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import '../home/main.dart';

/// 注文完了画面（受付番号とか表示する画面：ここは全画面）
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.selectedStore});
  final MobileOrderCompletion selectedStore;
  static String routeName = '/mobile_order_pay_success';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: false,
      headerText: '注文を承りました\nご来店を待ってまーす',
      isFab: true,
      fabWidget: SizedBox(
        height: 60,
        width: 200,
        child: FloatingActionButton(
          heroTag: null, // Disables the hero transition
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
          backgroundColor: MyColors.fabGreenButton,
          onPressed: () {
            // ホーム画面に戻る
            context.go(Home.routeName);
          },
          child: MyCustomText(text: '内容を確認し、閉じる', textColor: Colors.white, fontSize: 16),
        ),
      ),
      body: _BodyContent(selectedStore: selectedStore),
    );
  }
}

class _BodyContent extends StatelessWidget {
  const _BodyContent({required this.selectedStore});
  final MobileOrderCompletion selectedStore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        // 受取番号と時間に関する表示
        _ColumnReceivedNumberAndWaitTime(receivedNumber: selectedStore.pickupNumber),
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: MyColors.horizontalDivider, width: 0.25),
              bottom: BorderSide(color: MyColors.horizontalDivider, width: 0.25),
            ),
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 10, // 高さ10

            child: ColoredBox(color: Color(0xFFF4F4F4)),
          ),
        ),
        // 店舗情報に関する表示
        _ColumnStoreInfomation(selectedStore: selectedStore),
        // 受取方法について
        const Expanded(child: _ColumnReceiveWay()),
      ],
    );
  }
}

/// 受取番号と時間に関する表示
class _ColumnReceivedNumberAndWaitTime extends StatelessWidget {
  const _ColumnReceivedNumberAndWaitTime({required this.receivedNumber});
  final String receivedNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 受取番号と時間に関する表示
        Row(
          mainAxisAlignment: .center,
          children: const [
            Icon(Icons.local_drink_rounded, color: MyColors.fabGreenButton, size: 30),
            SizedBox(width: 10),
            MyCustomText(text: '受取番号', fontSize: 20, fontWeight: FontWeight.bold),
          ],
        ),
        const SizedBox(height: 15),
        MyCustomText(text: receivedNumber, fontSize: 32, fontWeight: FontWeight.bold),
        const SizedBox(height: 10),
        // ニックネームが設定されている場合は案内を表示しない
        if (receivedNumber.contains('*'))
          const MyCustomText(text: 'ニックネームに変えてみません？', fontSize: 16, textColor: MyColors.greenText),
        const SizedBox(height: 5),
        const Divider(color: MyColors.horizontalDivider),
        const SizedBox(height: 5),
        MyCustomText(text: '受取時間 約{min}～{max}分後', fontSize: 20, fontWeight: FontWeight.bold),
        const SizedBox(height: 15),
      ],
    );
  }
}

/// 店舗情報に関する表示
class _ColumnStoreInfomation extends StatefulWidget {
  const _ColumnStoreInfomation({required this.selectedStore});
  final MobileOrderCompletion selectedStore;

  @override
  State<_ColumnStoreInfomation> createState() => _ColumnStoreInfomationState();
}

class _ColumnStoreInfomationState extends State<_ColumnStoreInfomation> {
  final FavoriteStoreService _favoriteService = FavoriteStoreService();
  final Map<String, bool> _favoriteStores = {};
  // こんな使い方できたんだ。
  bool get isFavorite => _favoriteStores[widget.selectedStore.storeNumber] ?? false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final isFavorite = await _favoriteService.isStoreFavorite(widget.selectedStore.storeNumber);
      setState(() {
        _favoriteStores[widget.selectedStore.storeNumber] = isFavorite;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入りの取得中にエラーが発生しました: $e');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// お気に入り店舗の追加・削除
  Future<void> _toggleFavorite(String storeNumber) async {
    final isFavorite = _favoriteStores[storeNumber] ?? false;

    try {
      if (isFavorite) {
        await _favoriteService.removeFavoriteStore(storeNumber);
      } else {
        await _favoriteService.addFavoriteStore(storeNumber);
      }

      // Update state
      setState(() {
        _favoriteStores[storeNumber] = !isFavorite;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('お気に入りの更新中にエラーが発生しました: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          SizedBox(height: 5),
          Row(
            children: [
              MyCustomText(
                text: widget.selectedStore.storeName,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  // お気に入りの追加・削除
                  _toggleFavorite(widget.selectedStore.storeNumber);
                },
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border_sharp,
                  color: isFavorite ? MyColors.greenButton : null,
                ),
              ),
              SizedBox(width: 15),
              Icon(Icons.info_outline),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              MyCustomText(
                text: widget.selectedStore.address,
                fontSize: 14,
                textColor: MyColors.greyText,
              ),
            ],
          ),
          SizedBox(height: 3),
        ],
      ),
    );
  }
}

/// 受取方法について
class _ColumnReceiveWay extends StatelessWidget {
  const _ColumnReceiveWay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: MyColors.horizontalDivider, width: 0.25)),
      ),
      child: const SizedBox(
        width: double.infinity,
        child: ColoredBox(
          color: Color(0xFFF4F4F4),
          child: Padding(
            padding: .all(15),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  spacing: 10,
                  children: [
                    Icon(Icons.store_rounded, color: Colors.grey, size: 30),
                    MyCustomText(
                      text: 'How to pick up',
                      textColor: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      MyCustomText(text: '1.受取時間を目安に店舗へ', textColor: Colors.black54, fontSize: 16),
                      MyCustomText(
                        text: '2.商品の受け取りカウンターへ',
                        textColor: Colors.black54,
                        fontSize: 16,
                      ),
                      MyCustomText(text: '3.商品ラベルの受取番号(ニックネーム)を確認し受取', textColor: Colors.black54),
                      SizedBox(height: 10),
                      MyCustomText(
                        text: 'ドライブスルーでは受け取りできません。',
                        textColor: Colors.black54,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
