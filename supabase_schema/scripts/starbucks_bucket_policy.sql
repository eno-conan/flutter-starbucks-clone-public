-- フォルダ名:products

-- 既存のポリシーを削除（存在する場合）
DROP POLICY IF EXISTS "Authenticated users can read starbucks bucket" ON storage.objects;

-- バケットポリシー
CREATE POLICY "Authenticated users can read starbucks bucket"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'starbucks' AND auth.role() = 'authenticated'
);