import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:vector_graphics/vector_graphics_compat.dart';

import '../../../constants/my_colors.dart';
import '../../../constants/svg_png_path.dart';
import '../../../shared/widgets/headers/fixed_header.dart';
import '../../../shared/widgets/texts/my_custom_text.dart';
import '../../../shared/widgets/wrap_sliver_to_box_adapter.dart';

///eチケット店内利用用表示画面
class ETicketUseInStore extends StatelessWidget {
  const ETicketUseInStore({super.key});
  static String routeName = 'starbucks_eticket_available_use_in_store';

  @override
  Widget build(BuildContext context) {
    return FixedHeaderCommonComponent(
      isLeadingIcon: true,
      icon: Icon(Icons.close),
      //TODO:チケットに応じて動的にできるように、extra?の設定
      headerText: 'Coffee More One 会員 | Tall',
      isFab: false,
      onIconPressed: () {
        // トップ画面へ戻る
        context.pop(context);
      },
      body: _ScrollContents(),
    );
  }
}

class _ScrollContents extends StatelessWidget {
  const _ScrollContents();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: const <Widget>[
        _OrderCardWithQr(),
        WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider)),
        _ExtensionTileTicketDescription(), //チケット内容
        WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider)),
        _ExtensionTileAvailCondtion(), //ご利用条件
        WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider)),
        TicketExtensionTile(), //ご利用方法（店舗）
        WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider)),
        TicketExtensionTile(), //ご利用の注意
        WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider)),
        WrapSliverToBoxAdapter(body: SizedBox(height: 30)),
        WrapSliverToBoxAdapter(body: Divider(color: MyColors.horizontalDivider)),
      ],
    );
  }
}

/// チケット内容
class _ExtensionTileTicketDescription extends StatelessWidget {
  const _ExtensionTileTicketDescription();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const MyCustomText(text: 'チケット内容', fontSize: 16, fontWeight: FontWeight.bold),
          textColor: Colors.black,
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: .start,
                spacing: 10,
                children: [
                  MyCustomText(
                    text:
                        '・トールサイズまでのご提供\n・モバイルオーダーまたは店頭でご利用可\n・モバイルオーダーでドリップコーヒーまたはカフェミストをご購入いただいた当日の営業時間終了まで有効',
                    softwrap: true,
                  ),
                  MyCustomText(text: 'チケット名：One More Coffee 会員 | Tall', softwrap: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ご利用条件
class _ExtensionTileAvailCondtion extends StatelessWidget {
  const _ExtensionTileAvailCondtion();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const MyCustomText(text: 'ご利用条件', fontSize: 16, fontWeight: FontWeight.bold),
          textColor: Colors.black,
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                spacing: 5,
                children: [
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.20,
                        child: const MyCustomText(text: '対象商品', softwrap: true),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.60,
                        child: const MyCustomText(
                          text: 'Coffee More One(2杯目のコーヒー)またはカフェオレ\n※ホット/アイスは選択可能です',
                          softwrap: true,
                        ),
                      ),
                    ],
                  ),
                  _RowDividerAvailCondtionSection(), // 区切り線
                  Row(
                    crossAxisAlignment: .start,
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.20,
                        child: const MyCustomText(text: '対象商品', softwrap: true),
                      ),
                      const MyCustomText(
                        text: 'yyyy年M月dd日(e)',
                        fontWeight: FontWeight.bold,
                        softwrap: true,
                      ),
                    ],
                  ),

                  _RowDividerAvailCondtionSection(), // 区切り線
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.20,
                        child: const MyCustomText(text: '対象店舗', softwrap: true),
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.60,
                        child: Column(
                          crossAxisAlignment: .start,
                          children: const [
                            MyCustomText(text: '日本国内の店舗\n※一部対象外店舗あるよ～', softwrap: true),
                            MyCustomText(text: '店舗検索へ', softwrap: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// チケット内容のアコーディオン
class TicketExtensionTile extends StatelessWidget {
  const TicketExtensionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const MyCustomText(text: 'チケット内容', fontSize: 16, fontWeight: FontWeight.bold),
          textColor: Colors.black,
          iconColor: Colors.black,
          collapsedIconColor: Colors.black,
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: .start,
                spacing: 10,
                children: [
                  MyCustomText(
                    text:
                        '・トールサイズまでのご提供\n・モバイルオーダーまたは店頭でご利用可\n・モバイルオーダーでドリップコーヒーまたはカフェミストをご購入いただいた当日の営業時間終了まで有効',
                    softwrap: true,
                  ),
                  MyCustomText(text: 'チケット名：One More Coffee 会員 | Tall', softwrap: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///QR表示
class _OrderCardWithQr extends StatelessWidget {
  const _OrderCardWithQr();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          color: Color(0xFFE6E6E6),
          child: Card(
            elevation: 2,
            color: Colors.white,
            clipBehavior: Clip.antiAliasWithSaveLayer, //SVGをCardの淵に合わせる
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                VectorGraphic(
                  fit: BoxFit.cover,
                  width: MediaQuery.sizeOf(context).width,
                  loader: const AssetBytesLoader(SvgPngPath.oneMoreCoffeeSvg),
                ),
                VectorGraphic(
                  fit: BoxFit.cover,
                  width: MediaQuery.sizeOf(context).width * 0.85,
                  loader: const AssetBytesLoader(SvgPngPath.eTicketDotsSvg),
                ),
                Padding(
                  padding: const .all(20),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.4,
                            child: const MyCustomText(
                              text:
                                  '2杯目のコーヒーを128円/130円(持ち帰り価格/店内価格)または、ミストを182円/185円(持ち帰り価格/店内価格)で楽しめます',
                              softwrap: true,
                            ),
                          ),
                          const Spacer(),
                          // QR
                          const _DisplayQr(),
                        ],
                      ),
                      const MyCustomText(text: '詳細はこちら'),
                      const SizedBox(height: 15),
                      const Column(
                        crossAxisAlignment: .start,
                        children: [
                          MyCustomText(text: '利用期間'),
                          MyCustomText(text: '2025年2月11日(火)'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowDividerAvailCondtionSection extends StatelessWidget {
  const _RowDividerAvailCondtionSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        SizedBox(width: MediaQuery.sizeOf(context).width * 0.20),
        SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.60,
          child: Divider(color: MyColors.horizontalDivider),
        ),
      ],
    );
  }
}

class _DisplayQr extends StatelessWidget {
  const _DisplayQr();

  @override
  Widget build(BuildContext context) {
    final qrData = DateTime.now().toString();
    return Column(
      children: [
        QrImageView(key: ValueKey('one_more_coffee_qr'), data: qrData, size: 125),
        // MyCustomText(text: 'コード番号を表示', fontSize: 12, textColor: MyColors.greenText),
      ],
    );
  }
}
