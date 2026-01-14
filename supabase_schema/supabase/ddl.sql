-- seed.sql
-- PostgreSQLのローカル開発環境用テーブル作成・データ投入スクリプト

-- 既存のテーブルを削除（依存関係を考慮した順番）
DROP TABLE IF EXISTS product_sizes;
DROP TABLE IF EXISTS product_temperature_types;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS sizes;
DROP TABLE IF EXISTS temperature_types;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS prefectures;

-- 都道府県テーブルの作成
CREATE TABLE prefectures (
  id SERIAL PRIMARY KEY,
  name VARCHAR(20) NOT NULL
);

-- 店舗テーブルの作成
CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    store_number CHAR(4) NOT NULL,
    store_name VARCHAR(50) NOT NULL,
    prefecture_id INTEGER NOT NULL,
    address VARCHAR(100) NOT NULL,
    opening_date DATE NOT NULL,
    closing_date DATE,
    closing_time TIME NOT NULL DEFAULT '21:00:00'::TIME,
    opening_time TIME NOT NULL DEFAULT '09:00:00'::TIME,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- 店舗番号の一意性制約
    CONSTRAINT unique_store_number UNIQUE (store_number)
);


-- カテゴリテーブル
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 商品テーブル（カテゴリID追加）
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INTEGER REFERENCES categories(category_id),
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 商品温度タイプテーブル
CREATE TABLE temperature_types (
    temperature_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL -- 'HOT', 'ICE' など
);

-- 商品サイズテーブル
CREATE TABLE sizes (
    size_id SERIAL PRIMARY KEY,
    size_name VARCHAR(10) NOT NULL, -- 'S', 'M', 'L', 'LL' など
    size_description VARCHAR(100)
);

-- 商品-温度タイプ関連テーブル
CREATE TABLE product_temperature_types (
    product_id INTEGER REFERENCES products(product_id),
    temperature_type_id INTEGER REFERENCES temperature_types(temperature_type_id),
    PRIMARY KEY (product_id, temperature_type_id)
);

-- 商品-サイズ関連テーブル（価格を直接設定）
CREATE TABLE product_sizes (
    product_id INTEGER REFERENCES products(product_id),
    size_id INTEGER REFERENCES sizes(size_id),
    price INTEGER NOT NULL, -- 整数に変更
    PRIMARY KEY (product_id, size_id)
);

-- インデックス作成
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_product_temperature ON product_temperature_types(product_id);
CREATE INDEX idx_product_sizes ON product_sizes(product_id);