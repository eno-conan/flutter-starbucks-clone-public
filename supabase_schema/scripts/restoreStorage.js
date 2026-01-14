const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
const mime = require('mime-types');
const { Client } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Environment variables from .env
const SUPABASE_LOCAL_URL = process.env.SUPABASE_LOCAL_URL || 'http://127.0.0.1:54321';
const SERVICE_KEY = process.env.SUPABASE_LOCAL_SERVICE_KEY;
const DB_HOST = process.env.DB_HOST || '127.0.0.1';
const DB_PORT = process.env.DB_PORT || 54322;
const DB_USER = process.env.DB_USER || 'postgres';
const DB_PASSWORD = process.env.DB_PASSWORD || 'postgres';
const DB_NAME = process.env.DB_NAME || 'postgres';
const LOCAL_BUCKET_NAME = process.env.LOCAL_BUCKET_NAME || 'starbucks';

// クライアント初期化（RLSバイパス用）
const supabaseAdmin = createClient(SUPABASE_LOCAL_URL, SERVICE_KEY, {
    auth: {
        autoRefreshToken: false,
        persistSession: false
    }
});

async function createBucketIfNotExists(bucketName) {
    try {
        const { data: existingBucket, error: listError } = await supabaseAdmin
            .storage
            .listBuckets();

        if (listError) throw listError;

        const bucketExists = existingBucket.some(b => b.name === bucketName);

        if (bucketExists) {
            console.log(`Bucket '${bucketName}' already exists`);
            return;
        }

        // allowedMimeTypesを明示的に設定
        const { data: newBucket, error: createError } = await supabaseAdmin
            .storage
            .createBucket(bucketName, {
                public: false,
                allowedMimeTypes: ['image/png'],
                fileSizeLimit: '10MB' // 必要に応じてサイズ制限を調整
            });

        if (createError) throw createError;
        console.log(`Bucket '${bucketName}' created successfully`);
    } catch (error) {
        console.error('Bucket creation error:', error);
        throw error;
    }
}

async function uploadFile(bucketName, filePath, objectPath) {
    const fileContent = fs.readFileSync(filePath);
    const contentType = mime.lookup(filePath) || 'application/octet-stream';

    const { error } = await supabaseAdmin
        .storage
        .from(bucketName)
        .upload(objectPath, fileContent, {
            contentType, // 検出したMIMEタイプを使用
            upsert: true,
            cacheControl: '3600'
        });

    if (error) {
        if (!error.message.includes('already exists')) {
            throw error;
        }
        console.log(`Skipped (exists): ${objectPath}`);
    } else {
        console.log(`Uploaded: ${objectPath} (${contentType})`);
    }
}

async function restoreStorage() {
    const bucketName = LOCAL_BUCKET_NAME;
    const backupDir = path.join(__dirname, '../storage_backup');

    try {
        // バケット作成
        await createBucketIfNotExists(bucketName);

        if (!fs.existsSync(backupDir)) {
            console.log('No backup found to restore');
            return;
        }

        const processDirectory = async (directory, relativePath = '') => {
            const items = fs.readdirSync(directory, { withFileTypes: true });

            for (const item of items) {
                const fullPath = path.join(directory, item.name);
                const objectPath = path.join(relativePath, item.name)
                    .replace(/\\/g, '/') // Windowsパス対策
                    .replace(/\/+/g, '/'); // 連続スラッシュを修正

                if (item.isDirectory()) {
                    await processDirectory(fullPath, objectPath);
                } else {
                    await uploadFile(bucketName, fullPath, objectPath);
                }
            }
        };

        await processDirectory(backupDir);
        console.log('🎉 Storage restore completed successfully!');

    } catch (error) {
        console.error('❌ Restore failed:', error);
        process.exit(1);
    }
}

restoreStorage();