---
name: find-next-work
description: ローカルのリポジトリから未commit、未push、stash、TODOを集め、TODOの待ち条件が満たされたかを確かめて、次に取りかかれる作業を報告する(fetch以外でリポジトリを変更しない)。
argument-hint: "[root-directory]"
disable-model-invocation: true
---

# Find Next Work

引数: $ARGUMENTS

1. このファイルと同じディレクトリにある `scan.sh $ARGUMENTS` を実行する。失敗したら理由を伝えて止まる。対象のリポジトリと出力の形式はスクリプト冒頭のコメントを参照する。
2. `todo-file` のTODO.mdと `todo-comment` の行を読み、見出しや説明文などTODOではないものを除く。
3. 待ち条件のある項目は、条件が満たされたかを確かめる。パッケージの公開状況、issueの状態、ローカルのバージョンなど、できるだけ軽い方法で調べ、調べた事実と推測を分けて書く。
4. ファイルは変更しない。動かして確かめる必要がある項目は、そのリポジトリのセッションへの引き継ぎ事項をまとめるところまでにする。
5. 次の3つに分けて報告する。
   - 今取りかかれるもの: uncommitted、ahead、behind、no-upstream、stash、待ち条件のないTODO、待ち条件が満たされたTODO
   - 待ち状態のもの: 何を待っているかと確認した結果
   - 確認した範囲: リポジトリの数、`clean` だったもの、`fetch-failed` だったもの
