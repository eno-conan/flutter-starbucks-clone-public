import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../../constants/my_colors.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../gift_starbucks_egift/egift_creation_screen.dart';

const String egiftForyouSvgPath = 'assets/starbucks/svg/egift_foryou.svg';

/// Starbucks eGiftセクション
class GiftEgiftSection extends StatelessWidget {
  const GiftEgiftSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      height: 180,
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.white),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            spacing: 5,
            mainAxisAlignment: .center,
            children: [RowTitle(), RowDescriptionAndIllustration(), RowSendEgiftOutlinedButton()],
          ),
        ),
      ),
    );
  }
}

class RowTitle extends StatelessWidget {
  const RowTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: const [MyCustomText(text: 'Starbucks eGift', fontSize: 22)]);
  }
}

/// 概要とイラスト（svg）
class RowDescriptionAndIllustration extends StatelessWidget {
  const RowDescriptionAndIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width;
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        SizedBox(
          width: size * 0.625,
          child: const MyCustomText(
            text: 'LINEやSNSで500円から贈れるデジタルチケット。受け取りもかんたんですぐに使えるギフトです。',
            fontSize: 12,
            softwrap: true,
          ),
        ),
        const SizedBox(width: 20),
        VectorGraphic(width: size * 0.18, loader: const AssetBytesLoader(egiftForyouSvgPath)),
        const SizedBox(width: 20),
      ],
    );
  }
}

/// eGiftを贈るボタン
class RowSendEgiftOutlinedButton extends StatelessWidget {
  const RowSendEgiftOutlinedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton(
          onPressed: () {
            context.go('/home/tab5/${GiftEgift.routeName}');
            // final fullPath = RouteFinder.getFullPath(GiftEgift.routeName);
            // context.push(fullPath.join());
          },
          style: FilledButton.styleFrom(
            backgroundColor: MyColors.greenButton,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            minimumSize: const Size(0, 35),
          ),
          child: const MyCustomText(
            text: 'eGiftを贈る',
            textColor: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
