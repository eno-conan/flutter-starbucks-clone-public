import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../constants/my_colors.dart';
import '../../../../core/models/user_ticket.dart';
import '../../../../provider/e_ticket_provider.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';
import '../../star_reward_exchange/main.dart';
import '../e_ticket_available_tab_no_available_message.dart';
import '../main.dart';
import 'tab_available_tickets_msgarea_exchange_eticket.dart';

/// 利用可能なeチケットタブ
class ETicketTabAvailableTickets extends ConsumerWidget {
  const ETicketTabAvailableTickets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(availableTicketsProvider);

    return CustomScrollView(
      slivers: [
        const ETicketTabAvailableTicketsMsgareaExchangeEticket(),
        // チケットリスト
        ticketsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            sliver: SliverToBoxAdapter(
              child: NoAvaiableETicketMessage(
                widgetKey: 'eticket-available-error',
                subMessage: 'チケットの読み込みに失敗しました',
              ),
            ),
          ),
          data: (tickets) {
            if (tickets.isEmpty) {
              return const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                sliver: SliverToBoxAdapter(
                  child: NoAvaiableETicketMessage(
                    widgetKey: 'eticket-available-tab-no-available-message',
                    subMessage: '現在ご利用可能なチケットはありません。',
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ticket = tickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: AvailableTicketCard(ticket: ticket),
                    );
                  },
                  childCount: tickets.length,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 利用可能チケットカード
class AvailableTicketCard extends StatelessWidget {
  const AvailableTicketCard({super.key, required this.ticket});

  final AvailableTicket ticket;

  /// デフォルトのチケット画像URL（image_urlがnullの場合に使用）
  static const String _defaultTicketImage =
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&auto=format&fit=crop';

  @override
  Widget build(BuildContext context) {
    // 画像URLの決定（nullの場合はデフォルト画像を使用）
    final imageUrl =
        (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty) ? ticket.imageUrl! : _defaultTicketImage;

    // 有効期限のフォーマット（yy/MM/dd形式）
    final formattedExpiry = DateFormat('yy/MM/dd').format(ticket.expiredAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // チケット画像
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 画像読み込みエラー時はデフォルト画像を表示
              return Image.network(
                _defaultTicketImage,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // チケット名
        MyCustomText(
          text: ticket.ticketName,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 5),
        // 有効期限
        MyCustomText(
          text: '利用期限 $formattedExpiry',
          fontSize: 14,
          textColor: Colors.grey[600],
        ),
        const SizedBox(height: 10),
        // 店舗で使うボタン
        InkWell(
          onTap: () {
            context.go('/home/tab1/${ETicket.routeName}/${ExchangeStarReward.routeName}');
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: MyColors.greenButton,
            ),
            height: 35,
            width: 100,
            child: const MyCustomText(
              text: '店舗で使う',
              textColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 7.5),
        // モバイルオーダーで使うボタン
        InkWell(
          onTap: () {
            // TODO: モバイルオーダーでの使用処理
          },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: Colors.white,
              border: Border.all(width: 0.5, color: MyColors.greenButton),
            ),
            height: 35,
            width: 175,
            child: const MyCustomText(
              text: 'モバイルオーダーで使う',
              textColor: MyColors.greenButton,
            ),
          ),
        ),
      ],
    );
  }
}
