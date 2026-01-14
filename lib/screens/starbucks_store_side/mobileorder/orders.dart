import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/menu.dart';
import '../../../constants/my_colors.dart';
import '../../../constants/supabase_rpcs.dart';
import '../../../constants/supabase_tables.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import '../model/store_order.dart';

//　店舗側のオーダー一覧
class StoreSideOrderList extends StatefulWidget {
  const StoreSideOrderList({super.key});

  static String routeName = '/starbucks_store_side_home';

  @override
  State<StoreSideOrderList> createState() => _StoreSideOrderListState();
}

class _StoreSideOrderListState extends State<StoreSideOrderList> {
  bool isLoading = true;
  List<StoreOrder> orderList = [];
  Set<String> completedOrderIdList = {}; // Set使用でO(1)検索に最適化
  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final String? userData = await authService.retrieveLoginUser();
      if (userData != null) {
        // 特定のユーザーIDに基づいてデータを取得
        final List<dynamic> response = await supabase.rpc(
          Rpcs.getStoreOrders,
          params: {'p_user_id': '0011c0f3-e1a9-4149-bad4-d8320f5772a8'},
        );

        final orders = StoreOrder.fromJsonList(response);
        // debugPrint(orders);

        setState(() {
          orderList = orders;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching store orders: $e');
    }
  }

  // 画面遷移時に、データベースから取得した注文情報を渡す
  Future<void> _updateProvidedStatusFromReadyToCompleted() async {}

  void _toggleOrderCompletion(String orderId) {
    setState(() {
      final orderIndex = orderList.indexWhere((order) => order.orderId == orderId);
      if (orderIndex != -1) {
        // 注文のisCompleted状態を切り替える
        orderList[orderIndex].isCompleted = !orderList[orderIndex].isCompleted;

        // completedOrderIdListを更新（Set使用で重複チェック不要）
        if (orderList[orderIndex].isCompleted) {
          completedOrderIdList.add(orderId);
        } else {
          completedOrderIdList.remove(orderId);
        }
      }
    });
  }

  ///提供状態を更新（0(準備中)→1(提供準備完了)へ）
  Future<void> updateOrderStatus(String orderId) async {
    final SupabaseClient supabase = Supabase.instance.client;
    // データ更新操作
    // final updateRes =
    await supabase
        .from(Tables.orders)
        .update({'provided_status': '1'})
        .eq('order_id', orderId)
        .select();
    // debugPrint(updateRes);
  }

  // ユーザーに注文準備完了を通知するモーダルを表示
  void _notifyUserOrderReadyModal(BuildContext context, StoreOrder order) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルト:40
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: .start,
              children: [
                const MyCustomText(text: '提供準備完了', fontSize: 28, fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                MyCustomText(text: order.pickupNumber, fontSize: 20, fontWeight: FontWeight.bold),
                const SizedBox(height: 10),
                const MyCustomText(text: '上記受付番号の注文の提供準備が完了しましたか？', fontSize: 14, softwrap: true),
                const SizedBox(height: 20),
                Row(
                  spacing: 15,
                  mainAxisAlignment: .end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyColors.greenButton,
                        side: BorderSide(color: MyColors.greenButton, width: 0.8),
                        padding: EdgeInsets.symmetric(horizontal: 25),
                        minimumSize: Size(0, 50),
                        splashFactory: InkSplash.splashFactory,
                      ),
                      child: const MyCustomText(text: 'キャンセル', textColor: MyColors.greenButton),
                    ),
                    FilledButton(
                      onPressed: () async {
                        // 通知処理のためのデータ更新を実行
                        try {
                          await updateOrderStatus(order.orderId);
                          // データ最新化
                          await _loadData();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (error) {
                          debugPrint('オーダーステータス更新でエラーが発生: $error');
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: MyColors.greenButton,
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        minimumSize: const Size(0, 50),
                      ),
                      child: const MyCustomText(text: 'OK', textColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // 提供完了状態にした注文について、データベースに反映を行う
    _updateProvidedStatusFromReadyToCompleted();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // アプリのHome画面に戻る
        context.go(MenuPage.routeName);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor)
                : _buildOrderList(),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const MyCustomText(text: '注文一覧', fontSize: 32),
          const SizedBox(height: 10),
          MyCustomText(
            text: orderList.isNotEmpty ? '対象店舗：${orderList[0].storeName}' : '',
            fontSize: 20,
          ),
          const SizedBox(height: 5),
          ButtonLogin(onAuthStatusChanged: _loadData),
          const SizedBox(height: 10),
          if (orderList.isNotEmpty)
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final order = orderList[index];
                      return Card(
                        // color: order.isCompleted ? Colors.black38 : Colors.white,
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: MyColors.greenButton, // ボーダーの色
                          ),
                          borderRadius: BorderRadius.circular(10.0), // 角の丸み
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: SizedBox(
                          height: 250,
                          child: InkWell(
                            onTap: () {
                              // 詳細確認画面へ
                            },
                            child: Column(
                              crossAxisAlignment: .start,
                              children: [
                                Padding(
                                  padding: const .all(16.0),
                                  child: Column(
                                    crossAxisAlignment: .start,
                                    children: [
                                      // 店舗/モバイル、#NNNか受取番号を表示（あとUberとかもあるのか）
                                      const MyCustomText(text: '受取番号', fontSize: 20),
                                      MyCustomText(text: order.pickupNumber, fontSize: 30),
                                      const SizedBox(height: 15),
                                      // 注文の商品数
                                      const MyCustomText(text: '注文商品数', fontSize: 20),
                                      MyCustomText(text: '${order.totalItemCount} 点', fontSize: 30),
                                      const SizedBox(height: 15),
                                      Row(
                                        mainAxisAlignment: .end,
                                        children: [
                                          if (order.providedStatus == '0')
                                            FilledButton(
                                              onPressed: () {
                                                // 通知処理
                                                _notifyUserOrderReadyModal(context, order);
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: MyColors.greenButton,
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                minimumSize: const Size(0, 50),
                                              ),
                                              child: const MyCustomText(
                                                text: 'Ready',
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                                textColor: Colors.white,
                                              ),
                                            )
                                          else
                                            FilledButton(
                                              onPressed: () {
                                                _toggleOrderCompletion(order.orderId);
                                              },
                                              style: FilledButton.styleFrom(
                                                backgroundColor: order.isCompleted
                                                    ? MyColors.greyText
                                                    : MyColors.greenButton,
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                minimumSize: const Size(0, 50),
                                              ),
                                              child: MyCustomText(
                                                text: order.isCompleted ? 'Completed' : 'Recieved',
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                                textColor: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: orderList.length),
                  ),
                ],
              ),
            )
          else
            Column(
              children: const [
                SizedBox(height: 30),
                MyCustomText(
                  text: 'ログインは済んでいますか？',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.black,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class ButtonLogin extends StatefulWidget {
  const ButtonLogin({super.key, required this.onAuthStatusChanged});
  final void Function() onAuthStatusChanged;

  @override
  State<ButtonLogin> createState() => _ButtonLoginState();
}

class _ButtonLoginState extends State<ButtonLogin> {
  final AuthService authService = AuthService();
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final String? userData = await authService.retrieveLoginUser();
    setState(() {
      userEmail = userData;
    });
  }

  Future<void> _handleAuth() async {
    try {
      if (userEmail != null) {
        await authService.signOutWithEmailAndPassword();
        setState(() {
          userEmail = null;
        });
        widget.onAuthStatusChanged(); // Call the callback after sign out
      } else {
        await authService.signInWithEmailAndPassword('0011@gmail.com', '0011');
        setState(() {
          userEmail = '0011@gmail.com';
        });
        widget.onAuthStatusChanged(); // Call the callback after sign in
      }
    } on PlatformException catch (e) {
      debugPrint('認証処理に失敗しました: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (userEmail != null)
          Padding(padding: const EdgeInsets.only(bottom: 10.0), child: Text('ログイン中: $userEmail')),
        FilledButton(
          onPressed: _handleAuth,
          style: FilledButton.styleFrom(
            backgroundColor: MyColors.greenButton,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            minimumSize: const Size(0, 50),
          ),
          child: MyCustomText(
            text: userEmail != null ? 'ログアウト' : 'ログイン',
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
