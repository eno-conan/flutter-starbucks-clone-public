const { S3Client, ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

require('dotenv').config({ path: path.join(__dirname, '.env') });

// S3設定を環境変数から読み込む
const S3_ENDPOINT = process.env.S3_ENDPOINT || 'http://127.0.0.1:54321/storage/v1/s3';
const S3_REGION = process.env.S3_REGION || 'local';
const S3_LOCAL_ACCESS_KEY = process.env.S3_LOCAL_ACCESS_KEY || '';
const S3_LOCAL_SECRET_KEY = process.env.S3_LOCAL_SECRET_KEY || '';
const LOCAL_BUCKET_NAME = process.env.LOCAL_BUCKET_NAME || 'starbucks';
const BACKUP_PATH = process.env.BACKUP_PATH || path.join(__dirname, '../storage_backup');

const client = new S3Client({
    endpoint: S3_ENDPOINT,
    region: S3_REGION,
    credentials: {
        accessKeyId: S3_LOCAL_ACCESS_KEY,
        secretAccessKey: S3_LOCAL_SECRET_KEY
    },
    forcePathStyle: true
});

// ユーザー入力を取得するための関数
function askQuestion(query) {
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    return new Promise(resolve => rl.question(query, ans => {
        rl.close();
        resolve(ans);
    }));
}

async function backupStorage() {
    const backupDir = BACKUP_PATH;
    if (!fs.existsSync(backupDir)) {
        fs.mkdirSync(backupDir, { recursive: true });
    }

    try {
        const listParams = { Bucket: LOCAL_BUCKET_NAME };

        try {
            const data = await client.send(new ListObjectsV2Command(listParams));

            if (!data.Contents || data.Contents.length === 0) {
                console.log(`バケット '${LOCAL_BUCKET_NAME}' は空です。バックアップするものがありません。`);
                return;
            }

            console.log(`バケット '${LOCAL_BUCKET_NAME}' から ${data.Contents.length} 個のオブジェクトをバックアップします...`);

            for (const item of data.Contents) {
                const getParams = { Bucket: LOCAL_BUCKET_NAME, Key: item.Key };
                const fileData = await client.send(new GetObjectCommand(getParams));

                // ここでパス変換を追加
                const safeKey = item.Key.replace(/\\/g, '/');
                const filePath = path.join(backupDir, safeKey);
                const dirname = path.dirname(filePath);

                if (!fs.existsSync(dirname)) {
                    fs.mkdirSync(dirname, { recursive: true });
                }

                const writeStream = fs.createWriteStream(filePath);
                fileData.Body.pipe(writeStream);

                // Promiseを返して完了を追跡
                await new Promise((resolve, reject) => {
                    writeStream.on('finish', () => {
                        console.log(`Backed up: ${safeKey}`);
                        resolve();
                    });
                    writeStream.on('error', (err) => {
                        console.error(`Error backing up ${safeKey}:`, err);
                        reject(err);
                    });
                });
            }
        } catch (error) {
            // バケットが存在しないなどのエラーの場合
            console.error(`バケットアクセス中にエラーが発生しました:`, error.message);

            // ユーザーに確認
            const answer = await askQuestion('現在のバックアップフォルダの内容を適用しますか？ (y/n): ');

            if (answer.toLowerCase() === 'y') {
                console.log('バックアップフォルダの内容を適用します。処理を正常終了します。');
                return;
            } else {
                throw new Error('ユーザーが操作をキャンセルしました。');
            }
        }

    } catch (error) {
        console.error(`バックアップ時にエラーが発生しました:`, error);
        throw error;
    }

    console.log('🎉 Storage backup completed successfully!');
}

// スクリプトが直接実行された場合に実行
if (require.main === module) {
    backupStorage().catch(error => {
        console.error('❌ Backup failed:', error);
        process.exit(1);
    });
}

module.exports = { backupStorage };