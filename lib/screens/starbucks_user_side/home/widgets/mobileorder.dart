import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/supabase_rpcs.dart';
import '../../../../constants/supabase_tables.dart';
import '../../../../core/models/awaiting_pickup_mobileorder.dart';
import '../../../../core/models/mobile_order_history.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../shared/widgets/dialogs/error_dialog.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../mobile_order_pay/mobileorder_tab_container.dart';
import '../../mobile_order_pay/tab_histories/histories_detail.dart';

const Color grey500 = Color(0xFF9E9E9E);

///Section:モバイルオーダー
class HomeMobileOrderSection extends StatefulWidget {
  const HomeMobileOrderSection({super.key});

  @override
  State<HomeMobileOrderSection> createState() => _HomeMobileOrderSectionState();
}

class _HomeMobileOrderSectionState extends State<HomeMobileOrderSection> {
  bool isLoading = true;
  AwaitingPickupOrder awaitingPickupOrders = AwaitingPickupOrder.empty();

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
      LoggerService.info('ホーム画面：モバイルオーダー情報取得開始');

      // 昨日の日付（今日の00:00:00）を計算
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day);

      // provided_status が 0 のデータを登録日時の降順で最新1件取得
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from(Tables.orders)
          .select('''
            pickup_number,
            created_at,
            stores(store_name)
          ''')
          .eq('provided_status', 0)
          .order('created_at', ascending: false)
          .limit(1);

      final orders = response.map((item) => AwaitingPickupOrder.fromJson(item)).toList();

      setState(() {
        // 最新データが昨日より古い場合は表示しない
        if (orders.isNotEmpty && orders[0].createdAt.isAfter(yesterday)) {
          awaitingPickupOrders = orders[0];
          LoggerService.info('モバイルオーダー情報取得完了: 受取番号=${orders[0].pickupNumber}');
        } else {
          if (orders.isNotEmpty) {
            LoggerService.info('モバイルオーダー情報は昨日より古いため表示しません: ${orders[0].formattedCreatedDate}');
          } else {
            LoggerService.info('受取待ちのモバイルオーダーなし');
          }
        }
        isLoading = false;
      });
    } catch (error) {
      LoggerService.warn('モバイルオーダー情報の取得に失敗しました', error);
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const SizedBox()
        : awaitingPickupOrders.pickupNumber == ''
        ? const _NoOrder()
        : _HasOrder(order: awaitingPickupOrders);
  }
}

///受取前のモバイルオーダーがある場合
class _HasOrder extends StatelessWidget {
  const _HasOrder({required this.order});
  final AwaitingPickupOrder order;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Container(
        decoration: BoxDecoration(color: Colors.black87),
        child: InkWell(
          splashColor: Color(0x30f010f0),
          onTap: () => {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: .start,
                  children: [
                    // タイトルテキスト
                    const MyCustomText(
                      text: 'MOBILE ORDER & PAY',
                      textColor: grey500,
                      useEnglishFont: true,
                    ),
                    const SizedBox(height: 12.0),
                    // 日本語テキスト
                    Row(
                      spacing: 10,
                      children: [
                        const MyCustomText(text: '受取番号', textColor: Colors.white, fontSize: 14.0),
                        MyCustomText(
                          text: order.pickupNumber,
                          textColor: Colors.white,
                          fontSize: 30.0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const MyCustomText(
                      text: '受取時間 約3～5分後',
                      textColor: Colors.white,
                      fontSize: 14.0,
                    ),
                    const SizedBox(height: 10),
                    MyCustomText(
                      text: order.formattedCreatedDate,
                      textColor: Colors.white,
                      fontSize: 14.0,
                    ),
                    const SizedBox(height: 10),
                    MyCustomText(text: order.storeName, textColor: Colors.white, fontSize: 14.0),
                    const SizedBox(height: 10),
                    _ButtonCheckOrder(order: order),
                  ],
                ),
                const _MobileOrderImage(100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// オーダー確認ボタン
class _ButtonCheckOrder extends ConsumerWidget {
  const _ButtonCheckOrder({required this.order});

  final AwaitingPickupOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: () async {
        // 注文詳細画面へ遷移
        await _navigateToOrderDetail(context);
      },
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        minimumSize: const Size(0, 35),
      ),
      child: const MyCustomText(text: 'オーダーを見る', fontSize: 16.0, fontWeight: FontWeight.w500),
    );
  }

  /// 注文詳細画面へ遷移
  Future<void> _navigateToOrderDetail(BuildContext context) async {
    try {
      // 受取番号を使用してフルオーダー情報を取得
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        // ログインしていない場合は従来の動作（タブ切り替え）
        if (context.mounted) {
          showErrorDialog(context, 'ログインが必要です。');
        }
        return;
      }

      // 受取番号を使用してフルオーダー情報を取得
      final response = await supabase.rpc<List<Map<String, dynamic>>>(
        Rpcs.getUserOrders,
        params: {'p_user_id': userId},
      );

      if (response.isNotEmpty) {
        // 注文情報が見つかった場合
        final orderHistory = MobileOrderHistory.fromJson(response[0]);

        if (context.mounted) {
          LoggerService.info('「オーダーを見る」ボタン押下 - 注文履歴詳細画面へ遷移: 受取番号=${order.pickupNumber}');
          // 詳細画面へ遷移
          context.go(
            '${MobileOrderTabContainer.routeName}${MobileOrderPayTabHistoriesHistoryDetail.routeName}',
            extra: orderHistory,
          );
        }
      } else {
        // 注文情報が見つからない場合
        if (context.mounted) {
          showErrorDialog(context, '注文情報が見つかりませんでした。');
        }
      }
    } catch (e) {
      // エラーが発生した場合
      if (context.mounted) {
        showErrorDialog(context, '注文情報の取得中にエラーが発生しました。：$e');
      }
    }
  }
}

///受取前のモバイルオーダーがない場合
class _NoOrder extends StatelessWidget {
  const _NoOrder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Container(
        decoration: BoxDecoration(color: Colors.black87),
        child: InkWell(
          splashColor: Color(0x30f010f0),
          onTap: () => {},
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // タイトルテキスト
                    MyCustomText(text: 'MOBILE ORDER & PAY', textColor: grey500),
                    SizedBox(height: 12.0),
                    // 日本語テキスト
                    MyCustomText(text: 'レジに並ばず、\nお店で受け取り', textColor: Colors.white, fontSize: 20.0),
                    SizedBox(height: 36.0),
                    _OrderElevatedButton(),
                  ],
                ),
                _MobileOrderImage(150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// オーダーボタン
class _OrderElevatedButton extends StatelessWidget {
  const _OrderElevatedButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        LoggerService.info('「オーダーする」ボタン押下 - モバイルオーダータブへ遷移');
        // モバイルオーダーのタブに遷移
        context.go(MobileOrderTabContainer.routeName);
      },
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        minimumSize: const Size(0, 35), //垂直方向の余白調整
      ),
      child: const MyCustomText(text: 'オーダーする', fontSize: 16.0, fontWeight: FontWeight.w500),
    );
  }
}

/// 画像
class _MobileOrderImage extends StatelessWidget {
  const _MobileOrderImage(this.width);
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width, // 適切な幅を指定
      child: Image(height: 175, image: AssetImage('assets/starbucks/png/mobile_order.png')),
    );
  }
}
