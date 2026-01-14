import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/my_colors.dart';
import '../../../../provider/e_ticket_provider.dart';
import '../../e_ticket/main.dart';
import '../../inbox/main.dart';
import '../../setting/main.dart';

///Section:ナビゲーション
class HomeNavigationSection extends StatelessWidget {
  const HomeNavigationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      child: Container(
        key: ValueKey('top_page_navigation_section'),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
        ),
        child: const Row(
          key: ValueKey('top_page_navigation_section_row'),
          children: [
            IconTextGoETicketScreen(),
            IconTextGoInboxScreen(),
            Spacer(),
            InkwellIconGoSettingPage(),
          ],
        ),
      ),
    );
  }
}

/// eチケット画面へ遷移するアイコンテキスト
class IconTextGoETicketScreen extends ConsumerWidget {
  const IconTextGoETicketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 利用可能なチケット枚数を取得
    final ticketCount = ref.watch(availableTicketCountProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (context.mounted) {
              context.push(ETicket.routeName);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // チケットアイコンとバッジ
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    // チケット枚数バッジ
                    if (ticketCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: MyColors.greenButton,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          ticketCount.toString(),
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      // チケットが0枚の場合は輪郭のみ表示
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          border: Border.all(width: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '0',
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text('eTicket'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inbox画面へ遷移するアイコンテキスト
class IconTextGoInboxScreen extends StatelessWidget {
  const IconTextGoInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: () {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (context.mounted) {
              context.push(InboxTopPage.routeName);
            }
          });
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.mail, color: Colors.green),
              SizedBox(width: 8),
              Text('Inbox'),
            ],
          ),
        ),
      ),
    );
  }
}

class InkwellIconGoSettingPage extends StatelessWidget {
  const InkwellIconGoSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () {
          context.push(Setting.routeName);
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Icon(Icons.settings_outlined, color: Colors.black),
        ),
      ),
    );
  }
}
