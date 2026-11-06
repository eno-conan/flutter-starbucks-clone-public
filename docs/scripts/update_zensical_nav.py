#!/usr/bin/env python3
"""
docs/content/ に追加された .md ファイルを zensical.toml の nav に自動登録する。

Usage:
  python update_zensical_nav.py                # 全ファイルをスキャンして未登録エントリを追加
  python update_zensical_nav.py <file_path>    # 特定ファイルのみ処理（絶対パス可）

ディレクトリとセクションのマッピング:
  claude/              → "Claude Code"
  setup/               → "セットアップ"
  development/         → "開発"
  services/            → "サービス連携"
  release/             → "リリース・運用"
  flutter/             → "Flutter"
  architecture/        → "アーキテクチャ"
  security/            → "セキュリティ"
  starbucks_user_side/ → "画面仕様"
  design/              → "設計書"

制限:
  - 2階層以上の深さ（例: starbucks_user_side/signin/*.md、security/owasp-mobile-top-10/*.md）は手動でnavに追加が必要
  - SECTION_MAP に含まれないディレクトリは処理をスキップ
"""
import sys
import os

SECTION_MAP = {
    "claude": "Claude Code",
    "setup": "セットアップ",
    "development": "開発",
    "services": "サービス連携",
    "release": "リリース・運用",
    "flutter": "Flutter",
    "architecture": "アーキテクチャ",
    "security": "セキュリティ",
    "starbucks_user_side": "画面仕様",
    "design": "設計書",
}


def extract_title(filepath: str) -> str:
    """ファイルの最初の H1 見出しをタイトルとして返す。なければファイル名を整形して返す。"""
    try:
        with open(filepath, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("# "):
                    return line[2:].strip()
    except Exception:
        pass
    name = os.path.splitext(os.path.basename(filepath))[0]
    return name.replace("-", " ").replace("_", " ").title()


def is_in_nav(toml_content: str, rel_path: str) -> bool:
    return f'"{rel_path}"' in toml_content


def insert_into_section(toml_content: str, section_name: str, title: str, rel_path: str) -> str:
    """
    section_name のセクション末尾に { "title" = "rel_path" } を追加する。
    ブラケットカウント方式でネストに対応。
    """
    marker = f'{{ "{section_name}" = ['
    start = toml_content.find(marker)
    if start == -1:
        print(f"[update_zensical_nav] Section not found: {section_name}", file=sys.stderr)
        return toml_content

    bracket_open = toml_content.find("[", start)
    if bracket_open == -1:
        return toml_content

    depth = 0
    close_pos = -1
    for i in range(bracket_open, len(toml_content)):
        ch = toml_content[i]
        if ch == "[":
            depth += 1
        elif ch == "]":
            depth -= 1
            if depth == 0:
                close_pos = i
                break

    if close_pos == -1:
        print(f"[update_zensical_nav] Could not find closing ] for section: {section_name}", file=sys.stderr)
        return toml_content

    # ] の直前にある改行を探し、そこに新エントリを挿入
    before_bracket_newline = toml_content.rfind("\n", 0, close_pos)
    new_entry = f'    {{ "{title}" = "{rel_path}" }},\n'
    return toml_content[: before_bracket_newline + 1] + new_entry + toml_content[before_bracket_newline + 1 :]


def process_file(filepath: str, docs_dir: str, toml_content: str) -> tuple[str, bool]:
    filepath = os.path.normpath(filepath)
    docs_dir = os.path.normpath(docs_dir)

    if not filepath.endswith(".md"):
        return toml_content, False

    try:
        rel = os.path.relpath(filepath, docs_dir).replace("\\", "/")
    except ValueError:
        # Windows で別ドライブの場合など
        return toml_content, False

    if is_in_nav(toml_content, rel):
        return toml_content, False

    parts = rel.split("/")
    if len(parts) < 2:
        return toml_content, False

    if len(parts) > 2:
        print(f"[update_zensical_nav] Nested path skipped (add manually to nav): {rel}", file=sys.stderr)
        return toml_content, False

    dir_name = parts[0]
    section = SECTION_MAP.get(dir_name)
    if not section:
        print(f"[update_zensical_nav] No section mapping for directory: {dir_name}", file=sys.stderr)
        return toml_content, False

    title = extract_title(filepath)
    print(f'[update_zensical_nav] Adding: [{section}] "{title}" -> {rel}')
    updated = insert_into_section(toml_content, section, title, rel)
    return updated, True


def main() -> None:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    zensical_dir = os.path.dirname(script_dir)
    docs_dir = os.path.join(zensical_dir, "content")
    toml_path = os.path.join(zensical_dir, "zensical.toml")

    with open(toml_path, encoding="utf-8") as f:
        toml_content = f.read()

    if len(sys.argv) > 1:
        filepath = os.path.abspath(sys.argv[1])
        if not os.path.normpath(filepath).startswith(os.path.normpath(docs_dir)):
            # docs/content/ 外のファイルは無視（ hook から呼ばれた場合）
            return
        files = [filepath]
    else:
        files = []
        for root, dirs, fnames in os.walk(docs_dir):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for fname in fnames:
                if fname.endswith(".md"):
                    files.append(os.path.join(root, fname))

    modified = False
    for fp in files:
        toml_content, changed = process_file(fp, docs_dir, toml_content)
        modified = modified or changed

    if modified:
        with open(toml_path, "w", encoding="utf-8") as f:
            f.write(toml_content)
        print("[update_zensical_nav] zensical.toml updated successfully.")
    else:
        print("[update_zensical_nav] No changes needed.")


if __name__ == "__main__":
    main()
