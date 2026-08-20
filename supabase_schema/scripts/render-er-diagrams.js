#!/usr/bin/env node
'use strict';

/**
 * entity_relationship/*.mmd を SVG に変換する。
 *
 *   node scripts/render-er-diagrams.js
 *
 * mermaid-cli は Puppeteer 経由で Chromium を使う。
 * CI などで別の Chromium を使わせたい場合は PUPPETEER_EXECUTABLE_PATH を設定する。
 */

const { execFileSync, execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const CONFIG_PATH = path.join(__dirname, 'schema-doc-config.json');
const IS_WINDOWS = process.platform === 'win32';

/** shell 経由で起動する Windows 用に、空白などを含む引数を括る。 */
function quoteForShell(arg) {
  return /[\s&|<>^"]/.test(arg) ? `"${arg}"` : arg;
}

/**
 * ER_README.md 記載のとおり mermaid-cli は PK_FK のような複合制約を解釈できない。
 * 生成側では出さないが、手で編集された .mmd を SVG 化する前にも一応止める。
 */
function assertNoCompositeConstraint(file) {
  const text = fs.readFileSync(file, 'utf8');
  const line = text.split('\n').findIndex((l) => /\bPK[_,]FK\b/.test(l));
  if (line !== -1) {
    throw new Error(
      `${path.basename(file)}:${line + 1} に複合制約 (PK_FK) があります。` +
        'mermaid-cli が解釈できないため FK のみに直してください。'
    );
  }
}

function main() {
  const config = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  const erDir = path.join(ROOT, config.output.erDir);

  // mermaid-cli は Chromium を同梱せず起動時に解決する。
  // Playwright 等が用意した Chromium があればそれを使う。
  const env = { ...process.env };
  if (!env.PUPPETEER_EXECUTABLE_PATH && env.CHROME_PATH) {
    env.PUPPETEER_EXECUTABLE_PATH = env.CHROME_PATH;
  }

  const puppeteerConfig = path.join(erDir, '.puppeteer.json');
  fs.writeFileSync(puppeteerConfig, JSON.stringify({ args: ['--no-sandbox', '--disable-gpu'] }, null, 2));

  const diagrams = config.erDiagrams.map((d) => d.name);
  let failed = 0;
  try {
    for (const name of diagrams) {
      const mmd = path.join(erDir, `${name}.mmd`);
      if (!fs.existsSync(mmd)) {
        console.error(`  スキップ ${name}.mmd (未生成)`);
        failed += 1;
        continue;
      }
      assertNoCompositeConstraint(mmd);
      const svg = path.join(erDir, `${name}.svg`);
      const args = ['--yes', '@mermaid-js/mermaid-cli', '-i', mmd, '-o', svg, '-p', puppeteerConfig, '-b', 'white'];
      const options = { stdio: ['ignore', 'ignore', 'inherit'], env, cwd: ROOT };
      if (IS_WINDOWS) {
        // Windows の npx は npx.cmd で、Node は .cmd を shell 経由でしか起動できない
        // (shell を介さないと ENOENT / EINVAL になる)。
        // shell では引数が展開されるため、空白などを含むパスは自前で括ってから 1本の文字列で渡す。
        execSync(['npx.cmd', ...args].map(quoteForShell).join(' '), options);
      } else {
        execFileSync('npx', args, options);
      }
      console.log(`  生成 ${path.relative(ROOT, svg)}`);
    }
  } finally {
    fs.rmSync(puppeteerConfig, { force: true });
  }

  if (failed > 0) {
    console.error('\n.mmd が不足しています。先に `npm run schema:docs` を実行してください。');
    process.exit(1);
  }
  console.log(`\n${diagrams.length}件のER図をSVGへ変換しました。`);
}

try {
  main();
} catch (error) {
  console.error(`\n${error.message}\n`);
  process.exit(1);
}
