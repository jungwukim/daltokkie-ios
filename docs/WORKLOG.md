# 달토끼 iOS — 작업 로그 (WORKLOG)

> 모든 Claude Code 세션에서 이 문서를 앵커로 사용할 것.
> 작업 시작 전 반드시 읽고, 작업 완료 후 반드시 업데이트할 것.

## 문서 구조

| 문서 | 용도 |
|------|------|
| `docs/WORKLOG.md` | **앵커 문서** — 작업 히스토리, 현재 상태, 다음 작업 |
| `docs/PROCESS.md` | **개발 프로세스** — PDCA + TDD 워크플로우 정의 |
| `docs/DECISIONS.md` | 설계 결정 기록 — 왜 이렇게 했는지 근거 |
| `docs/features/{name}/` | 기능별 PLAN.md + DESIGN.md |
| `STATUS.md` (루트) | 프로젝트 전체 상태 (기존 유지) |

## 작업 규칙

1. **요청한 것만 변경** — 범위 밖 변경은 반드시 사용자에게 먼저 질문
2. **근거 필수** — 공식 문서, 시안, 사용자 요청 중 하나 없으면 작업하지 않음
3. **불확실하면 질문** — 임의 판단/할루시네이션 금지
4. **작업 전 이 문서 확인** — 이전 맥락, 결정 사항, 남은 작업 파악

---

## 현재 상태

- **브랜치**: main
- **최신 빌드**: 성공 (2026-06-13)
- **엔진 테스트**: 13건 전부 통과, 골든 픽스처 4,398건 검증

## 작업 히스토리

### 2026-06-13 세션

#### 1. Claude Code 업데이트 확인
- **요청**: Claude Code 최신 버전 확인
- **결과**: v2.1.177 — npm 최신과 동일 확인

#### 2. Claude Code 설정 검증
- **요청**: 현재 설정이 올바른지 검증
- **결과**: 전반적 OK, 단 **모델 버전 검증 실수** — claude-opus-4-6을 "OK"로 통과시킴
- **수정**: claude-opus-4-6 → claude-opus-4-8 로 업데이트
- **교훈**: 설정 검증 시 모델 버전 최신 여부도 정확히 확인할 것

#### 3. 프로젝트 분석
- **요청**: 현재 프로젝트 분석
- **결과**: 구조 정리 (App 19개 소스 2,858줄 / Engine 28개 소스 5,585줄 / 에셋 164개)

#### 4. 탭바 중앙 버튼 높이 조정
- **요청**: "탭바 가운데 버튼이 너무 위로 가 있는데 다른 아이콘들과 동일하게 높이 맞춰줘"
- **필요한 변경**: `.offset(y: -20)` → `.offset(y: 0)` (높이만)
- **실수**: 요청 없이 아이콘(dal-tokkie-icon → moon.stars.fill), 라벨(없음 → "운세"), CenterBadge 구조까지 임의 삭제
- **복원**: 원래 코드 전체 복원 후 offset만 수정
- **교훈**: 요청 범위를 벗어나는 변경 절대 금지 → 피드백 메모리 저장됨

#### 5. iOS 스킬 검증 및 재작성
- **요청**: Apple 공식 문서 근거로 스킬 만들고 근거 위주 설명
- **작업 내용**:
  - `apple-hig-designer` — 전면 재작성 (Apple HIG 10개 페이지 공식 수치 반영)
  - `ios-ux-design` — 전면 재작성 (잘못된 규칙 "purple/indigo 금지" 삭제, 모든 항목 출처 명시)
  - `mobile-ios-design` — 전면 재작성 (iOS 18+ Tab API 추가, 코드에 HIG 수치 병기)
  - `appstore-review-guide` — **신규 생성** (App Store Review Guidelines 섹션 1-5 + 달토끼 특수 주의사항)
- **근거**: Apple Developer Documentation 11개 페이지 조사

#### 6. 작업 히스토리 문서 구조 생성
- **요청**: 작업 히스토리 문서 구조 만들어서 앵커로 사용
- **결과**: docs/WORKLOG.md + docs/DECISIONS.md 생성

#### 7. PDCA + TDD 구조화 개발 프로세스 세팅
- **요청**: [설계 → 반영] (PDCA) → TDD로 구조화 개발 가능하도록 프로젝트 세팅
- **결과**: docs/PROCESS.md 생성 (워크플로우 정의), docs/features/ 디렉토리 생성
- **프로세스**: Plan → Design → TDD(Red→Green→Refactor) → Check → Act
- **코드 변경 없음** (사용자 선택: docs 템플릿 + 프로세스 문서화만)

