const fs = require('fs');
const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

/**
 * PostgreSQLデータベースにSQLファイルを読み込んで実行する関数
 * @param {string} dbUrl - PostgreSQL接続URL
 * @param {string} sqlFilePath - 実行するSQLファイルのパス
 */
async function executeSqlFile(dbUrl, sqlFilePath) {
    // SQLファイルの存在確認
    if (!fs.existsSync(sqlFilePath)) {
        console.error(`SQLファイルが見つかりません: ${sqlFilePath}`);
        process.exit(1);
    }

    console.log(`SQLファイルを読み込んでいます: ${path.basename(sqlFilePath)}`);

    // SQLファイルを読み込む
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');

    // PostgreSQL接続プールを作成
    const pool = new Pool({
        connectionString: dbUrl
    });

    try {
        console.log('データベースに接続しています...');

        // クエリを実行
        console.log('SQLを実行しています...');
        const result = await pool.query(sqlContent);

        console.log('SQLファイルの実行が完了しました');
        // console.log(`影響を受けた行数: ${result.rowCount || '不明'}`);

        return result;
    } catch (error) {
        console.error('SQLファイルの実行中にエラーが発生しました:', error.message);
        throw error;
    } finally {
        // プールを終了して接続をクリーンアップ
        await pool.end();
        console.log('データベース接続を終了しました');
    }
}

// __dirnameを使用して現在のスクリプトのディレクトリを取得
const currentDir = __dirname;
const sqlFileName = process.env.SQL_FILE_NAME || 'starbucks_bucket_policy.sql';
const sqlFilePath = path.join(currentDir, sqlFileName);

// 使用例
async function main() {
    const dbHost = process.env.DB_HOST || '127.0.0.1';
    const dbPort = process.env.DB_PORT || 54322;
    const dbUser = process.env.DB_USER || 'postgres';
    const dbPassword = process.env.DB_PASSWORD || 'postgres';
    const dbName = process.env.DB_NAME || 'postgres';

    const dbUrl = process.env.DATABASE_URL ||
        `postgresql://${dbUser}:${dbPassword}@${dbHost}:${dbPort}/${dbName}`;

    console.log(`検索しているSQLファイルのパス: ${sqlFilePath}`);

    try {
        // ディレクトリの内容を確認して出力
        // console.log('ディレクトリの内容:');
        const files = fs.readdirSync(currentDir);
        files.forEach(file => {
            // console.log(` - ${file}`);
        });

        // ファイルが存在するか確認
        if (files.includes(path.basename(sqlFilePath))) {
            await executeSqlFile(dbUrl, sqlFilePath);
            console.log('処理が正常に完了しました');
        } else {
            console.error(`${path.basename(sqlFilePath)}がディレクトリ内に見つかりません。`);
            process.exit(1);
        }
    } catch (error) {
        console.error('エラーが発生しました:', error);
        process.exit(1);
    }
}

// スクリプトが直接実行された場合に実行
if (require.main === module) {
    main();
}

module.exports = { executeSqlFile };