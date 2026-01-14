import 'package:flutter/material.dart';

import '../../../../../core/models/product_detail.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import 'common_widgets.dart';

/// Widget for size selection
class SizeSelector extends StatelessWidget {
  const SizeSelector({
    super.key,
    required this.product,
    required this.selectedIndex,
    required this.onSelected,
  });

  final ProductDetail product;
  final int selectedIndex;
  final void Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    return PaddingContents(
      body: Column(
        crossAxisAlignment: .start,
        children: [
          const MyCustomText(
            text: 'SIZE',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            useEnglishFont: true,
          ),
          const SizedBox(height: 10),
          CustomSelector(
            items: product.sizeList,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ],
      ),
    );
  }
}
