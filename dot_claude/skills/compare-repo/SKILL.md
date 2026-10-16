---
name: compare-repo
description: 現在のリポジトリとリファレンスのリポジトリを比べ、構成や共通ファイルの差分を分類して報告する（読み取り専用）。兄弟リポジトリをリファレンスに揃える作業の前や、リポジトリ間の差分の確認を頼まれたときに使う。
argument-hint: <reference-repository>
allowed-tools: Read, Glob, Grep, Bash
context: fork
agent: Explore
---

# Compare Repo

ローカルのパスで渡されたリファレンス（$ARGUMENTS）と現在のリポジトリを比べ、差分を報告する。ファイルは変更しない。

## スクリプト

このファイルと同じディレクトリにある次のスクリプトを、絶対パスで直接実行する（`bash` を前に付けない）。`<dir1>` はリファレンス、`<dir2>` は現在のリポジトリ。どちらのスクリプトも `fd` を使うので、見つからない場合はその旨を報告して止まる。

- `compare-structure.sh <dir1> <dir2> <path>...`：各パスの直下にあるエントリを、片方にだけあるものと共通のものに分けて一覧する
- `diff-files.sh <dir1> <dir2> <path>...`：ファイル、またはディレクトリ配下の共通ファイルの差分と、片方にだけあるファイルを出力する

## 手順

1. `compare-structure.sh <dir1> <dir2> .` でトップレベルの構成を比べ、全体像をつかむ
2. 次の対象を `compare-structure.sh` で掘り下げ、`diff-files.sh` で内容の差分を取る
   - Makefile：ターゲット名、`##` のコメント、依存関係
   - `tools/` のスクリプト
   - コンテナ関連のファイル（Dockerfile、compose.yamlなど）
   - GitHub Actionsのワークフロー（`.github/workflows/`）
   - lintの設定ファイル（`.markdownlint.json`など）
   - AGENTS.md
   - ルート直下のシェルスクリプト
3. 必要に応じてRead、Glob、Grepで詳しく調べる

## ルール

- Bashは上の2つのスクリプトにだけ使う
- 報告に徹し、変更するかどうかの判断はユーザーに委ねる
- プロジェクト固有の事情による差異は、その旨を注記する

## 出力

1. 対象ごとの差分レポート
2. 最後に「推奨事項」として、差分を次のように分類する
   - (a) 現在のリポジトリがリファレンスに揃えるべきもの
   - (b) プロジェクト固有で、揃えなくてよいもの
   - (c) 任意の改善
   - リファレンスへ反映する候補（現在のリポジトリが先行しているもの）
