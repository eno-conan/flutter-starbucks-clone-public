import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../star_reward_exchange/main.dart';
import '../main.dart';

///メッセージエリア
class ETicketTabAvailableTicketsMsgareaExchangeEticket extends StatelessWidget {
  const ETicketTabAvailableTicketsMsgareaExchangeEticket({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      key: const ValueKey('eticket-available-message'),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.06,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        color: Color(0xFF1E3932),
        child: Row(
          children: [
            const MyCustomText(text: 'eTicketに交換できるStarがあります。', textColor: Colors.white),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
              ),
              onPressed: () {
                context.push('${ETicket.routeName}/${ExchangeStarReward.routeName}');
                // final fullPath = RouteFinder.getFullPath(
                //   ExchangeStarReward.routeName,
                // );
                // context.push(fullPath.join());
              },
              child: const MyCustomText(
                text: '交換する',
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                textColor: Color(0xFF4F645F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
