# BPMN 図管理

[bpmn-js](https://bpmn.io/toolkit/bpmn-js/) を使ってビジネスフローを可視化するツール。
ブラウザ上でBPMN図の閲覧・編集・書き出しができる。

- [bpmn-js bundling example](https://github.com/bpmn-io/bpmn-js-examples/tree/main/bundling)
- [bpmn-js on NPM](https://www.npmjs.com/package/bpmn-js)

## ファイル構成

```
docs/bpmn/
├── diagrams/                    # BPMNファイル置き場
│   └── user_signup_flow.bpmn   # ユーザー会員登録フロー
├── src/
│   ├── app.js                   # bpmn-js Modeler 初期化
│   └── index.html               # ビューワーHTML
├── dist/                        # webpack ビルド成果物（gitignore済み）
├── webpack.config.js
└── package.json
```

## セットアップ（初回のみ）

```bash
cd docs/bpmn
npm install
```

## 起動

```bash
npm start
```

ブラウザが自動で `http://localhost:9013` を開く。

## 操作方法

| 操作 | 内容 |
|---|---|
| マウスホイール | ズームイン・アウト |
| ドラッグ（背景） | キャンバスのパン移動 |
| ドラッグ（要素） | タスク・ゲートウェイなどの移動 |
| ドラッグ（ラベル） | テキストラベルの位置調整 |
| ダブルクリック（ラベル） | テキストの直接編集 |
| Ctrl+Z / Ctrl+Y | undo / redo |

## 編集内容を保存する

1. ブラウザ上で図を編集する
2. 右上の **「XMLをダウンロード」** ボタンをクリック
3. ダウンロードされた `.bpmn` ファイルを `diagrams/` 内の対象ファイルに上書き

これにより、次回 `npm start` した際も編集内容が反映される。

## 図の追加方法

1. `diagrams/` に新しい `.bpmn` ファイルを追加する
2. `src/app.js` の fetch パスを変更して対象ファイルを切り替える

```javascript
// src/app.js の fetch パスを変更
const res = await fetch('./diagrams/your_new_flow.bpmn');
```

## 既存の図

| ファイル | 内容 |
|---|---|
| `user_signup_flow.bpmn` | ユーザー会員登録フロー（仮登録 + 本登録の2段階） |

