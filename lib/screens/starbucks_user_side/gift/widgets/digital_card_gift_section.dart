import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../../shared/widgets/texts/my_custom_text.dart';

const String egiftForyouSvgPath = 'assets/starbucks/svg/egift_foryou.svg';

/// Starbucks Degital Cardセクション
class GiftDigitalCardGiftSection extends StatelessWidget {
  const GiftDigitalCardGiftSection({super.key});

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
    return Row(
      children: const [MyCustomText(text: 'Digital Card Gift', fontSize: 22, useEnglishFont: true)],
    );
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
            text: 'メールやLINEなどのSNSNで贈れるデジタルカード。1,000円から3,000,000円wまでのお好きな金額を入力できます。',
            fontSize: 12,
            softwrap: true,
          ),
        ),
        const SizedBox(width: 20),
        const VectorGraphic(width: 70, loader: AssetBytesLoader(egiftForyouSvgPath)),
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
            // context.push(fullPath.join());
          },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            minimumSize: const Size(0, 35),
          ),
          child: const MyCustomText(
            text: 'Digital Cardを贈る',
            textColor: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
