import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

///利用済みeチケットの詳細（Thank you!とか書いてある）
class UsedETicketsDetail extends StatelessWidget {
  const UsedETicketsDetail({super.key});
  static String routeName = '/starbucks_eticket_used_detail';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: true,
      icon: Icon(Icons.close),
      //TODO:チケットに応じて動的にできるように、extra?の設定
      headerText: 'スターリワードフード eTicket 300',
      isFab: false,
      onIconPressed: () {
        // トップ画面へ戻る
        context.pop(context);
      },
      body: _Contents(),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        MyCustomText(text: 'Thank you!', fontSize: 20),
        MyCustomText(text: 'ご利用ありがとうございました。', fontSize: 12),
      ],
    );
  }
}
