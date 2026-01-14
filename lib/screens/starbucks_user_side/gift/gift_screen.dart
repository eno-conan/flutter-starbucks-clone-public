import 'package:flutter/material.dart';

import '../../../shared/widgets/headers/fixed_header.dart';
import 'widgets/carousel_section.dart';
import 'widgets/digital_card_gift_section.dart';
import 'widgets/egift_section.dart';

///Starbucks eGiftのトップ画面
class Gift extends StatelessWidget {
  const Gift({super.key});
  static String routeName = '/starbucks_e_gift_top';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: false,
      headerText: 'Gift',
      isFab: false,
      body: _Contents(),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFFF4F4F4),
      child: Column(
        spacing: 5,
        children: const [
          CarouselSection(), // カルーセル
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 7.5,
                children: [
                  GiftEgiftSection(), //Starbucks eGiftセクション
                  GiftDigitalCardGiftSection(), //Starbucks Digital Cardセクション
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
