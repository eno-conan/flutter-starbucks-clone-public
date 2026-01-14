#!/bin/bash

# ブランチ名変更スクリプト
# 使い方: ./rename_branch.sh <旧ブランチ名> <新ブランチ名>

# 引数チェック
if [ $# -ne 2 ]; then
    echo "エラー: 引数が不足しています"
    echo "使い方: $0 <旧ブランチ名> <新ブランチ名>"
    echo "例: $0 claude/issue-286-20251206-0049 16KB-memory-page-size"
    exit 1
fi

OLD_BRANCH=$1
NEW_BRANCH=$2

echo "ブランチ名を変更します..."
echo "旧: $OLD_BRANCH"
echo "新: $NEW_BRANCH"
echo ""

# ローカルブランチ名を変更
echo "1. ローカルブランチ名を変更中..."
git branch -m "$OLD_BRANCH" "$NEW_BRANCH"
if [ $? -ne 0 ]; then
    echo "エラー: ローカルブランチの変更に失敗しました"
    exit 1
fi
echo "✓ ローカルブランチの変更完了"

# リモートの旧ブランチを削除
echo "2. リモートの旧ブランチを削除中..."
git push origin --delete "$OLD_BRANCH"
if [ $? -ne 0 ]; then
    echo "エラー: リモートブランチの削除に失敗しました"
    exit 1
fi
echo "✓ リモートの旧ブランチ削除完了"

# 新ブランチをリモートにプッシュ
echo "3. 新ブランチをリモートにプッシュ中..."
git push origin "$NEW_BRANCH"
if [ $? -ne 0 ]; then
    echo "エラー: 新ブランチのプッシュに失敗しました"
    exit 1
fi
echo "✓ 新ブランチのプッシュ完了"

echo ""
echo "すべての処理が完了しました！"