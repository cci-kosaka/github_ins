# GitHub Repositoryのアクティビティ分析スクリプト

GitHubリポジトリの半年間のアクティビティを分析するBashスクリプト。

## 機能

### Repository全体の以下情報を取得
- 総コミット数
- 追加/削除/変更行数
- マージされたPR数
- リリース回数

### Repository内の各ユーザーの以下情報を取得
- コミット数
- 追加/削除/変更行数
- developブランチへのマージ済みPR数

## 必要条件

- [GitHub CLI (gh)](https://cli.github.com/)
- [jq](https://stedolan.github.io/jq/)

## 使用方法

1. リポジトリをクローン
2. スクリプトに実行権限を付与: `chmod +x github_repo_activity_analyzer.sh`
3. スクリプトに実行権限を付与: `chmod +x github_repo_activity_analyzer.sh`
4. 必要に応じて`REPO`と`DAYS`変数を編集
. 実行: `./github_repo_activity_analyzer.sh`

## 注意

大規模リポジトリの場合、実行に時間がかかることがあります。

## ライセンス

MIT