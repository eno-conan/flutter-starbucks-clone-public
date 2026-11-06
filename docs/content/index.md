# Starbucks Clone - 開発ドキュメント

Starbucks 公式アプリを模倣した Flutter アプリの開発ドキュメントです。

## 技術スタック

| カテゴリ | 技術 |
|---|---|
| UI フレームワーク | Flutter 3.x / Dart |
| 状態管理 | Riverpod 3.0 (Notifier API) |
| ルーティング | go_router |
| バックエンド | Supabase（認証・DB・ストレージ） |
| 地図 | Google Maps Flutter |
| 分析・通知 | Firebase（Crashlytics・Push 通知） |
| DI | get_it |

## ドキュメント一覧

### セットアップ・開発・運用

開発環境のセットアップ、テスト手順、各種サービス連携、CI/CD とリリースの設定方法。

- [開発環境セットアップ](setup/setup.md)
- [開発環境情報](setup/dev-setup.md)
- [テスト](development/testing.md)
- [Flutterパフォーマンス最適化ガイド](development/performance.md)
- [Supabase](services/supabase.md)
- [Firebase](services/firebase.md)
- [CI/CD](release/cicd.md)

### Claude Code

Claude Code を使った開発ワークフローとガイドライン。

- [ワークフロー](claude/workflow.md)
- [品質チェックリスト](claude/quality-checklist.md)
- [スラッシュコマンドガイド](claude/slash-commands-guide.md)
- [OpenShell（サンドボックスで Claude Code を動かす）](claude/openshell.md)

### アーキテクチャ

プロジェクト構成・Provider 一覧・実装パターン。

- [技術スタック概要](architecture/MEMORY.md)
- [アーキテクチャ詳細](architecture/architecture.md)
- [実装パターン](architecture/patterns.md)

### セキュリティ

コード解析・Google Cloud の設定・OWASP Mobile Top 10 対応・Android セキュリティ検証。

- [セキュリティ・コード解析](security/overview.md)
- [Google Cloud セキュリティ](security/google-cloud.md)
- [Android セキュリティ検証コマンド](security/android-verify.md)
- [OWASP Mobile Top 10 概要](security/owasp-mobile-top-10/README.md)
