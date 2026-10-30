---
name: dockerfile-check
description: Dockerfileをセキュリティとパフォーマンスのベスト・プラクティスに照らしてチェックする。Dockerfileを作成・変更したときや、レビューを頼まれたときに使う。
---

# Dockerfileのベスト・プラクティス・チェック

1. Dockerfileに対してhadolintを実行する。プロジェクトに `make hadolint` があればそれを使い、なければ `hadolint` を直接実行する。
2. 以下のチェックリストに照らしてDockerfileを確認する。チェックリストはhadolintが検出しない項目だけに絞ってある。Dockerfile以外のファイルで判断する項目は、各項目に書かれたファイルを読む。

## チェックリスト

### ベース・イメージ

- 軽量なイメージ(slim/alpine/distroless/Chainguard)を使う
- ベース・イメージはDocker Official Images、Verified Publisher、またはベンダー自身のレジストリのものを使う

### ビルドの最適化

- マルチ・ステージ・ビルドを使う
- 変更頻度の低い命令から順に並べる(キャッシュの最適化)
- .dockerignoreを用意する

### パッケージ管理

- 不要なパッケージを入れない
- apt-get updateとinstallを同じRUNで実行する

### セキュリティ

- 最終ステージをroot以外のUSERで実行する
- シークレットをイメージに埋め込まない。ビルド時のシークレットは `RUN --mount=type=secret` で渡す
- 最終ステージがroot以外のユーザーで動く常駐サービスで、リポジトリ内の実行時の設定(composeファイルや実行コマンド)が `no-new-privileges` を設定していない場合は、setuid/setgidビットを削除する

### 設定

- サービスが待ち受けるポートをEXPOSEで宣言する
- `org.opencontainers.image.revision` をビルド引数から設定する。CIのワークフローやMakefileがイメージをレジストリにpushしている場合は、`org.opencontainers.image.source` も設定する。その他のOCIラベルは任意

## 出力形式

hadolintの結果とチェックリストの各項目を1つの表にまとめる。このイメージに当てはまらない項目は、理由を添えて「該当なし」とする。問題があれば改善案を示す。

## 根拠

項目をチェックする理由やしない理由を聞かれたら、このスキルのディレクトリにある `references.md` を読んで答える。
