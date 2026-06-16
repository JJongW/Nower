#!/bin/bash
#
# bump-build.sh — iOS 빌드 번호 자동 증가
#
# CURRENT_PROJECT_VERSION 을 git 커밋 수로 설정한다.
# - 앱 타겟과 위젯 익스텐션이 같은 설정을 읽으므로 두 번들의 CFBundleVersion 이 자동 일치한다.
#   (App Store 는 앱/익스텐션 CFBundleVersion 일치를 요구함)
# - 커밋 수는 단조 증가하므로 "Redundant Binary Upload" (code 90189) 가 재발하지 않는다.
#
# 사용법: Xcode 에서 Archive 하기 직전에 한 번 실행.
#   ./Nower-iOS/scripts/bump-build.sh
#
# 같은 커밋에서 두 번 업로드해야 하면 빈 커밋을 하나 더 만들면 된다:
#   git commit --allow-empty -m "chore: bump build"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PBXPROJ="$SCRIPT_DIR/../Nower-iOS.xcodeproj/project.pbxproj"

if [[ ! -f "$PBXPROJ" ]]; then
  echo "error: project.pbxproj 를 찾을 수 없음: $PBXPROJ" >&2
  exit 1
fi

BUILD_NUMBER="$(git -C "$SCRIPT_DIR" rev-list --count HEAD)"

# 모든 CURRENT_PROJECT_VERSION = N; 을 커밋 수로 치환 (앱 4 + 위젯 4)
sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9]+;/CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};/g" "$PBXPROJ"

COUNT="$(grep -c "CURRENT_PROJECT_VERSION = ${BUILD_NUMBER};" "$PBXPROJ")"
echo "빌드 번호 → ${BUILD_NUMBER} (설정 ${COUNT}곳 갱신)"
echo "변경된 pbxproj 를 커밋한 뒤 Archive 하세요."
