# 달토끼 (DalTokkie) — Claude Code 프로젝트 설정

## 프로젝트 개요

운세/사주/타로 iOS 앱. SwiftUI 네이티브, iOS 17+, iPhone 전용.
XcodeGen(`project.yml`)으로 프로젝트 관리.

## 핵심 규칙

1. **요청한 것만 변경** — 범위 밖 변경은 반드시 먼저 질문할 것
2. **근거 필수** — 공식 문서, 시안, 사용자 요청 중 하나 없이 작업하지 않음
3. **불확실하면 질문** — 임의 판단/할루시네이션 금지
4. **개발 프로세스**: docs/PROCESS.md 참조 (PDCA + TDD)
5. **작업 앵커**: 세션 시작 시 docs/WORKLOG.md 읽을 것, 작업 후 업데이트

## 빌드 & 테스트

```bash
# Xcode 프로젝트 생성 (project.yml 변경 후)
xcodegen generate

# 앱 빌드
xcodebuild -project DalTokkie.xcodeproj -scheme DalTokkie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Engine 유닛 테스트 (13 test cases, 4,398 golden fixtures)
cd Engine && swift test

# 린트 (SwiftLint 설정 시)
swiftlint
```

## 아키텍처

```
App/                        ← SwiftUI 앱 레이어
├── DalTokkieApp.swift      ← 앱 진입점
├── AppState.swift           ← @Observable 앱 상태
├── Views/
│   ├── MainTabView.swift    ← 탭바 (CenterBadge 커스텀 오버레이)
│   ├── Theme.swift          ← DT 디자인 토큰
│   ├── Home/                ← 홈 탭
│   ├── Fortune/             ← 운세 상세
│   ├── Tarot/               ← 타로
│   └── Misc/                ← 부적, 마이
└── Models/

Engine/                     ← SPM 패키지 (순수 Swift, UI 의존 없음)
├── Sources/
│   ├── LunarKit/           ← 음양력 변환
│   ├── SajuKit/            ← 사주팔자 계산 + 용신/대운/일운
│   ├── NatalKit/           ← 서양 천체력 (VSOP87B + Meeus, AGPL-free)
│   └── ZiweiKit/           ← 자미두수
└── Tests/                  ← 골든 픽스처 기반 테스트
```

## 디자인 토큰 (DT namespace — Theme.swift)

| 토큰 | 값 | 용도 |
|------|-----|------|
| `DT.bg` | #F8F2E8 | 크래프트지 배경 |
| `DT.card` | #FAF6EE | 카드 크림 |
| `DT.accent` | #D4789C | 포인트 핑크 |
| `DT.ink` | #2A2520 | 본문 텍스트 |
| `DT.inkSoft` | #8B7E6A | 보조 텍스트 |
| `DT.line` | #E8DCC4 | 보더/구분선 |
| `DT.night` | #2A2F50 | 밤하늘 (CTA, 탭 로고 배경) |
| `DT.radius` | 16pt | 카드 코너 |
| `DT.pagePadding` | 14pt | 페이지 좌우 패딩 |

## 코딩 컨벤션

- SwiftUI + @Observable (iOS 17+), Observation 프레임워크 사용
- 뷰 컴포넌트: `CraftCard`, `SectionTitle` 재사용
- 폰트: `DT.serif()`, `DT.sans()` — 둘 다 **Pretendard 단일**로 매핑(번들 OFL, `DTFonts.register()` 런타임 등록). DEC-010
- Engine 레이어는 UI import 금지 — 순수 Swift 연산만
- 라이선스: AGPL 의존성 금지 (App Store 배포 제약)

## 참조 문서

- `docs/WORKLOG.md` — 작업 히스토리 앵커 (매 세션 필수 확인)
- `docs/PROCESS.md` — PDCA + TDD 개발 프로세스
- `docs/DECISIONS.md` — 설계 결정 기록 (DEC-001~)
- `STATUS.md` — 프로젝트 전체 상태
- `NOTICE.md` — 라이선스/저작권

## 핵심 변경/주의 (최근)

- **일일운세(daily-fortune) 분기**: 합충형파해 가중치·경향톤·명리 기반 달빛 편지(전치 신살 포함)로 자체 진화 → `daily-fortune.json` 픽스처는 자체 알고리즘 기준 재생성됨. **saju-api 비트재현 아님** (DEC-014/015). 코어 사주·천체력·자미두수 픽스처는 정통 재현 유지 — 변경 금지
- **AI 심층 편지**: 서버 라우트 `saju-api/app/api/daily/interpret/route.ts`(별도 레포). 앱은 `AIProxy.interpretDaily` → 달빛 편지 ✨탭. **프로덕션 동작하려면 saju-api vercel 배포 + AI_API_KEY 필요**
- **폰트**: Pretendard 단일(번들 OFL), DT.serif/sans 모두 매핑 (DEC-010)
- 신규 Swift 소스 추가 시 `xcodegen generate` 필수 (sources: App 자동 수집)

## App Store 주의사항

- Fortune telling은 포화 카테고리 (App Store Review Guidelines 4.3)
- 고유 가치 입증 필요 — 천체력 자체 구현, 한국 사주 특화가 차별점
