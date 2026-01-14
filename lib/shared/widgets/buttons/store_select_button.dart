import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants/my_colors.dart';
import '../../../core/models/store_mobile_order.dart';
import '../../../data/repository/store.dart';
import '../../../provider/mobile_order_selected_store_provider.dart';
import '../../../services/mobile_order_pay/store/store_availability_service.dart';
import '../texts/my_custom_text.dart';

/// 店舗選択ボタンウィジェット
///
/// 営業時間外の場合は非活性化し、エラーメッセージを表示する
class StoreSelectButton extends ConsumerStatefulWidget {
  const StoreSelectButton({super.key, required this.store, required this.onPressed, this.distance});

  final StoreMobileOrder store;
  final VoidCallback onPressed;
  final String? distance;

  @override
  ConsumerState<StoreSelectButton> createState() => _StoreSelectButtonState();
}

class _StoreSelectButtonState extends ConsumerState<StoreSelectButton> {
  late final StoreAvailabilityService _availabilityService;
  bool _isAvailable = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final storeRepository = StoreRepository(Supabase.instance.client);
    _availabilityService = StoreAvailabilityService(storeRepository);
    _checkStoreAvailability();
  }

  Future<void> _checkStoreAvailability() async {
    try {
      final isAvailable = await _availabilityService.isStoreAvailable(widget.store.storeNumber);
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAvailable = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 現在選択されている店舗を取得
    final selectedStore = ref.watch(selectedStoreProvider);
    final isSelected = selectedStore?.storeNumber == widget.store.storeNumber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // エラーメッセージ（営業時間外の場合）
        if (!_isLoading && !_isAvailable)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: MyCustomText(
              text: '受付時間外のため、選択できません。',
              fontSize: 12,
              textColor: MyColors.errorMessageText,
            ),
          ),

        // ボタンと距離表示の行
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton(
              onPressed: _isLoading
                  ? null
                  : _isAvailable
                  ? widget.onPressed
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _isLoading
                    ? Colors.grey[300]
                    : !_isAvailable
                    ? Colors.grey[600] // 営業時間外は濃いめの灰色
                    : isSelected
                    ? Colors.grey
                    : MyColors.greenButton,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                minimumSize: const Size(0, 35),
                splashFactory: InkSplash.splashFactory,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    )
                  : MyCustomText(text: isSelected ? '選択中' : '選択する', textColor: Colors.white),
            ),

            // 距離表示（提供されている場合）
            if (widget.distance != null)
              MyCustomText(text: widget.distance!, textColor: Colors.black54, fontSize: 12),
          ],
        ),
      ],
    );
  }
}
