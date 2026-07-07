-- Issue#544: データアーカイブ戦略 - pg_cronスケジュール設定
--
-- 前提: Supabase Dashboard > Database > Extensions で pg_cron が有効なこと
-- 適用方法: Supabase Dashboard > SQL Editor でこのスクリプトを実行する
--
-- タイムゾーン: pg_cron は UTC で動作する
--   - 毎月1日 AM3:00 JST = 前月末 UTC 18:00
--   - 毎週月曜 AM3:00 JST = 日曜 UTC 18:00

-- ----------------------------------------------------------------
-- 既存のジョブを削除（冪等性のため再実行可能）
-- ----------------------------------------------------------------
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname IN (
    'archive-old-orders',
    'archive-old-star-usage',
    'cleanup-expired-tickets',
    'cleanup-abandoned-carts'
);

-- ----------------------------------------------------------------
-- 注文データのアーカイブ (毎月1日 18:00 UTC = 翌2日 3:00 JST)
-- 対象: orders / orders_detail / star_acquisitions の18ヶ月超過データ
-- ----------------------------------------------------------------
SELECT cron.schedule(
    'archive-old-orders',
    '0 18 1 * *',
    $$SELECT public.archive_old_orders(18)$$
);

-- ----------------------------------------------------------------
-- スター使用履歴のアーカイブ (毎月1日 18:05 UTC)
-- orders アーカイブ完了後に5分ずらして実行
-- ----------------------------------------------------------------
SELECT cron.schedule(
    'archive-old-star-usage',
    '5 18 1 * *',
    $$SELECT public.archive_old_star_usage(18)$$
);

-- ----------------------------------------------------------------
-- 期限切れチケットの削除 (毎月1日 18:10 UTC)
-- 有効期限から3ヶ月以上経過した user_tickets を削除
-- ----------------------------------------------------------------
SELECT cron.schedule(
    'cleanup-expired-tickets',
    '10 18 1 * *',
    $$SELECT public.cleanup_expired_user_tickets(3)$$
);

-- ----------------------------------------------------------------
-- 放棄カートの削除 (毎週日曜 18:00 UTC = 月曜 3:00 JST)
-- 最終更新から30日以上経過した carts / carts_detail を削除
-- ----------------------------------------------------------------
SELECT cron.schedule(
    'cleanup-abandoned-carts',
    '0 18 * * 0',
    $$SELECT public.cleanup_abandoned_carts(30)$$
);

-- ----------------------------------------------------------------
-- 登録確認
-- ----------------------------------------------------------------
-- SELECT * FROM cron.job ORDER BY jobname;
