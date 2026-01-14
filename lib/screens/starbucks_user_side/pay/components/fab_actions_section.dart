import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../payment/deposit_screen.dart';
import 'fab_add_balance.dart';

/// 支払い画面のFloatingActionButtonのコンテンツ
class PayFloatingActionButtons extends StatelessWidget {
  const PayFloatingActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        _FloatingActionButtonBuilder(bottom: 10, width: 100, widget: _PaymentFloatingButton()),
        _FloatingActionButtonBuilder(bottom: 90, width: 90, widget: PayAddBalanceFloatingButton()),
      ],
    );
  }
}

///支払いボタン
class _PaymentFloatingButton extends StatelessWidget {
  const _PaymentFloatingButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: FloatingActionButton(
        heroTag: null,
        elevation: 2,
        onPressed: () {
          context.push(PayPayment.routeName);
          // final fullPath = RouteFinder.getFullPath(PayPayment.routeName);
          // context.push(fullPath.join());
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
        backgroundColor: MyColors.fabGreenButton,
        child: const MyCustomText(text: '支払い', textColor: Colors.white, fontSize: 18),
      ),
    );
  }
}

/// FloatingButton骨組み
class _FloatingActionButtonBuilder extends StatelessWidget {
  const _FloatingActionButtonBuilder({
    required this.bottom,
    required this.width,
    required this.widget,
  });
  final double bottom;
  final double width;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: 5,
      child: SizedBox(width: width, child: widget),
    );
  }
}
