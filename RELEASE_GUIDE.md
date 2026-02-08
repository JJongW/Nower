# 릴리즈 관리 가이드

## 목차
1. [버전 관리 전략](#버전-관리-전략)
2. [브랜치 전략](#브랜치-전략)
3. [릴리즈 프로세스](#릴리즈-프로세스)
4. [핫픽스 프로세스](#핫픽스-프로세스)
5. [커밋 메시지 컨벤션](#커밋-메시지-컨벤션)

## 버전 관리 전략

Nower 프로젝트는 **Semantic Versioning 2.0.0**을 따릅니다.

### 버전 형식
```
v주.부.수 (vMAJOR.MINOR.PATCH)
```

### 버전 업데이트 규칙
- **MAJOR (주)**: API 변경이나 하위 호환성이 깨지는 변경
  - 예: `v1.0.0` → `v2.0.0`
- **MINOR (부)**: 하위 호환성을 유지하는 새 기능 추가
  - 예: `v1.0.0` → `v1.1.0`
- **PATCH (수)**: 하위 호환성을 유지하는 버그 수정
  - 예: `v1.0.0` → `v1.0.1`

### 사전 릴리즈 버전
- **알파**: `v1.0.0-alpha.1`
- **베타**: `v1.0.0-beta.1`
- **RC**: `v1.0.0-rc.1`

## 브랜치 전략

### 주요 브랜치

#### `main`
- **역할**: 프로덕션 코드
- **특징**: 항상 배포 가능한 상태
- **보호**: 직접 푸시 금지, PR 필수

#### `develop` (선택사항)
- **역할**: 개발 통합 브랜치
- **특징**: 다음 릴리즈 준비
- **사용**: 여러 기능을 동시 개발할 때

### 보조 브랜치

#### Feature 브랜치
```bash
feature/기능명
```
- **용도**: 새로운 기능 개발
- **생성 기준**: `main` 또는 `develop`
- **머지 대상**: `main` 또는 `develop`
- **삭제**: 머지 후 삭제

**예시:**
```bash
feature/calendar-improvement
feature/widget-enhancement
feature/sync-optimization
```

#### Hotfix 브랜치
```bash
hotfix/버전명
```
- **용도**: 프로덕션 긴급 버그 수정
- **생성 기준**: 해당 릴리즈 태그 (예: `v1.0.0`)
- **머지 대상**: `main` (및 `develop`)
- **삭제**: 머지 후 삭제

**예시:**
```bash
hotfix/1.0.1
hotfix/critical-crash-fix
```

#### Release 브랜치
```bash
release/버전명
```
- **용도**: 릴리즈 준비 (버전 번호 업데이트, 최종 테스트)
- **생성 기준**: `develop` 또는 `main`
- **머지 대상**: `main`
- **삭제**: 머지 후 삭제

**예시:**
```bash
release/1.1.0
```

## 릴리즈 프로세스

### 1. 기능 개발

```bash
# Feature 브랜치 생성
git checkout -b feature/new-feature main

# 개발 및 커밋
git add .
git commit -m "feat: 새로운 기능 추가"

# 푸시 및 PR 생성
git push origin feature/new-feature
```

GitHub에서 Pull Request 생성:
- 제목: `feat: 새로운 기능 추가`
- 설명: 변경사항, 테스트 방법 등 상세히 기술
- 리뷰어 지정 (팀 프로젝트의 경우)

### 2. 릴리즈 준비

```bash
# Release 브랜치 생성
git checkout -b release/1.1.0 main

# CHANGELOG.md 업데이트
# - [Unreleased] 섹션의 내용을 새 버전으로 이동
# - 날짜 추가
# - 링크 업데이트

# 버전 번호 업데이트 (필요시)
# - Info.plist의 CFBundleShortVersionString
# - xcconfig 파일

# 커밋
git add .
git commit -m "chore: bump version to 1.1.0"

# main에 머지
git checkout main
git merge --no-ff release/1.1.0

# 태그 생성
git tag -a v1.1.0 -m "Release version 1.1.0

주요 변경사항:
- 새로운 기능 A 추가
- UI/UX 개선
- 버그 수정"

# 푸시
git push origin main
git push origin v1.1.0

# 브랜치 삭제
git branch -d release/1.1.0
git push origin --delete release/1.1.0
```

### 3. GitHub Release 생성

태그를 푸시하면 GitHub Actions가 자동으로 Release를 생성합니다.

수동으로 생성하려면:
```bash
gh release create v1.1.0 \
  --title "Nower v1.1.0" \
  --notes-file RELEASE_NOTES.md
```

## 핫픽스 프로세스

프로덕션에서 긴급 버그 발견 시:

```bash
# 1. 문제가 발생한 버전의 태그에서 hotfix 브랜치 생성
git checkout -b hotfix/1.0.1 v1.0.0

# 2. 버그 수정
git add .
git commit -m "fix: 크리티컬 크래시 버그 수정"

# 3. CHANGELOG.md 업데이트
# 4. 버전 번호 업데이트 (1.0.0 → 1.0.1)
git add .
git commit -m "chore: bump version to 1.0.1"

# 5. main에 머지
git checkout main
git merge --no-ff hotfix/1.0.1

# 6. 태그 생성
git tag -a v1.0.1 -m "Hotfix 1.0.1

- 캘린더 크래시 버그 수정"

# 7. 푸시
git push origin main
git push origin v1.0.1

# 8. develop에도 머지 (있다면)
git checkout develop
git merge --no-ff hotfix/1.0.1
git push origin develop

# 9. 브랜치 삭제
git branch -d hotfix/1.0.1
```

## 커밋 메시지 컨벤션

Nower 프로젝트는 **Conventional Commits** 스펙을 따릅니다.

### 형식
```
<타입>(<스코프>): <제목>

<본문>

<푸터>
```

### 타입
- **feat**: 새로운 기능 추가
- **fix**: 버그 수정
- **docs**: 문서 수정
- **style**: 코드 포맷팅, 세미콜론 누락 등 (기능 변경 없음)
- **refactor**: 코드 리팩토링
- **perf**: 성능 개선
- **test**: 테스트 코드 추가/수정
- **chore**: 빌드 프로세스, 도구 설정 변경 등
- **ci**: CI 설정 변경
- **build**: 빌드 시스템 변경

### 예시

#### 기본
```bash
git commit -m "feat: 캘린더 위젯 추가"
```

#### 스코프 포함
```bash
git commit -m "fix(calendar): 날짜 선택 버그 수정"
```

#### 본문 포함
```bash
git commit -m "feat: iCloud 동기화 기능 추가

- CloudSyncManager 구현
- 충돌 해결 로직 추가
- 백그라운드 동기화 지원"
```

#### Breaking Change
```bash
git commit -m "feat!: API 구조 변경

BREAKING CHANGE: TodoItem의 구조가 변경되어 기존 데이터와 호환되지 않습니다."
```

## CHANGELOG.md 관리

### 형식

```markdown
# Changelog

## [Unreleased]
### Added
- 개발 중인 새 기능

### Changed
- 변경된 기능

### Fixed
- 수정된 버그

## [1.1.0] - 2026-02-15
### Added
- 새 기능 A
- 새 기능 B

### Changed
- 변경 사항 A

### Fixed
- 버그 수정 A
```

### 카테고리
- **Added**: 새로운 기능
- **Changed**: 기존 기능 변경
- **Deprecated**: 곧 제거될 기능
- **Removed**: 제거된 기능
- **Fixed**: 버그 수정
- **Security**: 보안 관련 수정

## GitHub 브랜치 보호 규칙

main 브랜치 보호 설정 (권장):

1. **Settings** → **Branches** → **Add rule**
2. Branch name pattern: `main`
3. 설정:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1명 이상)
   - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators (선택사항)

## 도구 추천

### GitHub CLI
```bash
# 설치 (macOS)
brew install gh

# 인증
gh auth login

# PR 생성
gh pr create --title "feat: 새 기능" --body "설명"

# Release 생성
gh release create v1.0.0 --title "v1.0.0" --notes "변경사항"
```

### fastlane (선택사항)
iOS/macOS 앱 배포 자동화:
```bash
# 설치
gem install fastlane

# 초기화
fastlane init
```

## 체크리스트

### 릴리즈 전 체크리스트
- [ ] 모든 테스트 통과
- [ ] CHANGELOG.md 업데이트
- [ ] 버전 번호 업데이트
- [ ] 문서 업데이트
- [ ] 빌드 및 실행 테스트 (iOS, macOS)
- [ ] 다크모드 테스트
- [ ] 접근성 테스트

### 릴리즈 후 체크리스트
- [ ] GitHub Release 생성 확인
- [ ] 태그 푸시 확인
- [ ] 브랜치 정리 (병합된 feature/hotfix 브랜치 삭제)
- [ ] 팀 공지 (있다면)

## 문의

릴리즈 프로세스 관련 문의사항은 이슈로 등록해주세요.
