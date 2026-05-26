# Claude Code Usage Monitor インストールガイド

## 概要

Claude Code Usage Monitor は、Claude Code の使用状況（トークン使用量、コストなど）をリアルタイムで監視できるツールです。

公式リポジトリ: https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor

## インストール手順

### 前提条件

- `uv` がインストールされていること

```bash
# uv のバージョン確認
uv --version
# 例: uv 0.9.8 (85c5d3228 2025-11-07)
```

### インストール

```bash
# Claude Code Usage Monitor のインストール
uv tool install claude-monitor
```

## インストール確認

インストール後、以下のコマンドで確認できます：

```bash
# インストール済みツールの確認
uv tool list
# 出力例:
# claude-monitor v3.1.0
# - ccm
# - ccmonitor
# - cmonitor
# - claude-code-monitor
# - claude-monitor

# バージョン確認
claude-monitor --version
# または
/c/Users/eno49/.local/bin/claude-monitor.exe --version
```

## Windows 環境での PATH 設定

### 実行ファイルの場所

`uv tool install` でインストールされた実行ファイルは以下の場所に配置されます：

- Windows: `C:\Users\{ユーザー名}\.local\bin\claude-monitor.exe`

### PATH に追加されない場合の対処法

#### 方法1: 新しいターミナルセッションを開く（推奨）

`uv tool update-shell` を実行後、新しいターミナルを開くと自動的に PATH が更新されます。

```bash
# PATH の更新（初回のみ）
uv tool update-shell

# 新しいターミナルを開いてから
claude-monitor --version
```

#### 方法2: エイリアスを設定

現在のセッションでも使えるように、`.bashrc` にエイリアスを追加します。

```bash
# .bashrc にエイリアスを追加
echo "" >> ~/.bashrc
echo "# Claude Monitor alias" >> ~/.bashrc
echo "alias claude-monitor='/c/Users/eno49/.local/bin/claude-monitor.exe'" >> ~/.bashrc

# 設定を反映（新しいターミナルを開く）
source ~/.bashrc
```

#### 方法3: フルパスで実行

エイリアスが機能しない場合は、フルパスで実行できます。

```bash
/c/Users/eno49/.local/bin/claude-monitor.exe
```

## 使用方法

### 利用可能なコマンド

Claude Code Usage Monitor は複数のコマンド名で起動できます：

- `claude-monitor` - メインコマンド
- `ccmonitor` - 短縮形
- `cmonitor` - さらに短い形
- `ccm` - 最短形
- `claude-code-monitor` - 完全な名前

### 基本的な使用例

```bash
# ヘルプを表示
claude-monitor --help

# 基本的な起動
claude-monitor

# プランを指定して起動
claude-monitor --plan pro

# リアルタイム表示
claude-monitor --view realtime

# ダークテーマで起動
claude-monitor --theme dark
```

### 主なオプション

| オプション | 説明 | デフォルト |
|-----------|------|-----------|
| `--plan` | プランタイプ (pro, max5, max20, custom) | pro |
| `--view` | 表示モード (realtime, daily, monthly, session) | realtime |
| `--theme` | テーマ (light, dark, classic, auto) | auto |
| `--timezone` | タイムゾーン | システムのタイムゾーン |
| `--time-format` | 時刻フォーマット (12h, 24h) | 24h |
| `--refresh-rate` | 更新間隔（秒） | 5 |

### 使用例

```bash
# Pro プランでリアルタイム表示、ダークテーマ
claude-monitor --plan pro --view realtime --theme dark

# 日次表示、更新間隔10秒
claude-monitor --view daily --refresh-rate 10

# カスタムプランでセッション表示
claude-monitor --plan custom --view session
```

## トラブルシューティング

### `command not found` エラーが出る場合

1. **新しいターミナルを開く**
   - `uv tool update-shell` を実行後、新しいターミナルセッションを開いてください。

2. **PATH を確認**
   ```bash
   echo "$PATH" | tr ':' '\n' | grep -i local
   ```
   `C:\Users\{ユーザー名}\.local\bin` が含まれているか確認してください。

3. **フルパスで実行**
   ```bash
   /c/Users/eno49/.local/bin/claude-monitor.exe
   ```

### インストール場所の確認

```bash
# uv のツールディレクトリを確認
uv tool dir
# 例: C:\Users\eno49\AppData\Roaming\uv\tools

# インストール済みツールの確認
uv tool list

# 実行ファイルの場所を確認（Windows Git Bash）
ls -la "/c/Users/eno49/.local/bin/" | grep claude
```

## 参考リンク

- [公式リポジトリ](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor)
- [README - Modern Installation with uv](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor?tab=readme-ov-file#-modern-installation-with-uv-recommended)
