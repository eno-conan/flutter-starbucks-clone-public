import 'package:flutter/material.dart';

/// Sliverではないコンテンツをラッピング
class WrapSliverToBoxAdapter extends StatelessWidget {
  const WrapSliverToBoxAdapter({super.key, required this.body});
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: body);
  }
}
