---
description: GitHub Actions のバージョン指定ルール（バージョンを推測しない）
paths:
  - ".github/workflows/**"
  - ".github/dependabot.yml"
---

# GitHub Actions のバージョン指定

## 原則

**アクションのバージョンを学習知識から推測して書かない。必ず実際のタグを確認する。**

これは Claude 固有の事故です。人間は既存のワークフローからコピーするか公式ドキュメントを見るため、
「学習時点では最新だったバージョン」を書いてしまうのは Claude 側に偏った失敗の仕方です。
古いメジャーを書くと、ランナーの Node.js 廃止警告や、いずれ実行そのものの失敗に繋がります。

## 確認方法

新しくワークフローを書くとき、既存のワークフローにアクションを追加するときは、
**ファイルを書く前に**次のコマンドで最新メジャータグを確認してください。

```bash
git ls-remote --tags --refs https://github.com/<owner>/<repo> \
  | sed 's#.*refs/tags/##' | grep -E '^v[0-9]+$' | sort -V | tail -3
```

複数まとめて確認する場合:

```bash
for a in actions/checkout actions/setup-node actions/cache actions/upload-artifact; do
  latest=$(git ls-remote --tags --refs https://github.com/$a \
    | sed 's#.*refs/tags/##' | grep -E '^v[0-9]+$' | sed 's/^v//' | sort -n | tail -1)
  printf "%-32s v%s\n" "$a" "$latest"
done
```

### 注意

- **アクションごとにメジャーの進み方が違う**。「全部同じ番号」と決めつけない
  （実例: 2026年8月時点で `actions/checkout` は v7 だが `actions/cache` は v6）
- リポジトリ内の別のワークフローからコピーする場合も、そのファイル自体が古い可能性がある。
  コピー元を信用せず確認する
- サードパーティ製アクションの major 更新は破壊的変更を含みうる。
  必要に迫られていないなら自分で上げず、Dependabot のPRに任せてレビューする

## 継続的な追従は Dependabot の担当

バージョンの追従そのものは `.github/dependabot.yml` の `github-actions` エコシステムが行います。
人間にも Claude にも等しく効くため、こちらが本来の防波堤です。

このルールが担うのは「Claude が新規に書く瞬間に古い値を書かない」ことだけで、
既存ワークフローの定期的な更新をここでやろうとしないでください。

- `actions/*`（GitHub公式）: major でもまとめて1つのPR
- サードパーティ製: minor/patch はまとめ、major は個別PR
- patch / minor は `dependabot-automerge.yml` が自動マージする

Dependabot が上げたバージョンを、確認せずに手で書き戻さないこと。

## 関連

- 層の考え方: `.claude/rules/quality-gate-layers.md`
