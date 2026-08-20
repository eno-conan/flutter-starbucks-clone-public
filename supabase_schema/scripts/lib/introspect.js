'use strict';

/**
 * Postgres のカタログからスキーマ情報を読み出す。
 *
 * 論理名（日本語のカラム名）は COMMENT ON COLUMN の値をそのまま使う。
 * 定義書・ER図の生成はすべてここで得た情報だけを入力とする。
 */

/**
 * format_type() の出力を定義書向けの短い表記に正規化する。
 * information_schema はマテリアライズドビューを含まないため、pg_catalog を正とする。
 */
function formatType(row) {
  const type = row.formatted_type;
  return type
    .replace(/^character varying/, 'varchar')
    .replace(/^character(?!\s+varying)/, 'bpchar')
    .replace(/^timestamp with time zone$/, 'timestamptz')
    .replace(/^timestamp without time zone$/, 'timestamp')
    .replace(/^time with time zone$/, 'timetz')
    .replace(/^time without time zone$/, 'time')
    .replace(/^double precision$/, 'float8')
    .replace(/ /g, '');
}

const TABLES_SQL = `
  SELECT c.relname AS name,
         c.relkind AS kind,
         obj_description(c.oid, 'pg_class') AS comment
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'public'
     AND c.relkind IN ('r', 'm')
     AND c.relname NOT LIKE 'pg_%'
   ORDER BY c.relname
`;

const COLUMNS_SQL = `
  SELECT c.relname                             AS table_name,
         a.attname                             AS column_name,
         a.attnum                              AS ordinal,
         a.attnotnull                          AS not_null,
         format_type(a.atttypid, a.atttypmod)  AS formatted_type,
         t.typname                             AS udt_name,
         pg_get_expr(d.adbin, d.adrelid)       AS column_default,
         col_description(c.oid, a.attnum)      AS comment
    FROM pg_attribute a
    JOIN pg_class c      ON c.oid = a.attrelid
    JOIN pg_namespace n  ON n.oid = c.relnamespace
    JOIN pg_type t       ON t.oid = a.atttypid
    LEFT JOIN pg_attrdef d
           ON d.adrelid = c.oid AND d.adnum = a.attnum
   WHERE n.nspname = 'public'
     AND c.relkind IN ('r', 'm')
     AND a.attnum > 0
     AND NOT a.attisdropped
   ORDER BY c.relname, a.attnum
`;

const CONSTRAINTS_SQL = `
  SELECT con.conname                                  AS name,
         con.contype::text                            AS type,
         rel.relname                                  AS table_name,
         ARRAY(
           SELECT att.attname
             FROM unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord)
             JOIN pg_attribute att
               ON att.attrelid = con.conrelid AND att.attnum = k.attnum
            ORDER BY k.ord
         )::text[]                                    AS columns,
         fns.nspname                                  AS ref_schema,
         fre.relname                                  AS ref_table,
         ARRAY(
           SELECT att.attname
             FROM unnest(con.confkey) WITH ORDINALITY AS k(attnum, ord)
             JOIN pg_attribute att
               ON att.attrelid = con.confrelid AND att.attnum = k.attnum
            ORDER BY k.ord
         )::text[]                                    AS ref_columns,
         con.confdeltype                              AS on_delete,
         pg_get_constraintdef(con.oid)                AS definition
    FROM pg_constraint con
    JOIN pg_class rel     ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    LEFT JOIN pg_class fre     ON fre.oid = con.confrelid
    LEFT JOIN pg_namespace fns ON fns.oid = fre.relnamespace
   WHERE nsp.nspname = 'public'
     AND con.contype IN ('p', 'f', 'u', 'c')
   ORDER BY rel.relname, con.contype, con.conname
`;

const INDEXES_SQL = `
  SELECT c.relname   AS table_name,
         i.relname   AS index_name,
         idx.indisunique AS is_unique,
         pg_get_indexdef(idx.indexrelid) AS definition
    FROM pg_index idx
    JOIN pg_class c      ON c.oid = idx.indrelid
    JOIN pg_class i      ON i.oid = idx.indexrelid
    JOIN pg_namespace n  ON n.oid = c.relnamespace
   WHERE n.nspname = 'public'
     AND c.relkind IN ('r', 'm')
   ORDER BY c.relname, i.relname
`;

/** conname が示す ON DELETE 動作を読める文字列にする */
const ON_DELETE_LABEL = {
  a: null, // NO ACTION（既定なので表示しない）
  r: 'ON DELETE RESTRICT',
  c: 'ON DELETE CASCADE',
  n: 'ON DELETE SET NULL',
  d: 'ON DELETE SET DEFAULT',
};

async function introspect(client) {
  // pg の Client は1接続で同時に複数クエリを走らせられないため順に実行する
  const tables = await client.query(TABLES_SQL);
  const columns = await client.query(COLUMNS_SQL);
  const constraints = await client.query(CONSTRAINTS_SQL);
  const indexes = await client.query(INDEXES_SQL);

  /** @type {Map<string, object>} */
  const byName = new Map();
  for (const row of tables.rows) {
    byName.set(row.name, {
      name: row.name,
      isMaterializedView: row.kind === 'm',
      comment: row.comment,
      columns: [],
      primaryKey: [],
      foreignKeys: [],
      uniques: [],
      checks: [],
      indexes: [],
      // 主キー・ユニーク制約が内部で作るインデックスは制約側で表現するため覚えておく
      constraintIndexNames: new Set(),
    });
  }

  for (const row of columns.rows) {
    const table = byName.get(row.table_name);
    if (!table) continue;
    table.columns.push({
      name: row.column_name,
      type: formatType(row),
      notNull: row.not_null,
      default: row.column_default,
      comment: row.comment,
    });
  }

  for (const row of constraints.rows) {
    const table = byName.get(row.table_name);
    if (!table) continue;
    switch (row.type) {
      case 'p':
        table.primaryKey = row.columns;
        table.constraintIndexNames.add(row.name);
        break;
      case 'f':
        table.foreignKeys.push({
          columns: row.columns,
          refSchema: row.ref_schema,
          refTable: row.ref_table,
          refColumns: row.ref_columns,
          onDelete: ON_DELETE_LABEL[row.on_delete] || null,
        });
        break;
      case 'u':
        table.uniques.push(row.columns);
        table.constraintIndexNames.add(row.name);
        break;
      case 'c':
        // NOT NULL は列側で表現するため、単純な IS NOT NULL 検査は除く
        if (!/^CHECK \(\(?\w+ IS NOT NULL\)?\)$/.test(row.definition)) {
          table.checks.push({ columns: row.columns, definition: row.definition });
        }
        break;
      default:
        break;
    }
  }

  for (const row of indexes.rows) {
    const table = byName.get(row.table_name);
    if (!table) continue;
    // 制約が自動生成するインデックスは制約側で表現済みなので除く
    if (table.constraintIndexNames.has(row.index_name)) continue;
    table.indexes.push({
      name: row.index_name,
      isUnique: row.is_unique,
      definition: row.definition,
    });
  }

  return [...byName.values()].sort((a, b) => a.name.localeCompare(b.name));
}

module.exports = { introspect, formatType };
