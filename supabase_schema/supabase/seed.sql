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
  ('0001', '札幌中央店', 1, '北海道札幌市中央区北1条西2丁目1-1', '08:30', '22:00', '2020-04-01', NULL, false,  43.063968, 141.347899),
  ('0002', '仙台駅前店', 4, '宮城県仙台市青葉区中央1-1-1', '09:00', '21:30', '2020-06-15', NULL, false,  38.268215, 140.869356),
  ('0003', '東京新宿店', 13, '東京都新宿区新宿3-1-1', '07:45', '23:00', '2019-10-01', NULL, false,  35.689487, 139.691711),
  ('0004', '横浜ベイサイド店', 14, '神奈川県横浜市中区海岸通1-1', '10:00', '20:00', '2021-03-20', NULL, false,  35.443707, 139.638031),
  ('0005', '名古屋栄店', 23, '愛知県名古屋市中区栄3-1-1', '08:00', '22:30', '2020-09-10', NULL, false,  35.170915, 136.881537),
  ('0006', '大阪梅田店', 27, '大阪府大阪市北区梅田1-1-1', '09:15', '21:00', '2019-12-01', NULL, false,  34.693737, 135.502167),
  ('0007', '神戸ハーバー店', 28, '兵庫県神戸市中央区波止場町1-1', '08:45', '22:15', '2021-07-07', NULL, false,  34.690083, 135.195511),
  ('0008', '福岡天神店', 40, '福岡県福岡市中央区天神2-1-1', '09:30', '20:45', '2020-11-11', NULL, false,  33.590355, 130.401716),
  ('0009', '沖縄那覇店', 47, '沖縄県那覇市おもろまち1-1-1', '10:00', '21:00', '2022-04-01', NULL, false,  26.212401, 127.680932),
  ('0010', '旭川駅前店', 1, '北海道旭川市宮下通7丁目', '08:00', '19:30', '2021-05-05', '2023-01-31', false,43.770635, 142.364891),
  ('0011', '東京池袋店', 13, '東京都豊島区南池袋1-1-1', '09:00', '22:00', '2018-08-15', NULL, false,  35.728926, 139.711086),
  ('0012', '東京渋谷店', 13, '東京都渋谷区宇田川町1-1', '07:30', '23:30', '2017-12-20', NULL, false,  35.661741, 139.704521),
  ('0013', '東京銀座店', 13, '東京都中央区銀座4-1-1', '08:00', '22:00', '2019-05-01', NULL, false,  35.671156, 139.764936),
  ('0014', '東京秋葉原店', 13, '東京都千代田区外神田1-1-1', '09:30', '21:30', '2020-02-10', NULL, true,  35.698683, 139.774219),
  ('0015', '東京品川店', 13, '東京都港区高輪3-1-1', '08:45', '22:15', '2021-06-30', NULL, false,  35.628472, 139.738759),
  ('0016', '鎌ヶ谷駅前店', 12, '千葉県鎌ヶ谷市中央1-1-1', '09:00', '21:00', '2022-03-01', NULL, false,  35.766500, 139.982500),
  ('0017', '市川駅前店', 12, '千葉県市川市市川1-1-1', '08:30', '20:30', '2021-11-01', NULL, false,  35.733574, 139.934230),
  ('0018', '千葉駅前店', 12, '千葉県千葉市中央区新千葉1-1-1', '09:00', '22:00', '2020-08-01', NULL, false,  35.608312, 140.106218),
  ('0019', '舞浜駅前店', 12, '千葉県浦安市舞浜1-1-1', '10:00', '22:00', '2022-06-15', NULL, false,  35.651873, 139.861998),
  ('0020', '船橋駅前店', 12, '千葉県船橋市本町1-1-1', '08:45', '21:30', '2021-05-20', NULL, false,  35.693815, 139.989547),
  ('0021', '蘇我駅前店', 12, '千葉県千葉市中央区蘇我1-1-1', '09:15', '21:00', '2020-12-10', NULL, false,  35.598530, 140.126022),
  ('0022', '木更津駅前店', 12, '千葉県木更津市大和町1-1-1', '08:30', '20:30', '2021-07-10', NULL, false,  35.377284, 139.918933),
  ('0023', '館山駅前店', 12, '千葉県館山市館山1-1-1', '09:00', '20:00', '2022-04-05', NULL, false,  34.976216, 139.898875),
  ('0024', '成田駅前店', 12, '千葉県成田市花崎町1-1-1', '07:45', '21:30', '2021-09-01', NULL, false,  35.771725, 140.316708),
  ('0025', '西船橋駅前店', 12, '千葉県船橋市西船4-1-1', '09:30', '22:00', '2022-02-25', NULL, false,  35.711846, 139.973206),
  ('0026', '大宮駅東口店', 11, '埼玉県さいたま市大宮区桜木町2-1-1', '08:00', '22:00', '2021-04-01', NULL, false,  35.906654, 139.623895),
  ('0027', '川越駅前店', 11, '埼玉県川越市脇田本町1-1', '09:00', '21:30', '2021-09-15', NULL, false,  35.925277, 139.485855),
  ('0028', '浦和駅前店', 11, '埼玉県さいたま市浦和区高砂1-1-1', '08:30', '22:00', '2022-01-20', NULL, false,  35.859398, 139.655437),
  ('0029', '宇都宮駅前店', 9, '栃木県宇都宮市川向町1-1', '09:00', '21:00', '2020-10-01', NULL, false,  36.554872, 139.882564),
  ('0030', '日光駅前店', 9, '栃木県日光市相生町1-1', '10:00', '19:00', '2022-05-03', NULL, false,  36.745272, 139.604309),
  ('0031', '足利駅前店', 9, '栃木県足利市伊勢町1-1', '08:30', '20:30', '2021-06-20', NULL, false,  36.339148, 139.448978),
  ('0032', '前橋駅前店', 10, '群馬県前橋市表町1-1-1', '09:00', '21:00', '2020-07-15', NULL, false,  36.390856, 139.060861),
  ('0033', '高崎駅東口店', 10, '群馬県高崎市八島町1-1', '08:00', '22:00', '2021-03-01', NULL, true,  36.322617, 139.004005),
  ('0034', '太田駅南口店', 10, '群馬県太田市飯田町1-1', '09:30', '21:30', '2022-07-10', NULL, false,  36.293165, 139.376437),
  ('0035', '京都駅前店', 26, '京都府京都市下京区烏丸通塩小路下ル1-1', '08:00', '22:30', '2020-03-01', NULL, false,  34.985648, 135.758829),
  ('0036', '広島駅前店', 34, '広島県広島市南区松原町1-1', '09:00', '21:00', '2021-11-03', NULL, false,  34.397440, 132.475937),
  ('0037', '静岡駅前店', 22, '静岡県静岡市葵区黒金町1-1', '08:30', '21:30', '2020-05-20', NULL, false,  34.971652, 138.388727),
  ('0038', '金沢駅前店', 17, '石川県金沢市木ノ新保町1-1', '09:00', '21:00', '2021-08-01', NULL, false,  36.578293, 136.648003),
  ('0039', '松山駅前店', 38, '愛媛県松山市宮田町1-1', '08:30', '20:30', '2022-03-15', NULL, false,  33.842820, 132.765553),
  ('0040', '鹿児島中央駅前店', 46, '鹿児島県鹿児島市中央町1-1', '09:00', '21:30', '2021-10-10', NULL, false,  31.590099, 130.542397);

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
('抹茶ラテ', 3, '抹茶とミルクのラテ', 'products/product_2.png', 'regular', 999),
('エスプレッソ', 1, '濃厚なコーヒーショット', 'products/product_3.png', 'regular', 999),
('アメリカーノ2', 1, 'エスプレッソをお湯で割ったコーヒー', 'products/product_4.png', 'regular', 999),
('カプチーノ', 1, 'エスプレッソにスチームミルクとフォームミルクを加えたコーヒー', 'products/product_5.png', 'regular', 999),
('モカ', 1, 'チョコレートとエスプレッソの組み合わせ', 'products/product_6.png', 'regular', 999),
('ブラックティー', 2, 'シンプルな紅茶', 'products/product_7.png', 'regular', 999),
('アールグレイ', 2, 'ベルガモットの香りが特徴の紅茶', 'products/product_8.png', 'regular', 999),
('抹茶', 2, '日本の伝統的な緑茶', 'products/product_9.png', 'regular', 999),
('ジャスミンティー', 2, 'ジャスミンの香りが漂う中国茶', 'products/product_10.png', 'regular', 999),
('ロイヤルミルクティー', 2, 'ミルクをたっぷり使った濃厚な紅茶', 'products/product_11.png', 'regular', 999),
('カフェラテ', 3, 'エスプレッソとスチームミルクのラテ', 'products/product_12.png', 'regular', 999),
('バニララテ', 3, 'バニラフレーバーのラテ', 'products/product_13.png', 'regular', 999), 
('キャラメルラテ', 3, 'キャラメルソース入りのラテ', 'products/product_14.png', 'regular', 999), 
('ヘーゼルナッツラテ', 3, 'ヘーゼルナッツフレーバーのラテ', 'products/product_15.png', 'regular', 999), 
('チャイラテ', 3, 'スパイスとミルクを使ったインド風のラテ', 'products/product_16.png', 'regular', 999), 
('ソイラテ', 3, '豆乳を使用したヘルシーなラテ', 'products/product_17.png', 'regular', 999),
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
    true
  ),
  (
    '9876-5432-1098-7654',
    '2498c0f3-e1a9-4149-bad4-d8320f5772a8',
    'ショッピングポイントカード',
    'https://example.com/card-images/point-card.png',
    5000,
    false
  ),
  (
  '4376-5432-1098-7611', 
  'eecd2638-c80a-47c1-9105-eb0856fd5345',
  'eno49private', 
  'https://example.com/card-images/point-card.png',
  1500,
  false
  );
  -- (
  -- '5098-5432-1098-7655', 
  -- 'df4d01af-5ac9-45f0-956f-da489d2d4fd9',
  -- 'stg1', 
  -- 'https://example.com/card-images/point-card.png',
  -- 2000,
  -- false
  -- );  

