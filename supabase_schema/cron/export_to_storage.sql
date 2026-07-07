-- Issue#544: アーカイブデータの Storage エクスポート - pg_cron スケジュール設定
--
-- 前提: Supabase Dashboard > Database > Extensions で pg_cron が有効なこと
-- 適用方法: Supabase Dashboard > SQL Editor でこのスクリプトを実行する
--
-- タイムゾーン: pg_cron は UTC で動作する
--   - archive-old-orders は 18:00 UTC 実行
--   - エクスポートは完了後の 19:00 UTC に実行（1時間のバッファ）
--   - 19:00 UTC = 翌日 4:00 JST

-- ----------------------------------------------------------------
-- 既存のジョブを削除（冪等性のため再実行可能）
-- ----------------------------------------------------------------
SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname IN ('export-archive-to-storage');

-- ----------------------------------------------------------------
-- アーカイブデータの Storage エクスポート (毎月1日 19:00 UTC = 翌2日 4:00 JST)
-- archive-old-orders（18:00 UTC）完了後に 1 時間ずらして実行
-- ----------------------------------------------------------------
SELECT cron.schedule(
    'export-archive-to-storage',
    '0 19 1 * *',
    $$SELECT public.trigger_export_archive_to_storage()$$
);

-- ----------------------------------------------------------------
-- 登録確認
-- ----------------------------------------------------------------
-- SELECT * FROM cron.job ORDER BY jobname;
