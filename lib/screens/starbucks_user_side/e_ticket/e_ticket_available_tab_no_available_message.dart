import 'package:flutter/material.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';

/// 利用可能なチケットがない場合のメッセージ表示
class NoAvaiableETicketMessage extends StatelessWidget {
  const NoAvaiableETicketMessage({super.key, required this.widgetKey, required this.subMessage});
  final String widgetKey;
  final String subMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 5,
      children: [
        const MyCustomText(text: 'チケットはありません', fontSize: 18),
        MyCustomText(text: subMessage, textColor: Color(0xFF8B8B8B)),
      ],
    );
  }
}
