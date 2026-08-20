'use strict';

/** イントロスペクション結果から定義書 Markdown と ER図 (.mmd) を組み立てる */

const MD_TABLE_HEADER =
  '| 論理名 | カラム名 | 型 | 主キー | 外部参照 | 備考 |\n' +
  '|--------|----------|-----|--------|----------|------|';

/** 主キー・外部キー・ユニーク・CHECK から「備考」列の文言を作る */
function buildRemarks(table, column) {
  const remarks = [];

  if (column.default != null) {
    // nextval(...) は AUTO INCREMENT として表現する
    if (/^nextval\(/.test(column.default)) {
      const seq = column.default.match(/^nextval\('([^']+)'/);
      remarks.push(seq ? `AUTO INCREMENT (${seq[1].replace(/^public\./, '')})` : 'AUTO INCREMENT');
    } else {
      remarks.push(`デフォルト: ${column.default.replace(/::[\w ]+$/, '')}`);
    }
  }
  if (column.notNull && !table.primaryKey.includes(column.name)) {
    remarks.push('NOT NULL');
  }
  for (const cols of table.uniques) {
    if (cols.length === 1 && cols[0] === column.name) remarks.push('UNIQUE制約');
    else if (cols.includes(column.name)) remarks.push(`UNIQUE制約: (${cols.join(', ')})`);
  }
  for (const chk of table.checks) {
    if (chk.columns.length === 1 && chk.columns[0] === column.name) {
      remarks.push(`CHECK制約: ${chk.definition.replace(/^CHECK \(\(?/, '').replace(/\)?\)$/, '')}`);
    }
  }
  for (const fk of table.foreignKeys) {
    if (fk.columns.includes(column.name) && fk.onDelete) remarks.push(fk.onDelete);
  }
  return remarks.join(', ');
}

/** カラムが参照する外部キーの参照先を "table.column" 形式で返す */
function refFor(table, column) {
  for (const fk of table.foreignKeys) {
    const i = fk.columns.indexOf(column.name);
    if (i === -1) continue;
    const prefix = fk.refSchema === 'public' ? '' : `${fk.refSchema}.`;
    return `${prefix}${fk.refTable}.${fk.refColumns[i]}`;
  }
  return '';
}

function escapeCell(value) {
  return String(value == null ? '' : value).replace(/\|/g, '\\|');
}

function renderTable(table) {
  const lines = [`## ${table.name}`, ''];
  if (table.comment) lines.push(table.comment, '');
  lines.push(MD_TABLE_HEADER);

  for (const col of table.columns) {
    lines.push(
      [
        '',
        escapeCell(col.comment || '—'),
        escapeCell(col.name),
        escapeCell(col.type),
        table.primaryKey.includes(col.name) ? '○' : '',
        escapeCell(refFor(table, col)),
        escapeCell(buildRemarks(table, col)),
        '',
      ].join(' | ').replace(/^ \| /, '| ').replace(/ \| $/, ' |')
    );
  }
  lines.push('');

  if (table.primaryKey.length > 1) {
    lines.push(`**主キー**: \`(${table.primaryKey.join(', ')})\` の複合主キー`, '');
  }
  const multiColumnChecks = table.checks.filter((c) => c.columns.length !== 1);
  for (const chk of multiColumnChecks) {
    lines.push(`**CHECK制約**: \`${chk.definition}\``, '');
  }
  if (table.indexes.length > 0) {
    const rendered = table.indexes
      .map((i) => `\`${i.name}\`${i.isUnique ? ' (UNIQUE)' : ''}`)
      .join(' / ');
    lines.push(`**インデックス**: ${rendered}`, '');
  }
  return lines.join('\n');
}

function renderDefinitions(tables, config, meta) {
  const excluded = new Set(config.excludeTables || []);
  const regular = tables.filter((t) => !t.isMaterializedView && !excluded.has(t.name));
  const views = tables.filter((t) => t.isMaterializedView && !excluded.has(t.name));

  const out = [];
  out.push('## テーブル定義', '');
  out.push(
    '> ⚠️ このセクションは `npm run schema:docs` による自動生成です。直接編集しても次回生成時に上書きされます。',
    '> 論理名（日本語のカラム名）はマイグレーションの `COMMENT ON COLUMN` が正です。',
    ''
  );
  for (const table of regular) out.push(renderTable(table), '---', '');

  if (views.length > 0) {
    out.push('## マテリアライズドビュー (Materialized Views)', '');
    for (const view of views) out.push(renderTable(view), '---', '');
  }

  out.push('## テーブル概要', '');
  const known = new Set();
  for (const group of config.groups) {
    out.push(`### ${group.title}`, '');
    for (const name of group.tables) {
      known.add(name);
      const table = regular.find((t) => t.name === name);
      if (!table) throw new Error(`config.groups の "${name}" が実スキーマに存在しません`);
      out.push(`- \`${name}\`: ${table.comment || '（COMMENT ON TABLE 未設定）'}`);
    }
    for (const name of group.materializedViews || []) {
      known.add(name);
      const view = views.find((t) => t.name === name);
      if (!view) throw new Error(`config.groups の "${name}" が実スキーマに存在しません`);
      out.push(`- \`${name}\` *(Materialized View)*: ${view.comment || '（COMMENT ON TABLE 未設定）'}`);
    }
    out.push('');
    if (group.note) out.push(`> ${group.note}`, '');
  }

  const orphans = [...regular, ...views].map((t) => t.name).filter((n) => !known.has(n));
  if (orphans.length > 0) {
    throw new Error(
      `以下のテーブルが scripts/schema-doc-config.json の groups に未登録です: ${orphans.join(', ')}\n` +
        '  → config に追記してから再実行してください。'
    );
  }

  out.push(
    `合計${regular.length}テーブル` +
      (views.length > 0 ? `とマテリアライズドビュー${views.length}件` : '') +
      'で構成されています。',
    ''
  );

  return { body: out.join('\n'), tableCount: regular.length, viewCount: views.length, meta };
}

// ---------------------------------------------------------------------------
// ER図 (Mermaid)
// ---------------------------------------------------------------------------

/**
 * Mermaid の属性名に使えるよう型名を単純な識別子へ落とす。
 * `numeric(10,1)` や `varchar(100)` は括弧・カンマがパースエラーになるため桁を落とす。
 */
function mermaidType(type) {
  return type.replace(/\(.*\)$/, '').replace(/[^A-Za-z0-9_]/g, '_');
}

/** 日本語コメント内の二重引用符は Mermaid のラベルを壊すため除去する */
function mermaidLabel(value) {
  return String(value == null ? '' : value).replace(/"/g, '');
}

/**
 * ER_README.md に記載のとおり mermaid-cli は PK_FK のような複合制約を解釈できない。
 * 主キーかつ外部キーのカラムは FK のみを出力し、主キー性はリレーションで表現する。
 */
function mermaidConstraint(table, column) {
  const isFk = table.foreignKeys.some((fk) => fk.columns.includes(column.name));
  if (isFk) return 'FK';
  if (table.primaryKey.includes(column.name)) return 'PK';
  const isUnique = table.uniques.some((cols) => cols.length === 1 && cols[0] === column.name);
  return isUnique ? 'UK' : '';
}

const AUTH_USERS_NODE = 'auth_users';

function renderErDiagram(diagram, tables, config) {
  const excluded = new Set(config.excludeTables || []);
  const available = tables.filter((t) => !t.isMaterializedView && !excluded.has(t.name));
  const selected =
    diagram.tables === '*'
      ? available
      : diagram.tables.map((name) => {
          const table = available.find((t) => t.name === name);
          if (!table) throw new Error(`erDiagrams "${diagram.name}" の "${name}" が実スキーマに存在しません`);
          return table;
        });

  const names = new Set(selected.map((t) => t.name));
  const lines = ['erDiagram'];

  // --- リレーション ---
  let referencesAuthUsers = false;
  const relations = [];
  for (const table of selected) {
    for (const fk of table.foreignKeys) {
      const isAuthUsers = fk.refSchema === 'auth' && fk.refTable === 'users';
      if (isAuthUsers) referencesAuthUsers = true;
      else if (fk.refSchema !== 'public' || !names.has(fk.refTable)) continue;

      const parent = isAuthUsers ? AUTH_USERS_NODE : fk.refTable;
      // 参照側のカラムが一意なら 1対0..1、そうでなければ 1対多
      const childUnique =
        table.uniques.some((cols) => cols.join(',') === fk.columns.join(',')) ||
        table.primaryKey.join(',') === fk.columns.join(',');
      const cardinality = childUnique ? '||--o|' : '||--o{';
      relations.push(`    ${parent} ${cardinality} ${table.name} : "${fk.columns.join(', ')}"`);
    }
  }
  lines.push(...[...new Set(relations)].sort());
  lines.push('');

  // --- エンティティ ---
  if (referencesAuthUsers) {
    lines.push(`    ${AUTH_USERS_NODE} {`);
    lines.push('        uuid id PK "ユーザーID (Supabase Auth)"');
    lines.push('    }');
    lines.push('');
  }
  for (const table of selected) {
    lines.push(`    ${table.name} {`);
    for (const col of table.columns) {
      const constraint = mermaidConstraint(table, col);
      const parts = ['       ', mermaidType(col.type), col.name];
      if (constraint) parts.push(constraint);
      parts.push(`"${mermaidLabel(col.comment || col.name)}"`);
      lines.push(parts.join(' '));
    }
    lines.push('    }');
    lines.push('');
  }

  return lines.join('\n').replace(/\n+$/, '\n');
}

module.exports = { renderDefinitions, renderErDiagram, mermaidType };
