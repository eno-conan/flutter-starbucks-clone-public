import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/models/user_ticket.dart';
import '../../../provider/e_ticket_provider.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'e_ticket_available_tab_no_available_message.dart';

/// 利用済のeチケット（14日以内）
class UsedETicketsTab extends ConsumerWidget {
  const UsedETicketsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(usedTicketsProvider);

    return CustomScrollView(
      slivers: [
        // チケットリスト
        ticketsAsync.when(
          loading: () => const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => const SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: NoAvaiableETicketMessage(
                widgetKey: 'eticket-used-error',
                subMessage: 'チケットの読み込みに失敗しました',
              ),
            ),
          ),
          data: (tickets) {
            if (tickets.isEmpty) {
              return const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                sliver: SliverToBoxAdapter(
                  child: NoAvaiableETicketMessage(
                    widgetKey: 'eticket-used-tab-no-tickets',
                    subMessage: '利用済みチケットはありません。',
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ticket = tickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: UsedTicketCard(ticket: ticket),
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

/// 利用済みチケットカード
class UsedTicketCard extends StatelessWidget {
  const UsedTicketCard({super.key, required this.ticket});

  final UsedTicket ticket;

  /// デフォルトのチケット画像URL（image_urlがnullの場合に使用）
  static const String _defaultTicketImage =
      'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&auto=format&fit=crop';

  @override
  Widget build(BuildContext context) {
    // 画像URLの決定（nullの場合はデフォルト画像を使用）
    final imageUrl =
        (ticket.imageUrl != null && ticket.imageUrl!.isNotEmpty) ? ticket.imageUrl! : _defaultTicketImage;

    // 使用日時のフォーマット（yy/MM/dd形式）
    final formattedUsedAt = DateFormat('yy/MM/dd').format(ticket.usedAt);

    return Opacity(
      opacity: 0.6, // グレーアウト効果
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // チケット画像と「利用済み」バッジ
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.grey.withOpacity(0.5),
                    BlendMode.saturation,
                  ),
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
              ),
              // 「利用済み」バッジ
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const MyCustomText(
                    text: '利用済み',
                    textColor: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // チケット名
          MyCustomText(
            text: ticket.ticketName,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            textColor: Colors.grey[700],
          ),
          const SizedBox(height: 5),
          // 使用日時
          MyCustomText(
            text: '使用日 $formattedUsedAt',
            fontSize: 14,
            textColor: Colors.grey[600],
          ),
        ],
      ),
    );
  }
}
