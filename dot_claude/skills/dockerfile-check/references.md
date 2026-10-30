# 根拠

dockerfile-checkのチェックリストの根拠。SKILL.mdのチェックリストを変えるときは、このファイルも合わせて更新する。

## 出典

1. [Best practices | Docker Docs](https://docs.docker.com/build/building/best-practices/)
2. [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
3. [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
4. [Top 20 Dockerfile best practices | Sysdig](https://www.sysdig.com/learn-cloud-native/dockerfile-best-practices)
5. [OCI Image Format annotations](https://github.com/opencontainers/image-spec/blob/main/annotations.md)

## チェックリストの根拠

- 軽量なイメージ [1]
- 信頼できるベース・イメージ [2,3]: hadolintのDL3026 (`--trusted-registry`)はレジストリ単位で信頼するため、docker.ioの公式イメージと任意のユーザーのイメージを区別できない
- マルチ・ステージ・ビルド [1,4]
- キャッシュのための命令の順序 [1]
- .dockerignore [1]: hadolintはDockerfileしか読まない
- 不要なパッケージ [2,4]
- apt-get updateとinstallを同じRUNで実行する [1,2]: 分けて書いてもhadolintは専用のルールで警告しない
- root以外のUSER [1,2,3,4]: 「非rootで実行する」と「専用ユーザーを作る」を統合した。hadolintのDL3002が検出するのは最後のUSERが明示的にrootの場合だけで、USERがないことは検出しない。また、distrolessのように非rootユーザーを用意済みのベース・イメージもある
- シークレット [2]: hadolintのDL3064が検出するのは機密らしい名前のENV/ARGだけで、イメージにコピーされたシークレットのファイルは検出しない
- setuid/setgid [2]: rootで動くコンテナでは削除しても意味がなく、実行時の `no-new-privileges` はすべてのバイナリでsetuidによる昇格を防ぐ。そのため、これを設定していない非rootの常駐サービスにだけ当てはまる
- EXPOSE [1]: ポートを文書化する。hadolintのDL3011はポート番号の範囲しか確認しない
- OCIラベル [4,5]: `revision` でイメージからコミットをたどれる。GitHub Container Registryは `source` でパッケージをリポジトリに結び付ける。ラベルはベース・イメージから引き継がれるため、`source` を設定しないとベース・イメージのリポジトリを示すことがある

## hadolintに任せた項目

hadolintが既定で検出するため、チェックリストから外した。

- ベース・イメージのバージョンを固定する: DL3006、DL3007
- ADDではなくCOPYを使う: DL3020
- パイプを含むRUNの前に `-o pipefail` を設定する: DL4006
- `--no-install-recommends` を使う: DL3015
- aptのリストを削除する: DL3009
- `cd` ではなくWORKDIRを使う: DL3003
- CMDとENTRYPOINTはexec形式で書く: DL3025
- レイヤーを減らす: DL3059 (連続するRUN)
