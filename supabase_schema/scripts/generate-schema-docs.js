#!/usr/bin/env node
'use strict';

/**
 * ローカルの Supabase(Postgres) を読み取り、テーブル定義書と ER図(.mmd) を生成する。
 *
 *   node scripts/generate-schema-docs.js            生成してファイルへ書き出す
 *   node scripts/generate-schema-docs.js --check    生成結果と現在のファイルを比較する（書き込まない）
 *
 * 接続先は DATABASE_URL、未指定なら supabase start の既定ポート。
 * 事前に `npm run start && npm run db:reset` でマイグレーションを適用しておくこと。
 */

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

const { introspect } = require('./lib/introspect');
const { renderDefinitions, renderErDiagram } = require('./lib/render');

const ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(__dirname, 'schema-doc-config.json');
const MIGRATIONS_DIR = path.join(ROOT, 'supabase', 'migrations');
const DEFAULT_DATABASE_URL = 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';

/** 定義書のうち手書きで維持するセクションの開始見出し */
const PRESERVED_SECTION = '## 主な更新点';
/** 自動生成セクションの開始見出し */
const GENERATED_SECTION = '## テーブル定義';

/**
 * 「最終更新」は生成日時ではなく最新マイグレーションの日付から決める。
 * 実行日に依存させると --check が翌日に落ちるため。
 */
function latestMigrationDate() {
  const stamps = fs
    .readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.sql'))
    .map((f) => f.slice(0, 8))
    .filter((s) => /^\d{8}$/.test(s))
    .sort();
  if (stamps.length === 0) throw new Error(`マイグレーションが見つかりません: ${MIGRATIONS_DIR}`);
  const latest = stamps[stamps.length - 1];
  return `${Number(latest.slice(0, 4))}年${Number(latest.slice(4, 6))}月${Number(latest.slice(6, 8))}日`;
}

/**
 * 既存の定義書から、生成対象外の前後を取り出す。
 * - preamble : タイトル〜「## テーブル定義」の直前（ER図の説明など手書き）
 * - trailer  : 「## 主な更新点」以降（更新履歴。人が書き足す）
 */
function splitExisting(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(
      `${filePath} が存在しません。\n` +
        '  このスクリプトは既存の定義書の前書き・更新履歴を引き継ぐため、初回は手動で用意してください。'
    );
  }
  const text = fs.readFileSync(filePath, 'utf8');
  const genAt = text.indexOf(`\n${GENERATED_SECTION}\n`);
  const preAt = text.indexOf(`\n${PRESERVED_SECTION}\n`);
  if (genAt === -1) throw new Error(`定義書に "${GENERATED_SECTION}" が見つかりません`);
  if (preAt === -1) throw new Error(`定義書に "${PRESERVED_SECTION}" が見つかりません`);
  if (preAt < genAt) throw new Error(`"${PRESERVED_SECTION}" は "${GENERATED_SECTION}" より後ろに置いてください`);
  return {
    preamble: text.slice(0, genAt + 1),
    trailer: text.slice(preAt + 1),
  };
}

/** 前書きの「最終更新:」行だけを差し替える */
function withUpdatedDate(preamble, date) {
  if (!/^最終更新: .*$/m.test(preamble)) {
    throw new Error('定義書の前書きに "最終更新: ..." 行が見つかりません');
  }
  return preamble.replace(/^最終更新: .*$/m, `最終更新: ${date}`);
}

function compare(label, expected, actualPath) {
  const actual = fs.existsSync(actualPath) ? fs.readFileSync(actualPath, 'utf8') : null;
  if (actual === expected) return null;
  if (actual === null) return `${label}: 未生成`;
  const e = expected.split('\n');
  const a = actual.split('\n');
  for (let i = 0; i < Math.max(e.length, a.length); i += 1) {
    if (e[i] !== a[i]) {
      return (
        `${label}: ${i + 1}行目から差分\n` +
        `    現在: ${a[i] === undefined ? '(行なし)' : a[i]}\n` +
        `    生成: ${e[i] === undefined ? '(行なし)' : e[i]}`
      );
    }
  }
  return `${label}: 差分あり`;
}

async function main() {
  const checkOnly = process.argv.includes('--check');
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));

  const client = new Client({ connectionString: process.env.DATABASE_URL || DEFAULT_DATABASE_URL });
  let tables;
  try {
    await client.connect();
    tables = await introspect(client);
  } finally {
    await client.end().catch(() => {});
  }

  if (tables.length === 0) {
    throw new Error(
      'public スキーマにテーブルがありません。マイグレーション適用済みのDBに接続してください。'
    );
  }

  // --- 論理名（COMMENT ON COLUMN）の記述漏れを検出する ---
  const excluded = new Set(config.excludeTables || []);
  const missing = [];
  for (const table of tables) {
    if (excluded.has(table.name)) continue;
    for (const col of table.columns) {
      if (!col.comment) missing.push(`${table.name}.${col.name}`);
    }
  }
  if (missing.length > 0) {
    throw new Error(
      `COMMENT ON COLUMN が未設定のカラムがあります (${missing.length}件):\n` +
        missing.map((m) => `  - ${m}`).join('\n') +
        '\n  → マイグレーションに COMMENT ON COLUMN を追記してください。'
    );
  }

  const definitionsPath = path.join(ROOT, config.output.definitions);
  const erDir = path.join(ROOT, config.output.erDir);
  const { preamble, trailer } = splitExisting(definitionsPath);
  const rendered = renderDefinitions(tables, config, {});
  const document = `${withUpdatedDate(preamble, latestMigrationDate())}${rendered.body}\n${trailer}`;

  const artifacts = [{ label: path.relative(ROOT, definitionsPath), content: document, file: definitionsPath }];
  for (const diagram of config.erDiagrams) {
    const file = path.join(erDir, `${diagram.name}.mmd`);
    artifacts.push({
      label: path.relative(ROOT, file),
      content: renderErDiagram(diagram, tables, config),
      file,
    });
  }

  if (checkOnly) {
    const diffs = artifacts.map((a) => compare(a.label, a.content, a.file)).filter(Boolean);
    if (diffs.length > 0) {
      console.error('スキーマドキュメントが最新ではありません:\n');
      diffs.forEach((d) => console.error(`  ${d}\n`));
      console.error('  → `npm run schema:docs` を実行して結果をコミットしてください。');
      process.exitCode = 1;
      return;
    }
    console.log(`スキーマドキュメントは最新です (${rendered.tableCount}テーブル / ${artifacts.length}ファイル)`);
    return;
  }

  fs.mkdirSync(erDir, { recursive: true });
  for (const a of artifacts) {
    fs.writeFileSync(a.file, a.content);
    console.log(`  生成 ${a.label}`);
  }
  console.log(
    `\n${rendered.tableCount}テーブル / MV${rendered.viewCount}件 を ${artifacts.length}ファイルへ出力しました。`
  );
  console.log('  SVG を更新するには `npm run schema:docs:svg` を実行してください。');
}

main().catch((error) => {
  console.error(`\n${error.message}\n`);
  process.exit(1);
});
