import 'package:flutter/material.dart';
import '../../../../shared/widgets/texts/my_custom_text.dart';

///有効期限に関するダイアログ表示のアイコン
class RewardsIconDialogExpiration extends StatelessWidget {
  const RewardsIconDialogExpiration({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showStarExpirationModal(context);
      },
      child: Icon(Icons.info_outline),
    );
  }
}

/// 有効期限表示のモーダル
void _showStarExpirationModal(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16), // デフォルトの40から縮小
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: .start,
            children: [
              const SizedBox(height: 4),
              const MyCustomText(
                text: '保有Starの有効期限について',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 16),
              const MyCustomText(
                text: 'ためた個々の保有Starの有効期限は、付与から1年後の翌月1日までです。',
                fontSize: 14,
                softwrap: true,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const .all(16),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text('例）'),
                    SizedBox(height: 8),
                    Text('2022年6月29日に付与'),
                    MyCustomText(text: '▼', textColor: Colors.grey),
                    Text('2023年7月1日まで有効'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('スターリワードへの交換の際は、最も期限の近いStarから交換されます。', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: .end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.white,
                        border: Border.all(),
                      ),
                      height: 35,
                      width: 80,
                      child: const MyCustomText(
                        text: '閉じる',
                        // fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
