#!/bin/bash

# リポジトリ、期間（日数）を設定
REPO="voyagegroup/media-digital-connect"
DAYS=180

# 現在の日付と指定日数前の日付を取得
END_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_DATE=$(date -u -d "$DAYS days ago" +"%Y-%m-%dT%H:%M:%SZ")

# 統計情報を初期化
TOTAL_COMMITS=0
TOTAL_ADDITIONS=0
TOTAL_DELETIONS=0
TOTAL_CHANGES=0
MERGED_PRS=0
RELEASES=0

echo "リポジトリ全体の統計情報を収集中..."

# コミット統計の取得
PAGE=1
while true; do
  COMMITS=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$REPO/commits?since=$START_DATE&until=$END_DATE&per_page=100&page=$PAGE")

  COMMIT_COUNT=$(echo "$COMMITS" | jq length)
  if [ "$COMMIT_COUNT" -eq 0 ]; then
    break
  fi

  TOTAL_COMMITS=$((TOTAL_COMMITS + COMMIT_COUNT))

  for SHA in $(echo "$COMMITS" | jq -r '.[].sha'); do
    COMMIT_DETAIL=$(gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/$REPO/commits/$SHA")
    
    ADDITIONS=$(echo "$COMMIT_DETAIL" | jq '.stats.additions')
    DELETIONS=$(echo "$COMMIT_DETAIL" | jq '.stats.deletions')
    
    TOTAL_ADDITIONS=$((TOTAL_ADDITIONS + ADDITIONS))
    TOTAL_DELETIONS=$((TOTAL_DELETIONS + DELETIONS))
  done

  PAGE=$((PAGE + 1))
done

TOTAL_CHANGES=$((TOTAL_ADDITIONS + TOTAL_DELETIONS))

# マージされたPR数の取得
PAGE=1
while true; do
  PRS=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/$REPO/pulls?state=closed&base=develop&sort=updated&direction=desc&per_page=100&page=$PAGE")

  PR_COUNT=$(echo "$PRS" | jq '[.[] | select(.merged_at != null and .merged_at >= "'"$START_DATE"'" and .merged_at <= "'"$END_DATE"'")]' | jq length)
  if [ "$PR_COUNT" -eq 0 ]; then
    break
  fi

  MERGED_PRS=$((MERGED_PRS + PR_COUNT))
  PAGE=$((PAGE + 1))
done

# リリース数の取得
RELEASES=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/$REPO/releases?per_page=100" | \
  jq '[.[] | select(.published_at >= "'"$START_DATE"'" and .published_at <= "'"$END_DATE"'")]' | \
  jq length)

# 結果の出力
echo "リポジトリ $REPO の過去 $DAYS 日間のアクティビティ統計:"
echo "総コミット数: $TOTAL_COMMITS"
echo "追加行数: $TOTAL_ADDITIONS"
echo "削除行数: $TOTAL_DELETIONS"
echo "変更行数: $TOTAL_CHANGES"
echo "マージされたPR数: $MERGED_PRS"
echo "リリース回数: $RELEASES"