#### 8. Claude Code 최적 성능 설정 (2026-06-13)
- **요청**: 최고 성능이 나도록 설정 최적화, 근거 기반
- **변경 내용**:
  - `CLAUDE.md` **신규 생성** — Claude Code가 매 세션 자동 로드하는 프로젝트 컨텍스트 파일. 빌드 커맨드, 아키텍처, 디자인 토큰, 핵심 규칙, 참조 문서 경로 포함
  - **플러그인 17개 → 6개** 정리 — 제거: typescript-lsp, rust-analyzer-lsp, frontend-design, vercel(2개), stripe, agent-sdk-dev, plugin-dev, bkit(2개), superpowers. 근거: iOS 네이티브 프로젝트에 무관한 플러그인이 컨텍스트 윈도우를 소비
  - **유지 플러그인**: swift-lsp, context7, github, code-review, security-guidance, figma
  - `alwaysThinkingEnabled`: false → **true** — Opus 4.8 adaptive thinking 활성화. 복잡한 Engine 계산/아키텍처 결정에서 정확도 향상
  - `.claude/settings.json` **프로젝트 레벨 신규 생성** — xcodebuild, xcodegen, swift test, swiftlint 등 빌드 권한을 유연하게 설정
- **근거**: Claude Code 공식 문서에서 CLAUDE.md는 "모든 세션에서 자동 로드되는 시스템 프롬프트" 역할. 불필요한 플러그인은 컨텍스트 윈도우를 소비하여 실제 작업 가용 토큰 감소

#### 9. 홈 CTA 배너 → 탭바 위 떠 있는 레이어 + X 닫기 (2026-06-13)
- **요청**: "메인 페이지 하단의 배너는 탭바 레이어 스택으로 올라오고 X 버튼 누르면 배너 없어지게 설계 변경하고 적용/테스트/검증"
- **범위 확정** (사용자 확인): 대상=`ctaBanner`("달토끼의 한마디") / 홈 탭 한정·탭바 위 고정 / 닫힘=세션 한정(앱 재실행 전까지)
- **변경**: `App/Views/Home/HomeView.swift`만 수정
  - `showCtaBanner` @State(세션 한정, 저장 없음) 추가
  - ctaBanner를 스크롤에서 분리 → 최상위 `.overlay(alignment: .bottom)`에 배치, `.move(edge: .bottom)` 트랜지션
  - X 닫기 버튼(topTrailing) 추가, 스크롤 하단 패딩 동적 확보(104/18)
- **함정 해결**: ctaBanner 내부 `GeometryReader` 별 배경이 overlay에서 전체 화면으로 늘어남 → `.fixedSize(vertical: true)`로 원래 높이 유지 (사용자 지적 "왜 전체 화면으로 떠?" 반영)
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·설치·실행, 배너 크기/위치 시각 확인 ✅ — 사용자 "잘 되었어" 확인
- **결정 기록**: DEC-006

---

## 남은 작업 (STATUS.md에서 이관)

| 우선순위 | 작업 | 상태 |
|---------|------|------|
| 1 | 탭바 중앙 배지 높이 시뮬레이터 확인 및 미세 조정 | 대기 — 사용자 확인 필요 |
| 2 | Noto Sans/Serif KR 폰트 번들 | 미착수 |
| 3 | 행운 아이콘 웹 SVG 125종 대응 (현재 SF Symbols 5종) | 미착수 |
| 4 | 타로/궁합 AI 해석 연결 | 미착수 |
| 5 | 사주 상세 신살/공망/합충형파해/지장간 섹션 추가 | 미착수 |
| 6 | 마이 탭 고도화 | 미착수 |
| 7 | 앱스토어 메타데이터/심사 대응 | 미착수 |

## 주의사항

- 달토끼는 App Store 기준 "fortune telling" — 포화 카테고리이므로 고유 가치 입증 필요 (App Store Review Guidelines 4.3)
- 디자인 토큰: 배경 #f8f2e8, 카드 #faf6ee, 포인트 #d4789c, 텍스트 #2a2520/#8b7e6a, 탭바 보더 #e8dcc4, 밤하늘 #2a2f50
- 천체력은 라이선스 클린 재구현 (AGPL 의존성 없음)
