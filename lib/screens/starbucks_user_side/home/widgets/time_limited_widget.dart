import 'package:flutter/material.dart';
import '../../../../services/home/campaign_service.dart';

/// 期間限定表示ウィジェット
/// Star Dashなどのキャンペーンコンテンツを期間限定で表示する
class TimeLimitedWidget extends StatelessWidget {
  const TimeLimitedWidget({super.key});

  CampaignService get _campaignService => const CampaignService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _campaignService.isCampaignActive('september_campaign_2025'),
      builder: (context, snapshot) {
        // ローディング中やエラー時は非表示
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final isActive = snapshot.data ?? false;
        return isActive ? const _StarDashDisplay() : const SizedBox.shrink();
      },
    );
  }
}

// Star Dash表示コンテンツ（プライベート）
class _StarDashDisplay extends StatelessWidget {
  const _StarDashDisplay();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Star Dash',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('期間限定のスターダッシュキャンペーン開催中！', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
