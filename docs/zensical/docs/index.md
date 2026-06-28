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

### プロジェクト

開発環境のセットアップ、テスト手順、CI/CD、各種サービス連携の設定方法。

- [開発環境情報](project/dev-setup.md)
- [テスト](project/testing.md)
- [CI/CD](project/cicd.md)
- [Supabase](project/supabase.md)
- [Firebase](project/firebase.md)
- [セキュリティ](project/security.md)

### Claude Code

Claude Code を使った開発ワークフローとガイドライン。

- [ワークフロー](claude/workflow.md)
- [品質チェックリスト](claude/quality-checklist.md)
- [スラッシュコマンドガイド](claude/slash-commands-guide.md)

### アーキテクチャ

プロジェクト構成・Provider 一覧・実装パターン。

- [技術スタック概要](architecture/MEMORY.md)
- [アーキテクチャ詳細](architecture/architecture.md)
- [実装パターン](architecture/patterns.md)

### セキュリティ

OWASP Mobile Top 10 対応と Android セキュリティ検証。

- [Android セキュリティ検証コマンド](security/android_verify_security_commands.md)
- [OWASP Mobile Top 10 概要](security/owasp-mobile-top-10/README.md)