-- 注文サンプルデータ
-- 概要
INSERT INTO "public"."orders" ("id", "order_id", "user_id", "store_number", "usage", "order_type", "pickup_number", "price_without_tax", "price_with_tax", "tax_rate", "payment_method", "provided_status", "created_at", "updated_at")
VALUES
('0a777d73-c1ea-4ccd-834f-78ba4dcf2b2b', 'order_chXYLN0rXIqUUOpf_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0011', '2', '2', 'ﾊﾟﾅﾏ*04', '1150', '1242', '8', 'クレジットカード','provided', '2025-03-18 05:34:50.785489+00', '2025-03-18 05:34:50.785489+00'),
('103dc91e-fb0b-4ac2-afaf-2e7f73f9e446', 'order_MTQy5Jm5GeMDuFLj_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0002', '2', '2', 'ｴｼﾞﾌﾟﾄ*06', '1040', '1123', '8', 'クレジットカード', 'provided', '2025-03-18 05:35:20.211485+00', '2025-03-18 05:35:20.211485+00'),
('83c608f1-688a-400e-8c2f-89643becb7ee', 'order_ORiANYH4iBd7ClQL_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0014', '2', '2', 'ｲﾀﾘｱ*01', '700', '756', '8', 'クレジットカード', 'provided', '2025-03-16 01:59:50.658948+00', '2025-03-16 01:59:50.658948+00'),
('df9879c6-a468-4e72-ae60-6ed5408b65b5', 'order_43DjGHf1iLbyGp5o_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0004', '2', '2', 'ｱﾒﾘｶ*03', '1100', '1188', '8', 'クレジットカード', 'provided', '2025-03-16 04:46:35.778397+00', '2025-03-16 04:46:35.778397+00'),
('e7ebdbb1-f2e4-4e13-a790-0ae9e82169a7', 'order_75y0BioS12Q5wUOo_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0011', '2', '2', 'ｲｷﾞﾘｽ*02', '1050', '1134', '8', 'クレジットカード', 'provided', '2025-04-26 05:34:37.236132+00', '2025-03-18 05:34:37.236132+00'),
('e7ebdbb1-f2e4-4e13-a790-0ae9e82169a8', 'order_76y0BioS12Q5wUOo_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '0011', '2', '2', 'ｳｶﾞﾝﾀﾞ*09', '1200', '1320', '10', 'クレジットカード', 'pending', '2025-06-26 05:36:37.236132+00', '2025-03-18 05:36:37.236132+00');

-- アーカイブ動作確認用データ（18ヶ月以上前 = 2024-09-19より前）
-- 現在日付 2026-03-19 基準で archive_old_orders(18) の対象となる
INSERT INTO "public"."orders" ("id", "order_id", "user_id", "store_number", "usage", "order_type", "pickup_number", "price_without_tax", "price_with_tax", "tax_rate", "payment_method", "provided_status", "created_at", "updated_at")
VALUES
('a1000001-0000-0000-0000-000000000001', 'order_arch_0001', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0001', '1', '1', 'ｱｰｶｲﾌﾞ*01', '650',  '702', '8',  'クレジットカード', 'provided', '2023-01-15 09:00:00+00', '2023-01-15 09:00:00+00'),
('a1000001-0000-0000-0000-000000000002', 'order_arch_0002', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0003', '2', '2', 'ｱｰｶｲﾌﾞ*02', '700',  '756', '8',  'クレジットカード', 'provided', '2023-03-20 11:30:00+00', '2023-03-20 11:30:00+00'),
('a1000001-0000-0000-0000-000000000003', 'order_arch_0003', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0011', '1', '1', 'ｱｰｶｲﾌﾞ*03', '800',  '864', '8',  'クレジットカード', 'provided', '2023-05-10 08:15:00+00', '2023-05-10 08:15:00+00'),
('a1000001-0000-0000-0000-000000000004', 'order_arch_0004', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0006', '2', '2', 'ｱｰｶｲﾌﾞ*04', '1100', '1188', '8', 'クレジットカード', 'provided', '2023-07-25 14:45:00+00', '2023-07-25 14:45:00+00'),
('a1000001-0000-0000-0000-000000000005', 'order_arch_0005', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0003', '1', '1', 'ｱｰｶｲﾌﾞ*05', '450',  '486', '8',  'クレジットカード', 'provided', '2023-09-08 10:00:00+00', '2023-09-08 10:00:00+00'),
('a1000001-0000-0000-0000-000000000006', 'order_arch_0006', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0011', '2', '2', 'ｱｰｶｲﾌﾞ*06', '950',  '1026', '8', 'クレジットカード', 'provided', '2023-11-30 16:20:00+00', '2023-11-30 16:20:00+00'),
('a1000001-0000-0000-0000-000000000007', 'order_arch_0007', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0002', '1', '1', 'ｱｰｶｲﾌﾞ*07', '350',  '378', '8',  'クレジットカード', 'provided', '2024-01-14 07:30:00+00', '2024-01-14 07:30:00+00'),
('a1000001-0000-0000-0000-000000000008', 'order_arch_0008', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0003', '2', '2', 'ｱｰｶｲﾌﾞ*08', '1050', '1134', '8', 'クレジットカード', 'provided', '2024-03-22 12:00:00+00', '2024-03-22 12:00:00+00'),
('a1000001-0000-0000-0000-000000000009', 'order_arch_0009', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0011', '1', '1', 'ｱｰｶｲﾌﾞ*09', '750',  '810', '8',  'クレジットカード', 'provided', '2024-06-05 09:45:00+00', '2024-06-05 09:45:00+00'),
('a1000001-0000-0000-0000-000000000010', 'order_arch_0010', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '0006', '2', '2', 'ｱｰｶｲﾌﾞ*10', '900',  '972', '8',  'クレジットカード', 'provided', '2024-09-01 13:10:00+00', '2024-09-01 13:10:00+00');

-- 詳細
INSERT INTO "public"."orders_detail" ("id", "order_id", "user_id", "product_id", "temperature_type_id", "size_id", "count", "subtotal_without_tax", "product_name", "unit_price_without_tax")
-- Issue #938 D-1: 商品名は products から、税抜単価は 小計 ÷ 数量 から導出する
SELECT v."id"::uuid, v."order_id"::varchar(32), v."user_id"::uuid,
       v."product_id"::integer, v."temperature_type_id"::integer, v."size_id"::integer,
       v."count"::integer, v."subtotal_without_tax"::integer,
       p."product_name", v."subtotal_without_tax"::integer / v."count"::integer
FROM (VALUES
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
('f888f392-b24c-479c-9b51-245ed02cbb64', 'order_chXYLN0rXIqUUOpf_001', '2498c0f3-e1a9-4149-bad4-d8320f5772a8', '1', '2', '2', '1', '350')
) AS v ("id", "order_id", "user_id", "product_id", "temperature_type_id", "size_id", "count", "subtotal_without_tax")
JOIN "public"."products" p ON p."product_id" = v."product_id"::integer;

-- アーカイブ動作確認用 orders_detail（上記10件の古い注文に対応）
INSERT INTO "public"."orders_detail" ("id", "order_id", "user_id", "product_id", "temperature_type_id", "size_id", "count", "subtotal_without_tax", "product_name", "unit_price_without_tax")
-- Issue #938 D-1: 商品名は products から、税抜単価は 小計 ÷ 数量 から導出する
SELECT v."id"::uuid, v."order_id"::varchar(32), v."user_id"::uuid,
       v."product_id"::integer, v."temperature_type_id"::integer, v."size_id"::integer,
       v."count"::integer, v."subtotal_without_tax"::integer,
       p."product_name", v."subtotal_without_tax"::integer / v."count"::integer
FROM (VALUES
-- order_arch_0001: アメリカーノ(HOT/Short) 1杯
('b1000001-0000-0000-0000-000000000001', 'order_arch_0001', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '1',  '1', '1', '1', '300'),
('b1000001-0000-0000-0000-000000000002', 'order_arch_0001', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '7',  '1', '2', '1', '350'),
-- order_arch_0002: 抹茶ラテ(HOT/Tall) 1杯
('b1000001-0000-0000-0000-000000000003', 'order_arch_0002', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '2',  '1', '2', '1', '350'),
('b1000001-0000-0000-0000-000000000004', 'order_arch_0002', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '12', '1', '2', '1', '450'),
-- order_arch_0003: カフェラテ(ICE/Grande) 1杯
('b1000001-0000-0000-0000-000000000005', 'order_arch_0003', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '12', '2', '3', '1', '500'),
('b1000001-0000-0000-0000-000000000006', 'order_arch_0003', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '6',  '1', '2', '1', '450'),
-- order_arch_0004: キャラメルラテ(HOT/Tall) 2杯 + アメリカーノ(HOT/Short)
('b1000001-0000-0000-0000-000000000007', 'order_arch_0004', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '14', '1', '2', '2', '960'),
('b1000001-0000-0000-0000-000000000008', 'order_arch_0004', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '1',  '1', '1', '1', '300'),
-- order_arch_0005: ブラックティー(HOT/Short) 1杯
('b1000001-0000-0000-0000-000000000009', 'order_arch_0005', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '7',  '1', '1', '1', '250'),
('b1000001-0000-0000-0000-000000000010', 'order_arch_0005', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '1',  '2', '2', '1', '350'),
-- order_arch_0006: モカ(HOT/Tall) + アールグレイ(HOT/Tall)
('b1000001-0000-0000-0000-000000000011', 'order_arch_0006', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '6',  '1', '2', '1', '450'),
('b1000001-0000-0000-0000-000000000012', 'order_arch_0006', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '8',  '1', '2', '1', '320'),
-- order_arch_0007: アメリカーノ(ICE/Tall) 1杯
('b1000001-0000-0000-0000-000000000013', 'order_arch_0007', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '1',  '2', '2', '1', '350'),
-- order_arch_0008: ソイラテ(HOT/Tall) + カプチーノ(HOT/Short)
('b1000001-0000-0000-0000-000000000014', 'order_arch_0008', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '17', '1', '2', '1', '440'),
('b1000001-0000-0000-0000-000000000015', 'order_arch_0008', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '5',  '1', '1', '1', '380'),
('b1000001-0000-0000-0000-000000000016', 'order_arch_0008', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '4',  '1', '1', '1', '350'),
-- order_arch_0009: 抹茶(ICE/Grande) + ロイヤルミルクティー(HOT/Short)
('b1000001-0000-0000-0000-000000000017', 'order_arch_0009', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '9',  '2', '3', '1', '380'),
('b1000001-0000-0000-0000-000000000018', 'order_arch_0009', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '11', '1', '1', '1', '350'),
-- order_arch_0010: チャイラテ(HOT/Grande) + カフェラテ(ICE/Tall)
('b1000001-0000-0000-0000-000000000019', 'order_arch_0010', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '16', '1', '3', '1', '510'),
('b1000001-0000-0000-0000-000000000020', 'order_arch_0010', 'eecd2638-c80a-47c1-9105-eb0856fd5345', '12', '2', '2', '1', '450')
) AS v ("id", "order_id", "user_id", "product_id", "temperature_type_id", "size_id", "count", "subtotal_without_tax")
JOIN "public"."products" p ON p."product_id" = v."product_id"::integer;

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
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202404', 45.2, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202405', 28.3, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202406', 32.6, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202407', 41.5, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202408', 14.8, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202409', 37.2, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202410', 52.9, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202411', 33.7, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202412', 29.4, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202501', 10.5, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202502', 60.7, false),
('2498c0f3-e1a9-4149-bad4-d8320f5772a8', '202503', 20.7, false);

-- 期間限定のスター獲得イベント
INSERT INTO campaign_settings (campaign_name, display_name, start_date, end_date, is_active)
VALUES
  ('september_campaign_2025', '9月限定キャンペーン', '2025-09-05 00:00:00+09', '2025-09-17 23:59:59+09', true),
  ('spring_campaign_2026', '春の特別企画', '2026-03-01 00:00:00+09', '2026-03-15 23:59:59+09', false);

-- スタッフデータの投入
INSERT INTO "public"."staff"
  ("staff_number", "staff_name", "email", "phone", "employment_type", "hire_date", "termination_date", "is_active")
VALUES
  ('STF001', '山田太郎', 'yamada.taro@starbucks-clone.com', '090-1234-5678', '正社員', '2024-04-01', NULL, true),
  ('STF002', '佐藤花子', 'sato.hanako@starbucks-clone.com', '090-2345-6789', 'パート', '2024-06-01', NULL, true),
  ('STF003', '鈴木次郎', 'suzuki.jiro@starbucks-clone.com', '090-3456-7890', 'アルバイト', '2025-01-15', NULL, true),
  ('STF004', '伊藤健一', 'ito.kenichi@starbucks-clone.com', '090-4567-8901', '正社員', '2024-07-01', NULL, true),
  ('STF005', '渡辺由美', 'watanabe.yumi@starbucks-clone.com', '090-5678-9012', 'パート', '2024-09-01', NULL, true),
  ('STF006', '小林さくら', 'kobayashi.sakura@starbucks-clone.com', '090-6789-0123', 'アルバイト', '2025-03-01', NULL, true);

-- スタッフシフトスケジュールデータの投入（2026年2月20日～3月15日）
INSERT INTO "public"."staff_schedules"
  ("date", "staff_number", "store_number", "period_1", "period_2", "period_3", "period_4", "period_5")
VALUES
  -- STF001（正社員・山田太郎）のシフト（2026年2月20日～28日）
  ('2026-02-20', 'STF001', '0011', true, true, true, true, false),
  ('2026-02-21', 'STF001', '0011', true, true, true, true, false),
  ('2026-02-22', 'STF001', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-23', 'STF001', '0011', true, true, true, true, false),
  ('2026-02-24', 'STF001', '0011', true, true, true, false, false),
  ('2026-02-25', 'STF001', '0011', true, true, true, true, true),
  ('2026-02-26', 'STF001', '0011', true, true, true, true, false),
  ('2026-02-27', 'STF001', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-28', 'STF001', '0011', true, true, true, true, false),
  -- STF001（正社員・山田太郎）のシフト（2026年3月1日～15日）
  ('2026-03-01', 'STF001', '0011', true, true, true, true, false),
  ('2026-03-02', 'STF001', '0011', true, true, true, false, false),
  ('2026-03-03', 'STF001', '0011', true, true, true, true, true),
  ('2026-03-04', 'STF001', '0011', true, true, true, true, false),
  ('2026-03-05', 'STF001', '0011', true, true, true, true, false),
  ('2026-03-06', 'STF001', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-07', 'STF001', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-08', 'STF001', '0011', true, true, true, true, false),
  ('2026-03-09', 'STF001', '0011', true, true, true, false, false),
  ('2026-03-10', 'STF001', '0011', true, true, true, true, true),
  ('2026-03-11', 'STF001', '0011', true, true, true, true, false),
  ('2026-03-12', 'STF001', '0011', true, true, true, true, false),
  ('2026-03-13', 'STF001', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-14', 'STF001', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-15', 'STF001', '0011', true, true, true, true, false),

  -- STF002（パート・佐藤花子）のシフト（2026年2月20日～28日）
  ('2026-02-20', 'STF002', '0011', true, true, true, false, false),
  ('2026-02-21', 'STF002', '0011', true, true, true, false, false),
  ('2026-02-22', 'STF002', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-23', 'STF002', '0011', true, true, true, false, false),
  ('2026-02-24', 'STF002', '0011', true, true, false, false, false),
  ('2026-02-25', 'STF002', '0011', true, true, true, false, false),
  ('2026-02-26', 'STF002', '0011', true, true, true, false, false),
  ('2026-02-27', 'STF002', '0011', true, true, true, false, false),
  ('2026-02-28', 'STF002', '0011', false, false, false, false, false),  -- 休み
  -- STF002（パート・佐藤花子）のシフト（2026年3月1日～15日）
  ('2026-03-01', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-02', 'STF002', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-03', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-04', 'STF002', '0011', true, true, false, false, false),
  ('2026-03-05', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-06', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-07', 'STF002', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-08', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-09', 'STF002', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-10', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-11', 'STF002', '0011', true, true, false, false, false),
  ('2026-03-12', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-13', 'STF002', '0011', true, true, true, false, false),
  ('2026-03-14', 'STF002', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-15', 'STF002', '0011', true, true, true, false, false),

  -- STF003（アルバイト・鈴木次郎）のシフト（2026年2月20日～28日）
  ('2026-02-20', 'STF003', '0011', false, false, true, true, true),
  ('2026-02-21', 'STF003', '0011', false, false, true, true, true),
  ('2026-02-22', 'STF003', '0011', false, false, true, true, true),
  ('2026-02-23', 'STF003', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-24', 'STF003', '0011', false, false, true, true, true),
  ('2026-02-25', 'STF003', '0011', false, false, true, true, false),
  ('2026-02-26', 'STF003', '0011', false, false, true, true, true),
  ('2026-02-27', 'STF003', '0011', false, false, true, true, true),
  ('2026-02-28', 'STF003', '0011', false, false, false, false, false),  -- 休み
  -- STF003（アルバイト・鈴木次郎）のシフト（2026年3月1日～15日）
  ('2026-03-01', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-02', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-03', 'STF003', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-04', 'STF003', '0011', false, false, true, true, false),
  ('2026-03-05', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-06', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-07', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-08', 'STF003', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-09', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-10', 'STF003', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-11', 'STF003', '0011', false, false, true, true, false),
  ('2026-03-12', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-13', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-14', 'STF003', '0011', false, false, true, true, true),
  ('2026-03-15', 'STF003', '0011', false, false, false, false, false),  -- 休み

  -- STF004（正社員・伊藤健一）のシフト（2026年2月20日～28日）
  ('2026-02-20', 'STF004', '0011', true, true, true, true, false),
  ('2026-02-21', 'STF004', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-22', 'STF004', '0011', true, true, true, true, false),
  ('2026-02-23', 'STF004', '0011', true, true, true, true, false),
  ('2026-02-24', 'STF004', '0011', true, true, true, true, false),
  ('2026-02-25', 'STF004', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-26', 'STF004', '0011', true, true, true, true, false),
  ('2026-02-27', 'STF004', '0011', true, true, true, true, false),
  ('2026-02-28', 'STF004', '0011', true, true, true, true, false),
  -- STF004（正社員・伊藤健一）のシフト（2026年3月1日～15日）
  ('2026-03-01', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-02', 'STF004', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-03', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-04', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-05', 'STF004', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-06', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-07', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-08', 'STF004', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-09', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-10', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-11', 'STF004', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-12', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-13', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-14', 'STF004', '0011', true, true, true, true, false),
  ('2026-03-15', 'STF004', '0011', false, false, false, false, false),  -- 休み

  -- STF005（パート・渡辺由美）のシフト（2026年2月20日～28日）
  ('2026-02-20', 'STF005', '0011', true, true, true, false, false),
  ('2026-02-21', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-22', 'STF005', '0011', true, true, true, false, false),
  ('2026-02-23', 'STF005', '0011', true, true, true, false, false),
  ('2026-02-24', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-25', 'STF005', '0011', true, true, true, false, false),
  ('2026-02-26', 'STF005', '0011', true, true, true, false, false),
  ('2026-02-27', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-28', 'STF005', '0011', true, true, true, false, false),
  -- STF005（パート・渡辺由美）のシフト（2026年3月1日～15日）
  ('2026-03-01', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-02', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-03', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-04', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-05', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-06', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-07', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-08', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-09', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-10', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-11', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-12', 'STF005', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-13', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-14', 'STF005', '0011', true, true, true, false, false),
  ('2026-03-15', 'STF005', '0011', false, false, false, false, false),  -- 休み

  -- STF006（アルバイト・小林さくら）のシフト（2026年2月20日～28日）
  ('2026-02-20', 'STF006', '0011', false, false, true, true, true),
  ('2026-02-21', 'STF006', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-22', 'STF006', '0011', false, false, true, true, true),
  ('2026-02-23', 'STF006', '0011', false, false, true, true, true),
  ('2026-02-24', 'STF006', '0011', false, false, true, true, true),
  ('2026-02-25', 'STF006', '0011', false, false, false, false, false),  -- 休み
  ('2026-02-26', 'STF006', '0011', false, false, true, true, true),
  ('2026-02-27', 'STF006', '0011', false, false, true, true, true),
  ('2026-02-28', 'STF006', '0011', false, false, true, true, true),
  -- STF006（アルバイト・小林さくら）のシフト（2026年3月1日～15日）
  ('2026-03-01', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-02', 'STF006', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-03', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-04', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-05', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-06', 'STF006', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-07', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-08', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-09', 'STF006', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-10', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-11', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-12', 'STF006', '0011', false, false, false, false, false),  -- 休み
  ('2026-03-13', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-14', 'STF006', '0011', false, false, true, true, true),
  ('2026-03-15', 'STF006', '0011', false, false, true, true, true);