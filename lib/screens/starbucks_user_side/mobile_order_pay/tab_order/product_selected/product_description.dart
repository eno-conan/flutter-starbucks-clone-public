import 'package:flutter/material.dart';

import '../../../../../core/models/product_detail.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import 'common_widgets.dart';

/// Widget for displaying product description
class ProductDescription extends StatelessWidget {
  const ProductDescription({super.key, required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return PaddingContents(
      body: MyCustomText(
        text: product.description,
        fontSize: 12,
        textColor: Colors.grey,
        softwrap: true,
      ),
    );
  }
}
