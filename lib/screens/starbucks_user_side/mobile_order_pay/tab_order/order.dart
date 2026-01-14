import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../constants/my_colors.dart';
import '../../../../constants/supabase_rpcs.dart';
import '../../../../constants/supabase_tables.dart';
import '../../../../core/models/card_model.dart';
import '../../../../core/models/cart.dart';
import '../../../../core/models/cart_detail.dart';
import '../../../../core/models/user_nickname.dart';
import '../../../../provider/auth_state_provider.dart';
import '../../../../provider/connectivity_check_provider.dart';
import '../../../../provider/last_order_completion_provider.dart';
import '../../../../provider/nickname_dialog_state_provider.dart';
import '../../../../shared/widgets/dialogs/init_nickname_dialog.dart';
import '../../../../shared/widgets/dialogs/nickname_action_bottom_sheet.dart';
import '../../../../shared/widgets/dialogs/nickname_dialog.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import 'order/additional_sections.dart';
import 'order/product_sections.dart';
import 'order/store_pickup_sections.dart';
import 'order/total_payment_sections.dart';

/// モバイルオーダートップ画面
class MobileOrderPayTabOrder extends ConsumerStatefulWidget {
  const MobileOrderPayTabOrder({super.key, required this.onRefreshOrders, this.isVisible = false});
  final Future<void> Function() onRefreshOrders;
  final bool isVisible; // タブの可視性を追加

  @override
  ConsumerState<MobileOrderPayTabOrder> createState() => _MobileOrderPayTabOrderState();
}

