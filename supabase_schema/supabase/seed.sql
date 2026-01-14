-- 仮のユーザーデータの投入
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '2498c0f3-e1a9-4149-bad4-d8320f5772a8',
  'authenticated',
  'authenticated',
  'test@gmail.com',
  crypt('password', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '',
  '',
  '',
  ''
),
(
  '00000000-0000-0000-0000-000000000000',
  'eecd2638-c80a-47c1-9105-eb0856fd5345',
  'authenticated',
  'authenticated',
  'eno49private@gmail.com',
  crypt('eno49', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '',
  '',
  '',
  ''
),
(
  '00000000-0000-0000-0000-000000000000',
  '2498c0f3-e1a9-4149-bad4-d8320f5772b2',
  'authenticated',
  'authenticated',
  'nodata@gmail.com',
  crypt('nodata', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '',
  '',
  '',
  ''
);

-- 仮の店舗用データの投入
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  '0002c0f3-e1a9-4149-bad4-d8320f5772a8',
  'authenticated',
  'authenticated',
  '0002@gmail.com',
  crypt('0002', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '',
  '',
  '',
  ''
),
(
  '00000000-0000-0000-0000-000000000000',
  '0011c0f3-e1a9-4149-bad4-d8320f5772a8',
  'authenticated',
  'authenticated',
  '0011@gmail.com',
  crypt('0011', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}',
  '{}',
  now(),
  now(),
  '',
  '',
  '',
  ''
);

-- 仮登録ユーザ情報
INSERT INTO "public"."pre_signup_users" ("id", "token", "email", "created_at", "expires_at") 
VALUES
 ('6d8f9b4a-6b2a-438a-8f12-69bdbce9910a', '7RRtXNgRpCiWpaakdKs9yGmCFh0x7B97', 'test97@gmail.com', '2025-04-29 08:22:37.067875+00', '2025-04-29 08:52:37.067875+00'),
 ('6d8f9b4a-6b2a-438a-8f12-69bdbce9910b', '7RRtXNgRpCiWpaakdKs9yGmCFh0x7B98', 'test98@gmail.com', '2025-05-29 08:22:37.067875+00', '2025-05-29 08:52:37.067875+00'),
 ('6d8f9b4a-6b2a-438a-8f12-69bdbce9910c', '7RRtXNgRpCiWpaakdKs9yGmCFh0x7B99', 'test99@gmail.com', '2025-06-29 08:22:37.067875+00', '2025-06-29 08:52:37.067875+00');

-- 都道府県データの投入
INSERT INTO public.prefectures (name) VALUES
('北海道'), ('青森県'), ('岩手県'), ('宮城県'), ('秋田県'),
('山形県'), ('福島県'), ('茨城県'), ('栃木県'), ('群馬県'),
('埼玉県'), ('千葉県'), ('東京都'), ('神奈川県'), ('新潟県'),
('富山県'), ('石川県'), ('福井県'), ('山梨県'), ('長野県'),
('岐阜県'), ('静岡県'), ('愛知県'), ('三重県'), ('滋賀県'),
('京都府'), ('大阪府'), ('兵庫県'), ('奈良県'), ('和歌山県'),
('鳥取県'), ('島根県'), ('岡山県'), ('広島県'), ('山口県'),
('徳島県'), ('香川県'), ('愛媛県'), ('高知県'), ('福岡県'),
('佐賀県'), ('長崎県'), ('熊本県'), ('大分県'), ('宮崎県'),
('鹿児島県'), ('沖縄県');

-- サンプル店舗データの投入
INSERT INTO public.stores 
  (store_number, store_name, prefecture_id, address, opening_time, closing_time, opening_date, closing_date, is_drive_thru_available, latitude, longitude) 
VALUES
  ('0001', '札幌中央店', 1, '北海道札幌市中央区北1条西2丁目1-1', '08:30', '22:00', '2020-04-01', NULL, '0',  43.063968, 141.347899),
  ('0002', '仙台駅前店', 4, '宮城県仙台市青葉区中央1-1-1', '09:00', '21:30', '2020-06-15', NULL, '0',  38.268215, 140.869356),
  ('0003', '東京新宿店', 13, '東京都新宿区新宿3-1-1', '07:45', '23:00', '2019-10-01', NULL, '0',  35.689487, 139.691711),
  ('0004', '横浜ベイサイド店', 14, '神奈川県横浜市中区海岸通1-1', '10:00', '20:00', '2021-03-20', NULL, '0',  35.443707, 139.638031),
  ('0005', '名古屋栄店', 23, '愛知県名古屋市中区栄3-1-1', '08:00', '22:30', '2020-09-10', NULL, '0',  35.170915, 136.881537),
  ('0006', '大阪梅田店', 27, '大阪府大阪市北区梅田1-1-1', '09:15', '21:00', '2019-12-01', NULL, '0',  34.693737, 135.502167),
  ('0007', '神戸ハーバー店', 28, '兵庫県神戸市中央区波止場町1-1', '08:45', '22:15', '2021-07-07', NULL, '0',  34.690083, 135.195511),
  ('0008', '福岡天神店', 40, '福岡県福岡市中央区天神2-1-1', '09:30', '20:45', '2020-11-11', NULL, '0',  33.590355, 130.401716),
  ('0009', '沖縄那覇店', 47, '沖縄県那覇市おもろまち1-1-1', '10:00', '21:00', '2022-04-01', NULL, '0',  26.212401, 127.680932),
  ('0010', '旭川駅前店', 1, '北海道旭川市宮下通7丁目', '08:00', '19:30', '2021-05-05', '2023-01-31', '0',43.770635, 142.364891),
  ('0011', '東京池袋店', 13, '東京都豊島区南池袋1-1-1', '09:00', '22:00', '2018-08-15', NULL, '0',  35.728926, 139.711086),
  ('0012', '東京渋谷店', 13, '東京都渋谷区宇田川町1-1', '07:30', '23:30', '2017-12-20', NULL, '0',  35.661741, 139.704521),
  ('0013', '東京銀座店', 13, '東京都中央区銀座4-1-1', '08:00', '22:00', '2019-05-01', NULL, '0',  35.671156, 139.764936),
  ('0014', '東京秋葉原店', 13, '東京都千代田区外神田1-1-1', '09:30', '21:30', '2020-02-10', NULL, '1',  35.698683, 139.774219),
  ('0015', '東京品川店', 13, '東京都港区高輪3-1-1', '08:45', '22:15', '2021-06-30', NULL, '0',  35.628472, 139.738759),
  ('0016', '鎌ヶ谷駅前店', 12, '千葉県鎌ヶ谷市中央1-1-1', '09:00', '21:00', '2022-03-01', NULL, '0',  35.766500, 139.982500),
  ('0017', '市川駅前店', 12, '千葉県市川市市川1-1-1', '08:30', '20:30', '2021-11-01', NULL, '0',  35.733574, 139.934230),
  ('0018', '千葉駅前店', 12, '千葉県千葉市中央区新千葉1-1-1', '09:00', '22:00', '2020-08-01', NULL, '0',  35.608312, 140.106218),
  ('0019', '舞浜駅前店', 12, '千葉県浦安市舞浜1-1-1', '10:00', '22:00', '2022-06-15', NULL, '0',  35.651873, 139.861998),
  ('0020', '船橋駅前店', 12, '千葉県船橋市本町1-1-1', '08:45', '21:30', '2021-05-20', NULL, '0',  35.693815, 139.989547),
  ('0021', '蘇我駅前店', 12, '千葉県千葉市中央区蘇我1-1-1', '09:15', '21:00', '2020-12-10', NULL, '0',  35.598530, 140.126022),
  ('0022', '木更津駅前店', 12, '千葉県木更津市大和町1-1-1', '08:30', '20:30', '2021-07-10', NULL, '0',  35.377284, 139.918933),
  ('0023', '館山駅前店', 12, '千葉県館山市館山1-1-1', '09:00', '20:00', '2022-04-05', NULL, '0',  34.976216, 139.898875),
  ('0024', '成田駅前店', 12, '千葉県成田市花崎町1-1-1', '07:45', '21:30', '2021-09-01', NULL, '0',  35.771725, 140.316708),
  ('0025', '西船橋駅前店', 12, '千葉県船橋市西船4-1-1', '09:30', '22:00', '2022-02-25', NULL, '0',  35.711846, 139.973206);

-- 店舗プロフィールデータの投入
INSERT INTO store_profiles 
  (store_number, user_id) 
VALUES 
  ('0002', '0002c0f3-e1a9-4149-bad4-d8320f5772a8'),
  ('0011', '0011c0f3-e1a9-4149-bad4-d8320f5772a8');

-- スターリワード（マスタデータ)
INSERT INTO star_rewards_exchange_items (short_name, name, image_url, points) VALUES
  ('カスタマイズeTicket', 'カスタマイズeTicket', '/images/rewards/customize_eticket.png', 25),
  ('ドリンク・フード・コーヒー一豆/ティーeTicket300', 'ドリンク・フード・コーヒー一豆/ティーeTicket 300', '/images/rewards/drink_food_coffee_300.png', 90),
  ('ドリンク・フード・コーヒー一豆/ティーeTicket500', 'ドリンク・フード・コーヒー一豆/ティーeTicket 500', '/images/rewards/drink_food_coffee_500.png', 130),
  ('ドリンク・フード・コーヒー一豆/ティーeTicket800', 'ドリンク・フード・コーヒー一豆/ティーeTicket 800', '/images/rewards/drink_food_coffee_800.png', 190),
  ('コーヒー豆/ティーeTicket1900', 'コーヒー豆/ティーeTicket 1900', '/images/rewards/coffee_tea_1900.png', 400),
  ('オリジナルグッズ', 'オリジナルグッズ', '/images/rewards/original_goods.png', 400);

-- サンプルデータ: カテゴリ
INSERT INTO categories (category_name, description) 
VALUES 
('コーヒー', 'コーヒー系飲料'),
('ティー', '紅茶・緑茶などのティー系飲料'),
('ラテ', 'ミルクを使用したラテ系飲料');

-- サンプルデータ挿入
INSERT INTO temperature_types (type_name) VALUES ('HOT'), ('ICE');
INSERT INTO sizes (size_name) VALUES ('Short'), ('Tall'), ('Grande'), ('GG');

-- サンプル商品データ（カテゴリID付き）
INSERT INTO products (product_name, category_id, description, product_image_path, sale_type, display_order) 
VALUES 
('アメリカーノ', 1, 'シンプルなブラックコーヒー', 'products/product_1.png', 'regular', 999),
('抹茶ラテ', 3, '抹茶とミルクのラテ', 'products/product_3.png', 'regular', 999),
('エスプレッソ', 1, '濃厚なコーヒーショット', 'products/product_1.png', 'regular', 999),
('アメリカーノ2', 1, 'エスプレッソをお湯で割ったコーヒー', 'products/product_2.png', 'regular', 999),
('カプチーノ', 1, 'エスプレッソにスチームミルクとフォームミルクを加えたコーヒー', 'products/product_1.png', 'regular', 999),
('モカ', 1, 'チョコレートとエスプレッソの組み合わせ', 'products/product_2.png', 'regular', 999),
('ブラックティー', 2, 'シンプルな紅茶', 'products/product_1.png', 'regular', 999),
('アールグレイ', 2, 'ベルガモットの香りが特徴の紅茶', 'products/product_2.png', 'regular', 999),
('抹茶', 2, '日本の伝統的な緑茶', 'products/product_3.png', 'regular', 999),
('ジャスミンティー', 2, 'ジャスミンの香りが漂う中国茶', 'products/product_2.png', 'regular', 999),
('ロイヤルミルクティー', 2, 'ミルクをたっぷり使った濃厚な紅茶', 'products/product_1.png', 'regular', 999),
('カフェラテ', 3, 'エスプレッソとスチームミルクのラテ', 'products/product_2.png', 'regular', 999),
('バニララテ', 3, 'バニラフレーバーのラテ', 'products/product_1.png', 'regular', 999), 
('キャラメルラテ', 3, 'キャラメルソース入りのラテ', 'products/product_2.png', 'regular', 999), 
('ヘーゼルナッツラテ', 3, 'ヘーゼルナッツフレーバーのラテ', 'products/product_1.png', 'regular', 999), 
('チャイラテ', 3, 'スパイスとミルクを使ったインド風のラテ', 'products/product_2.png', 'regular', 999), 
('ソイラテ', 3, '豆乳を使用したヘルシーなラテ', 'products/product_1.png', 'regular', 999),
-- 季節限定商品として追加
('メロンジュース', 2, '季節限定の甘くて爽やかなメロンジュース', 'products/product_18.png', 'seasonal', 20);

-- サンプル商品サイズ価格データ
INSERT INTO product_sizes (product_id, size_id, price) VALUES
(1, 1, 300), (1, 2, 350), (1, 3, 400), (1, 4, 450), -- アメリカーノ
(2, 2, 350),-- 抹茶ラテ
-- (2, 1, 300), (2, 2, 350), (2, 3, 400), (2, 4, 450), -- 抹茶ラテ
(3, 1, 300), (3, 2, 350), (3, 3, 400), (3, 4, 450), -- エスプレッソ
(4, 1, 350), (4, 2, 400), (4, 3, 450), (4, 4, 500), -- アメリカーノ2
(5, 1, 380), (5, 2, 430), (5, 3, 480), (5, 4, 530), -- カプチーノ
(6, 1, 400), (6, 2, 450), (6, 3, 500), (6, 4, 550), -- モカ
(7, 1, 250), (7, 2, 300), (7, 3, 350), (7, 4, 400), -- ブラックティー
(8, 1, 270), (8, 2, 320), (8, 3, 370), -- アールグレイ
(9, 1, 280), (9, 2, 330), (9, 3, 380), (9, 4, 430), -- 抹茶
(10, 1, 290), (10, 2, 340), (10, 3, 390), -- ジャスミンティー
(11, 1, 350), (11, 2, 400), (11, 3, 450), (11, 4, 500), -- ロイヤルミルクティー
(12, 1, 400), (12, 2, 450), (12, 3, 500), (12, 4, 550), -- カフェラテ
(13, 2, 470),  -- バニララテ
(14, 1, 430), (14, 2, 480), (14, 3, 530), (14, 4, 580), -- キャラメルラテ
(15, 2, 490), -- ヘーゼルナッツラテ
(16, 1, 410), (16, 2, 460), (16, 3, 510), (16, 4, 560), -- チャイラテ
(17, 1, 390), (17, 2, 440), (17, 3, 490), (17, 4, 540), -- ソイラテ
-- 季節限定商品として追加
(18, 1, 300), (18, 2, 350), (18, 3, 400), (18, 4, 450); -- メロンジュース

INSERT INTO product_temperature_types (product_id, temperature_type_id) VALUES 
-- アメリカーノ (product_id=1) の温度タイプ設定
(1, 1), -- アメリカーノ, HOT
(1, 2), -- アメリカーノ, ICE

-- 抹茶ラテ (product_id=2) の温度タイプ設定
(2, 1), -- 抹茶ラテ, HOT
(2, 2), -- 抹茶ラテ, ICE

-- エスプレッソ (product_id=3) の温度タイプ設定
(3, 1), -- 抹茶ラテ, HOT

-- アメリカーノ2 (product_id=4) の温度タイプ設定
(4, 1), -- アメリカーノ2, HOT
(4, 2), -- アメリカーノ2, ICE

-- カプチーノ (product_id=5) の温度タイプ設定
(5, 1), -- カプチーノ, HOT

-- モカ (product_id=6) の温度タイプ設定
(6, 1), -- モカ, HOT
(6, 2), -- モカ, ICE

-- ブラックティー (product_id=7) の温度タイプ設定
(7, 1), -- ブラックティー, HOT
(7, 2), -- ブラックティー, ICE

-- アールグレイ (product_id=8) の温度タイプ設定
(8, 1), -- アールグレイ, HOT

-- 抹茶 (product_id=9) の温度タイプ設定
(9, 2), -- 抹茶, ICE

-- ジャスミンティー (product_id=10) の温度タイプ設定
(10, 1), -- ジャスミンティー, HOT

-- ロイヤルミルクティー (product_id=11) の温度タイプ設定
(11, 1), -- ロイヤルミルクティー, HOT
(11, 2), -- ロイヤルミルクティー, ICE

-- カフェラテ (product_id=12) の温度タイプ設定
(12, 1), -- カフェラテ, HOT
(12, 2), -- カフェラテ, ICE

-- バニララテ (product_id=13) の温度タイプ設定
(13, 2), -- バニララテ, ICE

-- キャラメルラテ (product_id=14) の温度タイプ設定
(14, 1), -- キャラメルラテ, HOT
(14, 2), -- キャラメルラテ, ICE

-- ヘーゼルナッツラテ (product_id=15) の温度タイプ設定
(15, 2), -- ヘーゼルナッツラテ, ICE

-- チャイラテ (product_id=16) の温度タイプ設定
(16, 1), -- チャイラテ, HOT

-- ソイラテ (product_id=17) の温度タイプ設定
(17, 1), -- ソイラテ, HOT
(17, 2), -- ソイラテ, ICE

-- メロンジュース (product_id=18) の温度タイプ設定
(18, 2); -- メロンジュース, ICE

-- カード情報
INSERT INTO public.cards
  (card_id, user_id, card_name, image_url, balance, is_main)
VALUES
  (
    '1234-5638-9012-3456',
    '2498c0f3-e1a9-4149-bad4-d8320f5772a8',
    'クレジットカード',
    'https://example.com/card-images/main-credit.png',
    1500,
    1
  ),
  (
    '9876-5432-1098-7654',
    '2498c0f3-e1a9-4149-bad4-d8320f5772a8',
    'ショッピングポイントカード',
    'https://example.com/card-images/point-card.png',
    5000,
    0
  ),
  (
  '4376-5432-1098-7611', 
  'eecd2638-c80a-47c1-9105-eb0856fd5345',
  'eno49private', 
  'https://example.com/card-images/point-card.png',
  1500,
  0
  );  

-- 注文サンプルデータ
-- 概要
INSERT INTO "public"."orders" ("id", "order_id", "user_id", "store_number", "usage", "order_type", "pickup_number", "price_without_tax", "price_with_tax", "payment_method", "provided_status", "created_at", "updated_at") 
VALUES 
('0a777d73-c1ea-4ccd-834f-78ba4dcf2b2b', 'order_chXYLN0rXIqUUOpf_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0011', '2', '2', 'ﾊﾟﾅﾏ*04', '1150', '1242', 'クレジットカード','2', '2025-03-18 05:34:50.785489+00', '2025-03-18 05:34:50.785489+00'), 
('103dc91e-fb0b-4ac2-afaf-2e7f73f9e446', 'order_MTQy5Jm5GeMDuFLj_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0002', '2', '2', 'ｴｼﾞﾌﾟﾄ*06', '1040', '1123', 'クレジットカード', '2', '2025-03-18 05:35:20.211485+00', '2025-03-18 05:35:20.211485+00'), 
('83c608f1-688a-400e-8c2f-89643becb7ee', 'order_ORiANYH4iBd7ClQL_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0014', '2', '2', 'ｲﾀﾘｱ*01', '700', '756', 'クレジットカード', '2', '2025-03-16 01:59:50.658948+00', '2025-03-16 01:59:50.658948+00'), 
('df9879c6-a468-4e72-ae60-6ed5408b65b5', 'order_43DjGHf1iLbyGp5o_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0004', '2', '2', 'ｱﾒﾘｶ*03', '1100', '1188', 'クレジットカード', '2', '2025-03-16 04:46:35.778397+00', '2025-03-16 04:46:35.778397+00'), 
('e7ebdbb1-f2e4-4e13-a790-0ae9e82169a7', 'order_75y0BioS12Q5wUOo_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0011', '2', '2', 'ｲｷﾞﾘｽ*02', '1050', '1134', 'クレジットカード', '2', '2025-04-26 05:34:37.236132+00', '2025-03-18 05:34:37.236132+00'),
('e7ebdbb1-f2e4-4e13-a790-0ae9e82169a8', 'order_76y0BioS12Q5wUOo_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0011', '2', '2', 'ｳｶﾞﾝﾀﾞ*09', '1200', '1320', 'クレジットカード', '0', '2025-06-26 05:36:37.236132+00', '2025-03-18 05:36:37.236132+00');

-- 詳細
INSERT INTO "public"."orders_detail" ("id", "order_id", "user_id", "product_id", "temperature_type_id", "size_id", "count", "subtotal_without_tax") 
VALUES 
('17e984fe-abde-4c19-859e-30e464b9e397', 'order_43DjGHf1iLbyGp5o_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '1', '1', '1', '1', '300'), 
('1bd440cc-b147-445a-a57f-a4d61e6242a3', 'order_43DjGHf1iLbyGp5o_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '2', '1', '2', '1', '350'), 
('839c5bae-77f7-434d-9211-3e21727c92c1', 'order_43DjGHf1iLbyGp5o_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '3', '1', '4', '1', '450'), 
('91e1e3ff-c46d-4dcf-8fcb-ff9f2a952178', 'order_ORiANYH4iBd7ClQL_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '1', '2', '2', '1', '350'), 
('a39af32b-531c-485d-9ba6-a481537d483f', 'order_MTQy5Jm5GeMDuFLj_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '8', '1', '3', '2', '740'), 
('cc8f816a-c852-425a-a6cb-eb5e9ee7ad4f', 'order_75y0BioS12Q5wUOo_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '2', '2', '2', '3', '1050'), 
('cc8f816a-c852-425a-a6ca-eb5e9ee7ad4e', 'order_76y0BioS12Q5wUOo_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '2', '2', '2', '4', '1200'), 
('cd9140fa-6a29-46ca-8ce5-59725a9c7979', 'order_MTQy5Jm5GeMDuFLj_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '1', '1', '1', '1', '300'), 
('dec80cdf-c6a9-4402-b586-09852f9cf5d1', 'order_ORiANYH4iBd7ClQL_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '2', '2', '2', '1', '350'), 
('ed0b43f6-757a-4e6e-931f-aacea5020907', 'order_chXYLN0rXIqUUOpf_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '4', '2', '2', '2', '800'), 
('f888f392-b24c-479c-9b51-245ed02cbb64', 'order_chXYLN0rXIqUUOpf_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '1', '2', '2', '1', '350');

-- スターリワード獲得データ
INSERT INTO "public"."star_acquisitions" 
("id", "user_id", "order_id", "category", "acquired_points", "created_at", "updated_at") 
VALUES 
('34b4eb49-e05f-4dc9-95cd-500c6b22f530', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', 'order_chXYLN0rXIqUUOpf_001', '2', '20.7', '2025-03-18 05:34:50.488266+00', '2025-03-18 05:34:50.488266+00');

-- スターリワード集計用テーブル
INSERT INTO "public"."star_aggregations" (
    "user_id", 
    "target_year_month", 
    "total_points",
    "expiration_flag"
) VALUES 
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202404', 45.2, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202405', 28.3, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202406', 32.6, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202407', 41.5, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202408', 14.8, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202409', 37.2, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202410', 52.9, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202411', 33.7, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202412', 29.4, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202501', 10.5, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202502', 60.7, 0),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202503', 20.7, 0);

-- 期間限定のスター獲得イベント
INSERT INTO campaign_settings (campaign_name, display_name, start_date, end_date, is_active) 
VALUES 
  ('september_campaign_2025', '9月限定キャンペーン', '2025-09-05 00:00:00+09', '2025-09-17 23:59:59+09', true),
  ('spring_campaign_2026', '春の特別企画', '2026-03-01 00:00:00+09', '2026-03-15 23:59:59+09', false);