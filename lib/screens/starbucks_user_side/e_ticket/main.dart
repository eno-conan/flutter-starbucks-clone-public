import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../provider/auth_state_provider.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/splash_screen.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'widgets/tab_controller.dart';

//未ログイン時の表示
const String _eticketCoffeeCupSvgPath = 'assets/starbucks/svg/eticket_coffee_cup.svg';

///eチケット
class ETicket extends ConsumerWidget {
  const ETicket({super.key});
  static String routeName = '/starbucks_eticket_top';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    return authAsync.when(
      loading: () => const SliverToBoxAdapter(child: SplashScreen()),
      error: (error, _) => SliverToBoxAdapter(child: ErrorScreen(error: error.toString())),
      data: (user) => user != null
          ? const ETicketLoginedContents()
          : FixedHeaderCommonComponent(
              isLeadingIcon: true,
              headerText: 'eticket',
              isFab: false,
              onIconPressed: () {
                // トップ画面へ戻る
                context.pop(context);
              },
              body: _EticketNotLoginedContents(),
            ),
    );
  }
}

class _EticketNotLoginedContents extends StatelessWidget {
  const _EticketNotLoginedContents();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        spacing: 30,
        children: [
          const SizedBox(height: 5),
          VectorGraphic(
            loader: AssetBytesLoader(_eticketCoffeeCupSvgPath),
            // fit: BoxFit.cover,
            width: MediaQuery.sizeOf(context).width * 0.30,
            // width: 150,
          ),
          Column(
            crossAxisAlignment: .start,
            spacing: 20,
            children: const [
              MyCustomText(text: 'ログインが必要です', fontSize: 18),
              MyCustomText(
                text: 'ログインすると受け取ったeTicketを表示することができます',
                textColor: Color(0xFFA4A4A4),
                fontSize: 16,
                softwrap: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
