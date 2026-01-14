// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../app/menu.dart';
import '../../../constants/my_colors.dart';
import '../../../core/services/logger_service.dart';
import '../../../provider/auth_state_provider.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/error_screen.dart';
import '../../../shared/widgets/indicators/circular_progress_indicator.dart';
import '../../../shared/widgets/splash_screen.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import 'switch_notify_setting/main.dart';

/// 設定画面
class Setting extends ConsumerWidget {
  const Setting({super.key});
  static String routeName = '/starbucks_setting_page';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 認証状態の監視を開始
    ref.watch(authStateProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        // Home画面に戻る
        context.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          scrolledUnderElevation: 0, //背景色が灰色になるのを防ぐオプション
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(context),
          ),
        ),
        body: SafeArea(child: _CustomScrollView()),
      ),
    );
  }
}

class _CustomScrollView extends StatelessWidget {
  const _CustomScrollView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: const <Widget>[_SliverAppBar(), _Contents()]);
  }
}

class _Contents extends ConsumerWidget {
  const _Contents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      sliver: authAsync.when(
        loading: () => const SliverToBoxAdapter(child: SplashScreen()),
        error: (error, _) => SliverToBoxAdapter(child: ErrorScreen(error: error.toString())),
        data: (user) {
          final userEmail = user?.email;
          return userEmail != null
              ? SliverList(
                  delegate: SliverChildListDelegate([
                    const _SectionTile(sectionLabel: 'ログインアカウント'),
                    _MailAddressTile(text: userEmail),
                    const _SectionTile(sectionLabel: '会員情報について'),
                    const _BuildEachListTile(text: '会員情報変更'),
                    const _BuildEachListTile(text: '支払い方法'),
                    const _BuildEachListTile(text: '退会'),
                    const _BuildEachListTile(text: '会員専用Wi-Fi設定'),
                    const _SectionTile(sectionLabel: 'アプリについて'),
                    const _BuildEachListTile(text: 'ご利用ガイド'),
                    _BuildEachListTile(
                      text: '通知設定',
                      onTap: () {
                        // 通知設定切り替え画面へ
                        context.push('/home/a/${SwitchNotifySetting.routeName}');
                      },
                    ),
                    const _BuildEachListTile(text: 'ヘルプ'),
                    const _BuildEachListTile(text: '利用規約'),
                    const _BuildEachListTile(text: 'プライバシーポリシー'),
                    const _BuildEachListTile(text: 'ライセンス'),
                    _ButtonLogOut(),
                  ]),
                )
              : SliverList(
                  delegate: SliverChildListDelegate([
                    const _SectionTile(sectionLabel: 'アプリについて'),
                    const _BuildEachListTile(text: 'ご利用ガイド'),
                    const _BuildEachListTile(text: '通知設定'),
                    const _BuildEachListTile(text: 'ヘルプ'),
                    const _BuildEachListTile(text: '利用規約'),
                    const _BuildEachListTile(text: 'プライバシーポリシー'),
                    const _BuildEachListTile(text: 'ライセンス'),
                  ]),
                );
        },
      ),
    );
  }
}

// ログアウト処理
Future<void> _logOut(BuildContext context) async {
  final authService = GetIt.instance<AuthService>();
  final user = await authService.retrieveLoginUser();
  if (user != '') {
    if (kDebugMode) {
      LoggerService.info('ログアウト処理開始');
    }
    await authService.signOutWithGoogle();
  }
}

class _ButtonLogOut extends StatelessWidget {
  const _ButtonLogOut();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.30,
            height: MediaQuery.sizeOf(context).height * 0.05,
            child: OutlinedButton(
              onPressed: () async {
                try {
                  showCircularProgressIndicator(context);
                  _logOut(context);
                  context.go(MenuPage.routeName);
                  _showSnackBar(context, 'サインアウトしました。');
                } catch (e) {
                  context.pop();
                  _showSnackBar(context, 'サインアウトに失敗しました。');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.greenButton,
                backgroundColor: Colors.white,
                side: const BorderSide(color: MyColors.greenButton),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              ),
              child: const MyCustomText(
                text: 'ログアウト',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                textColor: MyColors.greenButton,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

///各セクション
class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.sectionLabel});
  final String sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: MyCustomText(
              text: sectionLabel,
              fontWeight: FontWeight.bold,
              textColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

///メールアドレス用の表示
class _MailAddressTile extends StatefulWidget {
  const _MailAddressTile({required this.text});
  final String text;

  @override
  State<_MailAddressTile> createState() => _MailAddressTileState();
}

class _MailAddressTileState extends State<_MailAddressTile> {
  bool isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        Container(
          alignment: Alignment.center,
          height: MediaQuery.sizeOf(context).height * 0.12,
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: MyColors.settingDivider, // 枠線の色
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                MyCustomText(
                  text: isVisible ? widget.text : maskingEmail(widget.text),
                  fontSize: isVisible ? 16 : 14,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isVisible = !isVisible;
                    });
                  },
                  child: isVisible
                      ? Icon(Icons.visibility_outlined)
                      : Icon(Icons.visibility_off_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Emailのマスキング
String maskingEmail(String email) {
  return email.replaceAll(RegExp(r'.(?=[^@]*@)'), '●');
}

///各メニュー
class _BuildEachListTile extends StatelessWidget {
  const _BuildEachListTile({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .center,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            height: MediaQuery.sizeOf(context).height * 0.08,
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: MyColors.settingDivider, // 枠線の色
                  width: 0.5,
                ),
              ),
            ),
            child: ListTile(
              title: MyCustomText(text: text, fontWeight: FontWeight.bold, fontSize: 16),
              trailing: const Icon(Icons.arrow_forward_ios),
            ),
          ),
        ),
      ],
    );
  }
}

/// AppBar
class _SliverAppBar extends StatelessWidget {
  const _SliverAppBar();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      automaticallyImplyLeading: false,
      expandedHeight: 70,
      flexibleSpace: Container(
        padding: EdgeInsets.only(bottom: 10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          // 微細な影を付与
          boxShadow: const [
            BoxShadow(color: MyColors.boxShadow, offset: Offset(0, 2), blurRadius: 4),
          ],
          // 下部の境界線
          border: const Border(bottom: BorderSide(color: Color.fromRGBO(0, 0, 0, 0.08))),
        ),
        child: const Row(
          children: [
            SizedBox(width: 10),
            MyCustomText(text: '設定', fontSize: 28),
          ],
        ),
      ),
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
}
