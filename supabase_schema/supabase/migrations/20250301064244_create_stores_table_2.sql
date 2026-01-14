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
  prefecture_id INTEGER NOT NULL REFERENCES prefectures(id),
  address VARCHAR(100) NOT NULL,
  opening_date DATE NOT NULL,
  closing_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  
  -- 店舗番号の一意性制約
  CONSTRAINT unique_store_number UNIQUE (store_number)
);