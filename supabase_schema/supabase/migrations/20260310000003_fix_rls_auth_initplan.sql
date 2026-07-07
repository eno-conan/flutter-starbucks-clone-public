-- Supabase Performance Advisor: auth_rls_initplan 警告対応（20件）
-- auth.uid() / auth.role() をサブクエリ (select auth.uid()) でラップして
-- クエリ実行時に1回だけ評価されるよう最適化する。
-- RLS の評価結果は変わらず、パフォーマンスのみ向上する。


-- ===== user_fcm_tokens =====
-- ポリシー: "Allow users to do everything on their own fcm_token"
-- auth.uid() × 2 箇所（USING / WITH CHECK）

DROP POLICY IF EXISTS "Allow users to do everything on their own fcm_token" ON public.user_fcm_tokens;

CREATE POLICY "Allow users to do everything on their own fcm_token"
  ON public.user_fcm_tokens
  AS permissive
  FOR ALL
  TO public
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));


-- ===== star_acquisitions =====
-- ポリシー: "Users can view only their own star acquisitions"

DROP POLICY IF EXISTS "Users can view only their own star acquisitions" ON public.star_acquisitions;

CREATE POLICY "Users can view only their own star acquisitions"
  ON public.star_acquisitions
  AS permissive
  FOR ALL
  TO public
  USING (((select auth.uid()) = user_id));


-- ===== star_aggregations =====
-- ポリシー: "Users can view only their own star aggregations"

DROP POLICY IF EXISTS "Users can view only their own star aggregations" ON public.star_aggregations;

CREATE POLICY "Users can view only their own star aggregations"
  ON public.star_aggregations
  AS permissive
  FOR ALL
  TO public
  USING (((select auth.uid()) = user_id));


-- ===== star_usage =====
-- ポリシー: "Users can view only their own star usage data"

DROP POLICY IF EXISTS "Users can view only their own star usage data" ON public.star_usage;

CREATE POLICY "Users can view only their own star usage data"
  ON public.star_usage
  AS permissive
  FOR SELECT
  TO public
  USING (((select auth.uid()) = user_id));


-- ===== orders =====
-- ポリシー: "insert_own_orders" / "update_own_or_store_orders"

DROP POLICY IF EXISTS "insert_own_orders" ON public.orders;

CREATE POLICY "insert_own_orders"
  ON public.orders
  AS permissive
  FOR INSERT
  TO public
  WITH CHECK (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "update_own_or_store_orders" ON public.orders;

CREATE POLICY "update_own_or_store_orders"
  ON public.orders
  AS permissive
  FOR UPDATE
  TO public
  USING ((
    ((select auth.uid()) = user_id)
    OR (EXISTS (
      SELECT 1
      FROM store_profiles
      WHERE (
        (store_profiles.user_id = (select auth.uid()))
        AND (store_profiles.store_number = orders.store_number)
      )
    ))
  ));


-- ===== store_profiles =====
-- ポリシー: "店舗は自分の情報のみ閲覧可能"

DROP POLICY IF EXISTS "店舗は自分の情報のみ閲覧可能" ON public.store_profiles;

CREATE POLICY "店舗は自分の情報のみ閲覧可能"
  ON public.store_profiles
  AS permissive
  FOR SELECT
  TO public
  USING (((select auth.uid()) = user_id));


-- ===== user_nickname =====
-- ポリシー: 参照/登録/更新/削除 × 4件

DROP POLICY IF EXISTS "ユーザーは自分のニックネームのみ参照可能" ON public.user_nickname;

CREATE POLICY "ユーザーは自分のニックネームのみ参照可能"
  ON public.user_nickname
  AS permissive
  FOR SELECT
  TO authenticated
  USING (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "ユーザーは自分のニックネームのみ登録可能" ON public.user_nickname;

CREATE POLICY "ユーザーは自分のニックネームのみ登録可能"
  ON public.user_nickname
  AS permissive
  FOR INSERT
  TO authenticated
  WITH CHECK (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "ユーザーは自分のニックネームのみ更新可能" ON public.user_nickname;

CREATE POLICY "ユーザーは自分のニックネームのみ更新可能"
  ON public.user_nickname
  AS permissive
  FOR UPDATE
  TO authenticated
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "ユーザーは自分のニックネームのみ削除可能" ON public.user_nickname;

CREATE POLICY "ユーザーは自分のニックネームのみ削除可能"
  ON public.user_nickname
  AS permissive
  FOR DELETE
  TO authenticated
  USING (((select auth.uid()) = user_id));


-- ===== user_tickets =====
-- ポリシー: select/insert/update/delete × 4件

DROP POLICY IF EXISTS "select_own_etickets" ON public.user_tickets;

CREATE POLICY "select_own_etickets"
  ON public.user_tickets
  AS permissive
  FOR SELECT
  TO public
  USING (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "insert_own_eticket" ON public.user_tickets;

CREATE POLICY "insert_own_eticket"
  ON public.user_tickets
  AS permissive
  FOR INSERT
  TO public
  WITH CHECK (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "update_own_eticket" ON public.user_tickets;

CREATE POLICY "update_own_eticket"
  ON public.user_tickets
  AS permissive
  FOR UPDATE
  TO public
  USING (((select auth.uid()) = user_id))
  WITH CHECK (((select auth.uid()) = user_id));

DROP POLICY IF EXISTS "delete_own_eticket" ON public.user_tickets;

CREATE POLICY "delete_own_eticket"
  ON public.user_tickets
  AS permissive
  FOR DELETE
  TO public
  USING (((select auth.uid()) = user_id));


-- ===== poc_realtime =====
-- ポリシー: "Authenticated users can insert poc_realtime records"
-- auth.role() をサブクエリでラップ

DROP POLICY IF EXISTS "Authenticated users can insert poc_realtime records" ON public.poc_realtime;

CREATE POLICY "Authenticated users can insert poc_realtime records"
  ON public.poc_realtime
  AS permissive
  FOR INSERT
  TO public
  WITH CHECK (((select auth.role()) = 'authenticated'::text));
