import { createClient } from 'npm:@supabase/supabase-js@2'

// Issue#544: アーカイブデータを Storage へエクスポートする Edge Function
// 呼び出し元: pg_cron → trigger_export_archive_to_storage() → net.http_post()
//
// 処理概要:
//   当日 archived_at のアーカイブレコードを各テーブルから取得し、
//   JSONL 形式で Storage バケット "archives" にアップロードする。
//   同日再実行時は上書き（upsert: true）する。
//
// Storage パス:
//   archives/{table_name}/{YYYY_MM_DD}.jsonl

interface UploadResult {
  table: string
  path: string
  row_count: number
}

const ARCHIVE_TABLES = [
  'orders_archive',
  'orders_detail_archive',
  'star_acquisitions_archive',
  'star_usage_archive',
] as const

type ArchiveTable = typeof ARCHIVE_TABLES[number]

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
)

Deno.serve(async (_req) => {
  const today = new Date()
  const dateLabel = formatDateLabel(today)

  const uploadedFiles: UploadResult[] = []

  for (const tableName of ARCHIVE_TABLES) {
    const result = await exportTableToStorage(tableName, dateLabel)
    uploadedFiles.push(result)
  }

  return new Response(
    JSON.stringify({ date: dateLabel, uploaded_files: uploadedFiles }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})

async function exportTableToStorage(
  tableName: ArchiveTable,
  dateLabel: string
): Promise<UploadResult> {
  const storagePath = `${tableFolder(tableName)}/${dateLabel}.jsonl`

  const { data, error } = await supabase
    .from(tableName)
    .select('*')
    .filter('archived_at', 'gte', `${dateLabel}T00:00:00+00:00`)
    .filter('archived_at', 'lt', nextDayIso(dateLabel))

  if (error) {
    console.error(`Failed to fetch ${tableName}:`, error)
    throw new Error(`Failed to fetch ${tableName}: ${error.message}`)
  }

  const rows = data ?? []
  const jsonl = rows.map((row) => JSON.stringify(row)).join('\n')
  const blob = new Blob([jsonl], { type: 'application/x-ndjson' })

  const { error: uploadError } = await supabase.storage
    .from('archives')
    .upload(storagePath, blob, {
      contentType: 'application/x-ndjson',
      upsert: true,
    })

  if (uploadError) {
    console.error(`Failed to upload ${storagePath}:`, uploadError)
    throw new Error(`Failed to upload ${storagePath}: ${uploadError.message}`)
  }

  return { table: tableName, path: storagePath, row_count: rows.length }
}

// YYYY_MM_DD 形式の日付文字列を生成
function formatDateLabel(date: Date): string {
  const yyyy = date.getUTCFullYear()
  const mm = String(date.getUTCMonth() + 1).padStart(2, '0')
  const dd = String(date.getUTCDate()).padStart(2, '0')
  return `${yyyy}_${mm}_${dd}`
}

// archived_at フィルター用: 翌日の ISO 文字列を生成
function nextDayIso(dateLabel: string): string {
  // YYYY_MM_DD → YYYY-MM-DD
  const iso = dateLabel.replace(/_/g, '-')
  const next = new Date(`${iso}T00:00:00Z`)
  next.setUTCDate(next.getUTCDate() + 1)
  return next.toISOString()
}

// テーブル名から Storage フォルダ名へのマッピング
function tableFolder(tableName: ArchiveTable): string {
  const map: Record<ArchiveTable, string> = {
    orders_archive: 'orders',
    orders_detail_archive: 'orders_detail',
    star_acquisitions_archive: 'star_acquisitions',
    star_usage_archive: 'star_usage',
  }
  return map[tableName]
}
