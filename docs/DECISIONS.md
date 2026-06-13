# 달토끼 iOS — 설계 결정 기록 (DECISIONS)

> 왜 이렇게 했는지 근거를 기록하는 문서.
> 모든 결정에는 근거(사용자 요청, 공식 문서, 기술적 제약)를 명시할 것.

---

## 결정 기록

### DEC-001: 탭바 중앙 돌출 배지 유지 (2026-06-13)

**결정**: 중앙 탭은 표준 탭 아이콘이 아닌 CenterBadge overlay로 유지
**근거**: 사용자 시안에 네이비 원 배지 + 달토끼 아이콘 + 라벨 없음으로 디자인됨
**참고**: Apple HIG Tab Bars에 따르면 탭 아이콘은 균일해야 하나, 사용자 디자인 의도를 우선함
**관련 파일**: `App/Views/MainTabView.swift`

### DEC-002: 디자인 토큰 체계 (2026-06-11)

**결정**: 커스텀 디자인 토큰 사용 (DT namespace)
**근거**: 달토끼 브랜드 컬러가 Apple 시스템 컬러와 다름 — 한지/크래프트지 톤
**값**:
- 배경: #f8f2e8
- 카드: #faf6ee
- 포인트: #d4789c
- 텍스트 주: #2a2520
- 텍스트 부: #8b7e6a
- 탭바 보더: #e8dcc4
- 밤하늘: #2a2f50
**참고**: 다크 모드 대응 시 4 variant (light, dark, light HC, dark HC) 필요 (Apple HIG — Color)
**관련 파일**: `App/Views/Theme.swift`

### DEC-003: 엔진 라이선스 클린 구현 (2026-06-11)

**결정**: 천체력을 VSOP87B + Meeus(MIT) + JPL Horizons로 자체 구현
**근거**: AGPL 라이브러리 의존성 제거 필요 (앱스토어 배포 시 소스 공개 의무 회피)
**검증**: 골든 픽스처 408건 대비 허용오차 이내 (행성≤0.003°, 달≤0.018°, 커스프≤0.0002°)
**관련 파일**: `Engine/Sources/NatalKit/`, `NOTICE.md`

### DEC-004: XcodeGen 사용 (2026-06-11)

**결정**: Xcode 프로젝트를 project.yml + xcodegen으로 관리
**근거**: .pbxproj 충돌 방지, 선언적 프로젝트 정의
**관련 파일**: `project.yml`

### DEC-005: iOS 스킬 근거 기반 재작성 (2026-06-13)

**결정**: apple-hig-designer, ios-ux-design, mobile-ios-design 전면 재작성 + appstore-review-guide 신규 생성
**근거**: Apple Developer Documentation 11개 페이지 공식 조사
  - Tab Bars, Typography, Color, Accessibility, Layout, Buttons, Navigation Bars, App Icons, Dark Mode, Motion, App Store Review Guidelines
**수정 내용**: 기존 스킬의 부정확한 수치 교정, 출처 없는 규칙 삭제, 모든 항목에 Apple 공식 출처 명시
**관련 파일**: `~/.claude/skills/apple-hig-designer/`, `ios-ux-design/`, `mobile-ios-design/`, `appstore-review-guide/`

### DEC-006: 홈 CTA 배너를 탭바 위 떠 있는 레이어로 전환 (2026-06-13)

**결정**: 홈 스크롤 콘텐츠 맨 아래에 있던 "달토끼의 한마디" CTA 배너(`ctaBanner`)를 스크롤에서 분리해 탭바 위에 떠 있는 overlay 레이어로 전환하고, X 버튼으로 닫을 수 있게 함
**근거**: 사용자 요청 — "메인 페이지 하단의 배너는 탭바 레이어 스택으로 올라오고 X 버튼 누르면 배너 없어지게"
**범위 확정** (사용자 확인): 대상=ctaBanner / 표시 범위=홈 탭 한정·탭바 위 고정 / 닫힘=세션 한정(앱 재실행 전까지 숨김, 영속 저장 없음)
**구현**:
- `showCtaBanner` @State(기본 true)로 세션 한정 표시 제어 — UserDefaults 저장 안 함
- HomeView 최상위 `.overlay(alignment: .bottom)`에 배너 배치, `.transition(.move(edge: .bottom))`로 슬라이드
- 스크롤 콘텐츠에 `padding(.bottom, showCtaBanner ? 104 : 18)`로 마지막 카드 가림 방지
**기술적 함정**: `ctaBanner` 내부 별 배경이 `GeometryReader`(탐욕적 레이아웃)라 전체 높이를 제안하는 overlay에서는 화면 전체로 늘어남 → `.fixedSize(horizontal: false, vertical: true)`로 원래 콘텐츠 높이 유지
**검증**: iPhone 16 Pro 시뮬레이터(iOS 18.0) 빌드·설치·실행, 배너 크기/위치/X 닫기 시각 확인 ✅
**관련 파일**: `App/Views/Home/HomeView.swift`

---

## 결정 템플릿

새 결정 추가 시 아래 형식 사용:

```
### DEC-NNN: 제목 (날짜)

**결정**: 무엇을 어떻게 하기로 했는지
**근거**: 왜 이렇게 결정했는지 (사용자 요청 / 공식 문서 / 기술적 제약)
**대안 검토**: 다른 방법이 있었다면 왜 선택하지 않았는지
**관련 파일**: 영향받는 파일 경로
```
