import 'package:flutter/material.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

const Color grey500 = Color(0xFF9E9E9E);

///Section:eチケットセクション
class HomeETicketSection extends StatelessWidget {
  const HomeETicketSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Container(
        decoration: BoxDecoration(color: Colors.black87),
        child: InkWell(
          splashColor: Color(0x30f010f0),
          onTap: () => {},
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // タイトルテキスト
                    MyCustomText(
                      text: 'MOBILE ORDER & PAY',
                      textColor: grey500,
                      useEnglishFont: true,
                    ),
                    SizedBox(height: 12.0),
                    // 日本語テキスト
                    MyCustomText(text: 'レジに並ばず、\nお店で受け取り', textColor: Colors.white, fontSize: 20.0),
                    SizedBox(height: 36.0),
                    _OrderElevatedButton(),
                  ],
                ),
                _MobileOrderImage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 画像
class _MobileOrderImage extends StatelessWidget {
  const _MobileOrderImage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [Image.asset('assets/starbucks/png/mobile_order.png', height: 160)],
    );
  }
}

/// オーダーボタン
class _OrderElevatedButton extends StatelessWidget {
  const _OrderElevatedButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
      ),
      child: MyCustomText(text: 'オーダーする', fontSize: 16.0, fontWeight: FontWeight.w500),
    );
  }
}
