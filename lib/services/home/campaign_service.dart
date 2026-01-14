import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/supabase_tables.dart';

/// キャンペーン管理サービス
class CampaignService {
  const CampaignService();

  SupabaseClient get supabase => Supabase.instance.client;

  /// 指定したキャンペーンがアクティブかどうかを確認
  Future<bool> isCampaignActive(String campaignName) async {
    try {
      final response = await supabase
          .from(Tables.campaignSettings)
          .select('start_date, end_date, is_active')
          .eq('campaign_name', campaignName)
          .eq('is_active', true) // アクティブなもののみ
          .maybeSingle(); // 0件または1件を想定

      if (response == null) {
        return false;
      }

      final now = DateTime.now();
      final startDate = DateTime.parse(response['start_date'] as String);
      final endDate = DateTime.parse(response['end_date'] as String);

      return now.isAfter(startDate) && now.isBefore(endDate);
    } catch (e) {
      // LoggerService.warn('Campaign check error: $e');
      return false; // エラー時は非表示
    }
  }
}
