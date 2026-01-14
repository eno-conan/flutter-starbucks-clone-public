
BEGIN
  -- まずcarts_detailテーブルのすべてのレコードを削除
  DELETE FROM carts_detail;
  
  -- 次にcartsテーブルのすべてのレコードを削除
  DELETE FROM carts;
  
  -- ログとして削除実行時刻を記録（オプション）
  RAISE NOTICE 'Cart tables cleanup completed at %', NOW();
  
END;