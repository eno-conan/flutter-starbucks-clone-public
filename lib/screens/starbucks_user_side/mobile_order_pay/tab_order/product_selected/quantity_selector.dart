import 'package:flutter/material.dart';
import 'common_widgets.dart';

/// Widget for quantity selection
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.count,
    required this.minusCount,
    required this.plusCount,
  });

  final int count;
  final VoidCallback minusCount;
  final VoidCallback plusCount;

  @override
  Widget build(BuildContext context) {
    return PaddingContents(
      body: CountSelector(count: count, minusCount: minusCount, plusCount: plusCount),
    );
  }
}
