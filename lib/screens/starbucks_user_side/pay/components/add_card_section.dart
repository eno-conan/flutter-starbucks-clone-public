import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

///カード追加イラストのパス
const String addCardSvgPath = 'assets/starbucks/svg/add_card.svg';

/// カード追加イラストエリア
class PayAreaAddCard extends StatelessWidget {
  const PayAreaAddCard({super.key});

  @override
  Widget build(BuildContext context) {
    final double svgWidth = MediaQuery.sizeOf(context).width * 0.4;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: VectorGraphic(loader: const AssetBytesLoader(addCardSvgPath), width: svgWidth),
            ),
          ],
        ),
      ),
    );
  }
}