class _MobileOrderPayTabOrderState extends ConsumerState<MobileOrderPayTabOrder>
    with WidgetsBindingObserver {
  bool _isInitialized = false;
  bool _isLoading = true;

  // ニックネーム情報
  UserNickname? nickname;
  // カード情報
  CardModel? cardData;
  // カート情報
  Cart? cartData;
  // カート詳細情報
  List<CartDetail>? cartDetailsData;

  // 計算結果格納
  int? _totalAmountExcludingTax;
  int? _totalTax;
  int? _totalAmountIncludingTax;

  @override
  void initState() {
    super.initState();
    _isInitialized = true;

    // データ取得完了後にダイアログをチェック
    _fetchInitialData().then((_) {
      // mounted チェックはここだけ（Futureが完了した時点）
      if (!mounted) {
        return;
      }

      if (widget.isVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // この時点では必ずmountedなので、mountedチェックは不要
          _checkAndShowNicknameDialog();
        });
      }
    });
  }

  @override
  void didUpdateWidget(MobileOrderPayTabOrder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized) {
      _fetchInitialData().then((_) {
        // mounted チェックはここだけ（Futureが完了した時点）
        if (!mounted) {
          return;
        }

        // タブの可視性が変更された場合にニックネームダイアログをチェック
        if (widget.isVisible && !oldWidget.isVisible) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // この時点では必ずmountedなので、mountedチェックは不要
            _checkAndShowNicknameDialog();
          });
        }
      });
    }
  }

  // 計算メソッドを追加
  void _calculateTotals() {
    if (cartDetailsData != null && cartData != null) {
      _totalAmountExcludingTax = CartDetail.calculateTotalSubtotalSafeAsInt(cartDetailsData);
      _totalTax = (_totalAmountExcludingTax! * cartData!.getTaxRate()).toInt();
      _totalAmountIncludingTax = _totalAmountExcludingTax! + _totalTax!;
    } else {
      _totalAmountExcludingTax = null;
      _totalTax = null;
      _totalAmountIncludingTax = null;
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final SupabaseClient supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      if (kDebugMode) {
        debugPrint('Error: ユーザーが認証されていません');
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 並列実行で高速化
    final results = await Future.wait([
      _fetchNickname(supabase, userId),
      _fetchCardData(supabase),
      _fetchCartData(),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      nickname = results[0] as UserNickname?;
      cardData = results[1] as CardModel?;

      final cartResult = results[2]! as Map<String, dynamic>;
      final cartInfo = cartResult['cartInfo'] as Map<String, dynamic>?;
      final cartDetails = cartResult['cartDetails'] as List<CartDetail>;

      if (cartInfo == null || cartInfo.isEmpty) {
        cartData = null;
        cartDetailsData = null;
      } else {
        cartData = Cart.fromJson(cartInfo);
        cartDetailsData = cartDetails;
      }

      _calculateTotals();
      _isLoading = false;
    });
  }

  // 各データ取得を独立した関数に分離
  Future<UserNickname?> _fetchNickname(SupabaseClient supabase, String userId) async {
    try {
      final nicknameInfo = await supabase
          .from(Tables.userNickname)
          .select('nick_name')
          .eq('user_id', userId)
          .maybeSingle();
      return nicknameInfo != null ? UserNickname.fromJson(nicknameInfo) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching nickname: $e');
      }
      return null;
    }
  }

  Future<CardModel?> _fetchCardData(SupabaseClient supabase) async {
    try {
      final cardInfo = await supabase
          .from(Tables.cards)
          .select('card_id, card_name, image_url, balance')
          .eq('is_main', 1)
          .maybeSingle();
      return CardModel.fromJsonOrNull(cardInfo);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching card data: $e');
      }
      return null;
    }
  }

  /// ニックネームダイアログの表示チェック
  void _checkAndShowNicknameDialog() {
    // debugPrint('nickname check: ${nickname?.nickName}');

    // ニックネームが既に登録されている場合は表示しない
    if (nickname != null && nickname!.nickName.isNotEmpty) {
      return;
    }

    final dialogState = ref.read(nicknameDialogProvider);

    // 「次回から表示しない」がチェックされている場合は表示しない
    if (dialogState.dontShowAgain) {
      return;
    }

    // 注文完了後30秒間はダイアログを表示しない
    final lastOrderCompletion = ref.read(lastOrderCompletionProvider.notifier);
    if (!lastOrderCompletion.hasElapsedSince()) {
      return;
    }

    final authAsync = ref.read(authStateProvider);

    authAsync.when(
      loading: () {
        // 認証中は何もしない
      },
      error: (error, stackTrace) {
        // 認証エラー時は何もしない
      },
      data: (user) {
        if (user == null) {
          return;
        }

        final connectivity = ref.read(connectivityCheckProvider);

        connectivity.whenData((results) {
          if (results.first != ConnectivityResult.none && mounted) {
            // 初回は showInitNickNameModal、2回目以降は showNickNameModal
            if (!dialogState.hasShownInitDialog) {
              ref.read(nicknameDialogProvider.notifier).markInitDialogShown();
              showInitNickNameModal(
                context,
                onNicknameUpdated: _refreshNicknameData,
                onDontShowAgainChecked: () {
                  ref.read(nicknameDialogProvider.notifier).setDontShowAgain(true);
                },
              );
            } else {
              showNickNameModal(context, onNicknameUpdated: _refreshNicknameData);
            }
          }
        });
      },
    );
  }

  // ニックネーム情報のみを再取得するメソッドを追加
  Future<void> _refreshNicknameData() async {
    final SupabaseClient supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return;
    }

    try {
      final nicknameInfo = await supabase
          .from(Tables.userNickname)
          .select('nick_name')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          nickname = nicknameInfo != null ? UserNickname.fromJson(nicknameInfo) : null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing nickname: $e');
      }
    }
  }

  // データ再取得メソッドを追加
  Future<void> _refreshCartData() async {
    try {
      // カートデータを取得(共通関数を使用)
      final Map<String, dynamic> fetchedCartData = await _fetchCartData();
      Map<String, dynamic>? cartInfo;
      List<CartDetail> cartDetails = <CartDetail>[];
      cartInfo = fetchedCartData['cartInfo'] != null
          ? Map<String, dynamic>.from(fetchedCartData['cartInfo'] as Map)
          : null;

      cartDetails = (fetchedCartData['cartDetails'] as List?)?.cast<CartDetail>() ?? <CartDetail>[];

      if (!mounted) {
        return;
      }

      setState(() {
        if (cartInfo == null || cartInfo.isEmpty) {
          // カートが空の場合
          cartData = null;
          cartDetailsData = null;
        } else {
          cartData = Cart.fromJson(cartInfo);
          cartDetailsData = cartDetails.isNotEmpty ? cartDetails : null;
        }
        _calculateTotals();
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing cart data: $e');
      }
    }
  }

  // カート関連データを取得する共通関数
  Future<Map<String, dynamic>> _fetchCartData() async {
    final SupabaseClient supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('ユーザーが認証されていません');
    }

    // カート情報を取得（店舗名はstoresテーブルから取得）
    final responseCartWithStore =
        await supabase.rpc<List<Map<String, dynamic>>>(
              Rpcs.getCartWithStore,
              params: {'p_user_id': userId},
            )
            as List<dynamic>?;

    if (responseCartWithStore == null || responseCartWithStore.isEmpty) {
      // 空の場合の処理
      return {'cartInfo': null, 'cartDetails': <CartDetail>[]};
    }

    final cartInfo = responseCartWithStore.first;

    // カート情報が存在する場合、カート詳細情報を取得
    final response = await supabase.rpc<List<Map<String, dynamic>>>(
      Rpcs.getCartDetails,
      params: {'input_user_id': userId},
    );
    final List<CartDetail> cartDetails = (response as List)
        .map((item) => CartDetail.fromJson(item as Map<String, dynamic>))
        .toList();

    return {'cartInfo': cartInfo, 'cartDetails': cartDetails};
  }

  @override
  Widget build(BuildContext context) {
    final hasCartItems = (cartDetailsData?.length ?? 0) > 0;

    return _isLoading
        ? Center(child: CircularProgressIndicator(color: MyColors.circularProgressIndicatorColor))
        : ColoredBox(
            color: MyColors.backgroundGrey,
            child: CustomScrollView(
              slivers: <Widget>[
                SelectedStoreSection(cart: cartData), //利用店舗
                const SliverToBoxAdapter(child: SizedBox(height: 5)),
                SelectedPickupMethodSection(cart: cartData), //利用方法
                SelectedProductSection(
                  cart: cartData,
                  cartDetailsData: cartDetailsData,
                  onRefreshCart: _refreshCartData,
                ), //選択商品
                const CheckBoxPaperBag(), //paper bag
                if (hasCartItems) ...[
                  GrandTotalSection(
                    taxRate: cartData?.getTaxRateAsPercent() ?? 0,
                    totalAmountExcludingTax: CartDetail.calculateTotalSubtotalSafe(cartDetailsData),
                    totalTax: Cart.formatWithComma(_totalTax ?? 0),
                    totalAmountIncludingTax: Cart.formatWithComma(_totalAmountIncludingTax ?? 0),
                    itemCount: cartDetailsData?.length ?? 0,
                  ), // 合計金額表示エリア
                  CardInfoAndButtonSettlement(
                    cart: cartData,
                    cartDetailsData: cartDetailsData,
                    totalAmountExcludingTax: _totalAmountExcludingTax ?? 0,
                    totalAmountIncludingTax: _totalAmountIncludingTax ?? 0,
                    cardData: cardData,
                    onRefreshOrders: widget.onRefreshOrders,
                    nickname: nickname?.nickName,
                  ), //利用規約・決済実施
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                NickNameSection(
                  nickname: nickname,
                  onNicknameUpdated: _refreshNicknameData,
                ), // ニックネーム表示
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
            ),
          );
  }
}

/// ニックネーム表示エリア
class NickNameSection extends StatelessWidget {
  const NickNameSection({super.key, required this.nickname, this.onNicknameUpdated});

  final UserNickname? nickname;
  final VoidCallback? onNicknameUpdated;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (nickname != null)
              Row(
                children: [
                  MyCustomText(text: 'ニックネーム:', textColor: MyColors.greyText),
                  GestureDetector(
                    onTap: () =>
                        showNicknameActionSheet(context, onNicknameUpdated: onNicknameUpdated),
                    child: MyCustomText(text: nickname!.nickName, textColor: MyColors.greenText),
                  ),
                ],
              )
            else
              GestureDetector(
                onTap: () => showNickNameModal(context, onNicknameUpdated: onNicknameUpdated),
                child: MyCustomText(text: 'ニックネームを使用する', textColor: MyColors.greenText),
              ),
          ],
        ),
      ),
    );
  }
}
