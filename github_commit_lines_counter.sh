#!/bin/bash

# リポジトリ、ユーザー名、期間（日数）を設定
REPO="voyagegroup/media-digital-connect"
USERNAME="no-kawaguchi"
DAYS=180

# 現在の日付と指定日数前の日付を取得
END_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_DATE=$(date -u -d "$DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ")

# 統計情報を初期化
COMMIT_COUNT=0
ADDED_LINES=0
DELETED_LINES=0
CHANGED_LINES=0

# ページネーションのための変数
PAGE=1
PER_PAGE=100

echo "コミット統計の収集中..."

while true; do
  # GitHub API を呼び出してコミットを取得
  RESPONSE=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$REPO/commits?author=$USERNAME&since=$START_DATE&until=$END_DATE&per_page=$PER_PAGE&page=$PAGE")

  # 応答が空の配列の場合、ループを終了
  if [ "$RESPONSE" == "[]" ]; then
    break
  fi

  # このページのコミット数を数える
  PAGE_COMMIT_COUNT=$(echo "$RESPONSE" | jq length)
  COMMIT_COUNT=$((COMMIT_COUNT + PAGE_COMMIT_COUNT))

  # 各コミットの詳細を取得し、統計を計算
  for SHA in $(echo "$RESPONSE" | jq -r '.[].sha'); do
    COMMIT_DETAIL=$(gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/$REPO/commits/$SHA")
    
    COMMIT_ADDED=$(echo "$COMMIT_DETAIL" | jq '.stats.additions')
    COMMIT_DELETED=$(echo "$COMMIT_DETAIL" | jq '.stats.deletions')
    COMMIT_CHANGED=$((COMMIT_ADDED + COMMIT_DELETED))

    ADDED_LINES=$((ADDED_LINES + COMMIT_ADDED))
    DELETED_LINES=$((DELETED_LINES + COMMIT_DELETED))
    CHANGED_LINES=$((CHANGED_LINES + COMMIT_CHANGED))
  done

  # 次のページへ
  PAGE=$((PAGE + 1))
done


# developブランチへのマージ済みPRの一覧を取得（ページネーション対応）
PR_LIST=[]
PAGE=1

while true; do
  PR_PAGE=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$REPO/pulls?state=all&base=develop&creator=$USERNAME&sort=updated&direction=desc&per_page=100&page=$PAGE")

  # ページが空の場合、ループを終了
  if [ "$(echo "$PR_PAGE" | jq length)" -eq 0 ]; then
    break
  fi

  # マージされたPRをフィルタリングし、開始日以降のものだけを保持
  # マージされたPRをフィルタリングし、開始日以降かつ特定のユーザーが作成したものだけを保持
FILTERED_PRS=$(echo "$PR_PAGE" | jq --arg start "$START_DATE" --arg user "$USERNAME" '[.[] | select(.merged_at != null and .merged_at >= $start and .user.login == $user)]')
  
  # 結果をPR_LISTに追加
  PR_LIST=$(echo "$PR_LIST $FILTERED_PRS" | jq -s 'add')

  # 最後のPRが開始日より前の場合、ループを終了
  LAST_PR_DATE=$(echo "$PR_PAGE" | jq -r '.[-1].updated_at')
  if [[ "$LAST_PR_DATE" < "$START_DATE" ]]; then
    break
  fi

  # 次のページへ
  PAGE=$((PAGE + 1))
done

# マージされたPRの数を計算
MERGED_PR_COUNT=$(echo "$PR_LIST" | jq length)

# 結果の出力
echo "ユーザー $USERNAME の過去 $DAYS 日間($START_DATE ~ $END_DATE )の貢献統計:"
echo "コミット数: $COMMIT_COUNT"
echo "追加行数: $ADDED_LINES"
echo "削除行数: $DELETED_LINES"
echo "変更行数: $CHANGED_LINES"
echo "developブランチへのマージ済みPR数: $MERGED_PR_COUNT"

echo -e "\ndevelopブランチへのマージ済みプルリクエスト一覧 (作成者: $USERNAME):"
echo "$PR_LIST" | jq -r '.[] | "タイトル: \(.title)\n  URL: \(.html_url)\n  作成者: \(.user.login)\n  マージ日時: \(.merged_at)\n"'