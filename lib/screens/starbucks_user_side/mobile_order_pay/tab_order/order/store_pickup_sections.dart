import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/order_type.dart';
import '../../../../../core/models/cart.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import '../../mobileorder_tab_container.dart';
import '../../store/store_selection.dart';
import '../pickup_method.dart';

/// 店舗選択エリア
class SelectedStoreSection extends ConsumerWidget {
  const SelectedStoreSection({super.key, required this.cart});
  final Cart? cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: () {
                context.go('${MobileOrderTabContainer.routeName}${StoreSelect.routeName}');
              },
              child: Container(
                height: cart == null ? 70 : 100,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Color(0xFFD8D8D8), width: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    Column(
                      crossAxisAlignment: .start,
                      mainAxisAlignment: .center,
                      children: cart == null
                          ? [
                              const MyCustomText(
                                text: 'お店を選択してください',
                                textColor: Colors.black,
                                fontSize: 16,
                              ),
                            ]
                          : [
                              MyCustomText(
                                text: cart?.storeName ?? '',
                                textColor: Color(0xFF939191),
                                fontSize: 14,
                              ),
                              const MyCustomText(
                                text: '約5～10分後',
                                textColor: Colors.black,
                                fontSize: 16,
                              ),
                              const MyCustomText(
                                text: '※注文状況により変動します',
                                textColor: Color(0xFF939191),
                                fontSize: 12,
                              ),
                            ],
                    ),
                    const Spacer(),
                    const Column(
                      mainAxisAlignment: .center,
                      children: [Icon(Icons.arrow_forward_ios_rounded, size: 16)],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 利用方法選択
class SelectedPickupMethodSection extends ConsumerWidget {
  const SelectedPickupMethodSection({super.key, required this.cart});
  final Cart? cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: cart != null
                  ? () {
                      context.go(
                        '${MobileOrderTabContainer.routeName}${MobileOrderPickupMethod.routeName}',
                      );
                    }
                  : null,
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(color: Color(0xFFD8D8D8), width: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: .center,
                  children: [
                    if (cart?.usage == OrderType.toGo.typeValue)
                      MyCustomText(
                        text: 'TO GO(お持ち帰り)',
                        textColor: cart != null ? Colors.black : Colors.grey,
                        fontSize: 16,
                      )
                    else
                      const MyCustomText(text: '店内飲食', textColor: Colors.black, fontSize: 16),
                    const Spacer(),
                    Column(
                      mainAxisAlignment: .center,
                      children: [
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: cart != null ? Colors.black : Colors.grey,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
