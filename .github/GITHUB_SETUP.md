# GitHub 저장소 설정 가이드

이 문서는 Nower 프로젝트의 GitHub 저장소를 올바르게 설정하는 방법을 안내합니다.

## 목차
1. [브랜치 보호 규칙](#브랜치-보호-규칙)
2. [GitHub Actions 권한](#github-actions-권한)
3. [레이블 설정](#레이블-설정)
4. [협업자 관리](#협업자-관리)

---

## 브랜치 보호 규칙

### main 브랜치 보호 설정

1. **Settings** → **Branches** → **Add rule** 클릭

2. **Branch name pattern** 입력:
   ```
   main
   ```

3. **다음 옵션을 활성화**:

   #### ✅ Require a pull request before merging
   - **Require approvals**: 1명 (팀 프로젝트인 경우)
   - **Dismiss stale pull request approvals when new commits are pushed**: 체크
   - **Require review from Code Owners**: 체크 (선택사항)

   #### ✅ Require status checks to pass before merging
   - **Require branches to be up to date before merging**: 체크
   - **Status checks**:
     - `build-ios` (CI 워크플로우 실행 후 자동으로 나타남)
     - `build-macos` (CI 워크플로우 실행 후 자동으로 나타남)

   #### ✅ Require conversation resolution before merging
   - 모든 코멘트가 해결되어야 머지 가능

   #### ⚠️ Include administrators (선택사항)
   - 관리자도 규칙을 따르도록 강제 (권장)

4. **Save changes** 클릭

### develop 브랜치 보호 설정 (선택사항)

main과 동일하게 설정하되, 승인 요구사항을 더 유연하게 할 수 있습니다.

---

## GitHub Actions 권한

GitHub Actions가 릴리즈를 자동으로 생성하려면 올바른 권한이 필요합니다.

### 권한 설정

1. **Settings** → **Actions** → **General**

2. **Workflow permissions** 섹션:
   - **Read and write permissions** 선택
   - **Allow GitHub Actions to create and approve pull requests** 체크

3. **Save** 클릭

### 토큰 권한 확인

`.github/workflows/release.yml` 파일은 `GITHUB_TOKEN`을 사용합니다. 위 설정으로 충분하지만, 문제가 있다면 Personal Access Token (PAT)을 사용할 수 있습니다.

#### PAT 생성 (필요시)

1. **Settings** (개인 설정) → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. **Generate new token**
3. 권한 선택:
   - `repo` (전체)
   - `workflow`
4. 토큰을 복사하고 저장소 Secrets에 추가:
   - **Settings** → **Secrets and variables** → **Actions** → **New repository secret**
   - Name: `RELEASE_TOKEN`
   - Value: 생성한 PAT

5. `.github/workflows/release.yml` 파일에서 `GITHUB_TOKEN`을 `RELEASE_TOKEN`으로 변경

---

## 레이블 설정

PR과 이슈를 효과적으로 관리하기 위한 레이블을 추가합니다.

### 레이블 목록

1. **Issues** → **Labels** → **New label**

2. 다음 레이블들을 추가:

| 이름 | 색상 | 설명 |
|------|------|------|
| `bug` | `#d73a4a` | 버그 리포트 |
| `enhancement` | `#a2eeef` | 새로운 기능 요청 |
| `documentation` | `#0075ca` | 문서 관련 |
| `question` | `#d876e3` | 질문 |
| `help wanted` | `#008672` | 도움이 필요함 |
| `good first issue` | `#7057ff` | 초보자 친화적 |
| `priority: high` | `#b60205` | 높은 우선순위 |
| `priority: medium` | `#fbca04` | 중간 우선순위 |
| `priority: low` | `#0e8a16` | 낮은 우선순위 |
| `iOS` | `#1d76db` | iOS 관련 |
| `macOS` | `#1d76db` | macOS 관련 |
| `design` | `#e99695` | UI/UX 디자인 |
| `refactor` | `#5319e7` | 리팩토링 |
| `performance` | `#f9d0c4` | 성능 개선 |
| `dependencies` | `#0366d6` | 의존성 업데이트 |

### 레이블 자동 적용

PR 제목에 따라 레이블을 자동으로 적용하려면 `.github/labeler.yml` 파일을 추가할 수 있습니다.

---

## 협업자 관리

### 협업자 추가

1. **Settings** → **Collaborators and teams**
2. **Add people** 또는 **Add teams** 클릭
3. GitHub 사용자명 입력
4. 권한 레벨 선택:
   - **Read**: 읽기 전용
   - **Triage**: 이슈/PR 관리
   - **Write**: 코드 작성 및 PR 생성
   - **Maintain**: 저장소 관리 (설정 제외)
   - **Admin**: 전체 관리 권한

### 팀 생성 (조직인 경우)

1. 조직 설정으로 이동
2. **Teams** → **New team**
3. 팀 이름 및 설명 입력
4. 멤버 추가
5. 저장소에 팀 추가:
   - **Settings** → **Collaborators and teams** → **Add teams**

---

## 알림 설정

### 릴리즈 알림

릴리즈가 생성되면 알림을 받으려면:

1. 저장소 상단의 **Watch** 버튼 클릭
2. **Custom** 선택
3. **Releases** 체크
4. **Apply** 클릭

### Slack/Discord 연동 (선택사항)

GitHub Actions에서 Slack이나 Discord로 알림을 보낼 수 있습니다.

#### Slack 예시

`.github/workflows/release.yml`에 추가:

```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'New release v${{ steps.get_version.outputs.VERSION }} created!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
  if: always()
```

---

## 보안 설정

### Dependabot 활성화

자동으로 의존성을 업데이트하고 보안 취약점을 알려줍니다.

1. **Settings** → **Security & analysis**
2. **Dependabot alerts** 활성화
3. **Dependabot security updates** 활성화
4. **Dependabot version updates** 활성화

### Secret 관리

민감한 정보를 저장소 Secrets에 저장:

1. **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. Secret 추가:
   - `KASI_API_KEY`: 공휴일 API 키
   - 기타 필요한 키들

**⚠️ 주의**: Secret은 절대 코드에 하드코딩하지 마세요!

---

## 체크리스트

설정이 완료되었는지 확인하세요:

- [ ] main 브랜치 보호 규칙 설정
- [ ] develop 브랜치 보호 규칙 설정 (선택사항)
- [ ] GitHub Actions 권한 설정
- [ ] 레이블 추가
- [ ] 협업자 추가 (필요시)
- [ ] Dependabot 활성화
- [ ] Secret 설정 (API 키 등)
- [ ] 릴리즈 알림 설정

---

## 추가 리소스

- [GitHub 브랜치 보호 문서](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub Actions 권한](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)
- [Dependabot 가이드](https://docs.github.com/en/code-security/dependabot)

---

## 문의

설정 관련 문의사항은 이슈로 등록해주세요.
