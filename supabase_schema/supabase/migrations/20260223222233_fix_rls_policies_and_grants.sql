-- ==============================================================
-- Issue#554 セキュリティ修正
-- ① e_tickets_promotions / e_tickets_special_offers
--   - RLS SELECT ポリシー追加
--   - anon / authenticated の過剰 GRANT を REVOKE
-- ② staff / staff_schedules
--   - anon の過剰 GRANT を REVOKE
--   - authenticated を SELECT のみに制限
-- ==============================================================

-- ---------------------------------------------------------------
-- ① e_tickets_promotions
-- ---------------------------------------------------------------

-- anon / authenticated から操作系権限を剥奪
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.e_tickets_promotions
  FROM anon, authenticated;

-- SELECT は全ユーザーに許可（プロモーション情報は公開情報）
GRANT SELECT ON public.e_tickets_promotions TO anon, authenticated;

-- RLS SELECT ポリシー追加（全員が読み取り可能）
CREATE POLICY "select_for_all_users"
  ON public.e_tickets_promotions
  AS PERMISSIVE
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ---------------------------------------------------------------
-- ① e_tickets_special_offers
-- ---------------------------------------------------------------

-- anon / authenticated から操作系権限を剥奪
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.e_tickets_special_offers
  FROM anon, authenticated;

-- SELECT は全ユーザーに許可
GRANT SELECT ON public.e_tickets_special_offers TO anon, authenticated;

-- RLS SELECT ポリシー追加（全員が読み取り可能）
CREATE POLICY "select_for_all_users"
  ON public.e_tickets_special_offers
  AS PERMISSIVE
  FOR SELECT
  TO anon, authenticated
  USING (true);

-- ---------------------------------------------------------------
-- ② staff
-- ---------------------------------------------------------------

-- anon から全権限を剥奪
REVOKE ALL ON public.staff FROM anon;

-- authenticated から操作系権限を剥奪（SELECT のみ残す・RLS ポリシーと一致）
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.staff
  FROM authenticated;

-- ---------------------------------------------------------------
-- ② staff_schedules
-- ---------------------------------------------------------------

-- anon から全権限を剥奪
REVOKE ALL ON public.staff_schedules FROM anon;

-- authenticated から操作系権限を剥奪（SELECT のみ残す・RLS ポリシーと一致）
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.staff_schedules
  FROM authenticated;
