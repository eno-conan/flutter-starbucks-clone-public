import 'package:flutter/material.dart';

/// ペーパーバッグ利用のチェックボックス
class CheckBoxPaperBag extends StatelessWidget {
  const CheckBoxPaperBag({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Text('ペーパーバッグを利用する'),
      ),
    );
  }
}
