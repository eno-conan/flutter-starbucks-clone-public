import 'package:flutter/material.dart';

import '../../../../../core/models/product_detail.dart';
import '../../../../../provider/mobile_order_selected_product_id_provider.dart';
import '../../../../../shared/widgets/texts/my_custom_text.dart';
import 'common_widgets.dart';

/// Widget for displaying product image and name
class ProductImageAndName extends StatelessWidget {
  const ProductImageAndName({super.key, required this.selectedProduct, required this.product});

  final SelectedProduct selectedProduct;
  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return PaddingContents(
      body: Row(
        spacing: 20,
        crossAxisAlignment: .start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              selectedProduct.imageUrl,
              height: 125,
              width: 125,
              cacheWidth: 200,
              filterQuality: FilterQuality.low,
              fit: BoxFit.cover, // 画像が角丸に合うように調整
            ),
          ),
          MyCustomText(text: product.name, fontSize: 18),
        ],
      ),
    );
  }
}
