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
**갱신(2026-06-13, DEC-007)**: 배지 유지 결정은 그대로, 단 돌출(offset -20) → 비돌출(offset 0)로 변경

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

### DEC-007: 하단 탭바는 CenterBadge 오버레이 유지(표준 탭바 미채택), 배지는 비돌출 (2026-06-13)

**결정**: 하단 탭바를 순수 iOS 표준 SwiftUI 탭바로 바꾸지 않고 기존 CenterBadge 커스텀 오버레이를 유지. 단 중앙 배지는 탭바 위로 돌출(`offset(y: -20)`)하지 않고 다른 탭 아이콘과 같은 높이로 정렬(`offset(y: 0)`)
**근거**:
- 기술적 제약 — SwiftUI 표준 `.tabItem`은 아이콘 크기를 시스템이 강제(~25pt). "표준 탭바"와 "큰 중앙 토끼 아이콘"은 동시 충족 불가. 큰 중앙 아이콘을 원하면 오버레이가 유일한 방법
- 사용자 요청 — 표준 전환을 시도했으나 중앙 아이콘이 작아지는 문제로 "마지막 커밋으로 원복" 후 "중앙 배지 높이를 다른 아이콘과 맞춰줘" 지시
**대안 검토**:
- 순수 표준 탭바(중앙도 일반 탭 아이템): 중앙 토끼가 ~25pt로 작아져 브랜드성 약화 → 사용자 반려
- 돌출 배지 복원(offset -20): 사용자가 "다른 아이콘과 높이 맞춤" 원해 비채택
**검증**: iPhone 16 Pro(iOS 18.0) 빌드·설치·실행, 중앙 배지 비돌출·동일 높이 정렬 확인 ✅ (커밋 6314dd3)
**관련 파일**: `App/Views/MainTabView.swift`
**관련**: DEC-001 갱신

### DEC-008: 이미지 에셋 ASCII 영어 의미명 + assets-src 레포 내 출처 (2026-06-14)

**결정**: 이미지/아이콘 에셋명을 한글 대신 **영어 의미명(ASCII)**으로 통일하고, 원본을 레포 내 `assets-src/<카테고리>/`에 두어 `prepare-assets.sh`가 자동 등록
**근거**:
- macOS는 한글 파일명을 **NFD(분해형)**로 저장 → `grep`/스크립트/툴링과 불일치 (실제로 `중앙` 검색 실패 확인)
- 외부 `~/Desktop` 의존 제거 → 버전관리·CI·타 PC 재현성 확보
- 영어 의미명은 개발자가 바로 식별 가능 (vs 번호/로마자)
**명명 규칙**: `<prefix>-<englishName>` — `color-green`, `place-library`, `dir-north`, `item-01`. 엔진 한글 값 → 에셋명 변환은 `LuckyAssets.swift` colorMap/placeMap이 담당
**대안 검토**: 로마자(chorok)·번호(color-01)는 가독성 낮아 반려 (사용자 선택: 영어 의미명)
**주의**: 셸이 zsh면 배열 1-인덱스라 매핑 스크립트는 bash로 실행할 것 (오프바이원 방지)
**관련 파일**: `assets-src/`, `App/Assets.xcassets/`, `App/LuckyAssets.swift`, `scripts/prepare-assets.sh`

### DEC-009: 홈 타이틀 Poppins 번들 + 런타임 폰트 등록 (2026-06-20)

**결정**: 홈 타이틀을 `dal tokkie`(소문자) + **Poppins Bold**(지오메트릭 산세리프)로 변경. 폰트는 `App/Fonts/Poppins-Bold.ttf`로 번들하고 **런타임 등록**(`CTFontManagerRegisterFontsForURL`, `DalTokkieApp.init`)으로 로드. Info.plist `UIAppFonts`는 사용하지 않음
**근거**:
- 사용자 요청: 브랜드 "The Coffee"(브라질 태생, 일본 미학 영감)의 둥근 지오메트릭 산세리프 룩 재현. The Coffee는 Circular/Poppins 계열 — Poppins는 OFL 무료라 상업 배포 가능
- 런타임 등록 선택 이유: 프로젝트가 `GENERATE_INFOPLIST_FILE: YES`(물리 Info.plist 없음). `UIAppFonts`를 쓰려면 Info.plist 수동 관리(`info:` 블록)로 전환 + 기존 4개 `INFOPLIST_KEY_*` 마이그레이션 필요해 위험. 런타임 등록은 변경 범위가 작고 자기완결적
**대안 검토**: ① SF Rounded(무번들, 근접하나 덜 기하학적) ② 시스템 SF(중립 그로테스크, 룩 불일치) — 사용자가 "정확한 매칭" 위해 반려. ③ Info.plist UIAppFonts — 위 근거로 반려
**라이선스**: Poppins SIL OFL 1.1 — `NOTICE.md` 고지 추가
**관련 파일**: `App/Fonts/Poppins-Bold.ttf`, `App/Views/Theme.swift`(`DT.geo`/`DTFonts`), `App/DalTokkieApp.swift`, `App/Views/Home/HomeView.swift`, `NOTICE.md`
**후속**: DEC-010으로 **되돌림(superseded)** — 앱 전체 Pretendard 단일 통일하며 Poppins/`DT.geo` 제거

### DEC-010: 앱 전체 타이포 Pretendard 단일 통일 (2026-06-20)

**결정**: 앱 전체 폰트를 **Pretendard**(OFL) 하나로 통일. `DT.serif`/`DT.sans` 둘 다 Pretendard로 매핑(weight별 정적 .otf 직접 참조), 런타임 등록(DEC-009의 `DTFonts` 방식 유지). DEC-009의 Poppins 타이틀 폰트는 제거
**근거**:
- 사용자 결정("Pretendard 단일"). 서비스 특성상 한글이 본문 95% — 시스템 폰트(SF/New York)는 한글이 기기·버전별 폴백(애플 SD산돌고딕/AppleMyungjo)이라 브랜드 일관성·디자인 통제 약함
- Pretendard = 한국 앱 사실상 표준, 고가독성, 라틴+한글 통합, OFL 무료(상업 배포 가능). WORKLOG 남은작업 #2(Noto KR 번들)을 이걸로 대체
- weight별 파일 직접 참조 → SwiftUI faux-bold(가짜 굵기) 방지
**대안 검토**: ① 2단 구성(본명조+Pretendard) — 감성/UI 분리상 이상적이나 사용자가 단일 선택 ② SF/New York 시스템 유지 — 한글 폴백 일관성 문제로 반려 ③ Poppins 병행 — 단일 방침과 충돌해 제거
**라이선스**: Pretendard SIL OFL 1.1 — `NOTICE.md` 갱신
**관련 파일**: `App/Fonts/Pretendard-{Regular,Medium,SemiBold,Bold}.otf`, `App/Views/Theme.swift`, `App/Views/Home/HomeView.swift`, `NOTICE.md`

### DEC-011: 홈 상단 카드 = 오늘 중심 7일 주간 페이저 (2026-06-20)

**결정**: 홈 히어로 카드를 7일 가로 페이저(`TabView .page`)로. 데이터는 **오늘 중심 7일(오늘±3)**이라 오늘이 항상 index 3(점 7개의 정중앙). 점 인디케이터는 오늘=다른 색(accent), 현재 페이지=길쭉 캡슐로 이중 표시. 페이징 범위는 상단 카드 한정
**근거**:
- 사용자 요청: 7개 점(요일) + 카드 페이징 + 오늘 점 다른 색 + 현재 페이지 표시 + 요일별 내용. 후속 요청으로 "오늘을 점 정중앙" → 월~일 고정이 아닌 **오늘 중심 창**이어야 오늘이 항상 가운데
- 카드 높이 고정(360): `TabView .page`는 페이지 높이가 일정해야 정렬·클리핑이 안정. 편지 글귀가 제목3줄·본문2줄로 균일해 고정값이 안전
- 캐러셀 간격: 페이지 카드 +7 패딩 / TabView -7 패딩으로 카드 본체 폭은 유지하면서 카드 사이 14pt 간격
**대안 검토**: ① 월~일 캘린더 주 고정 — 오늘이 가운데로 안 와 사용자 반려 ② `ScrollView(.horizontal)+.scrollTargetBehavior(.paging)` — 가능하나 점 동기화 바인딩이 `TabView selection`보다 번거로워 반려 ③ 전체 홈 페이징 — 요청은 "상단 카드"라 범위 한정
**관련 파일**: `App/AppState.swift`(7일·오늘±3), `App/Views/Home/HomeView.swift`(`heroPager`/`weekDots`/`heroBanner` 리팩터)
**부수효과**: `bundle.fortunes` 공유로 "자세히 보기"의 `LuckyLineChart`가 5→7포인트(주간)로 확장됨(개선으로 수용)

### DEC-012: 행운 아이템 항목별 전용 아이콘 — 카테고리+번호 ASCII명 (2026-06-21)

**결정**: 음료/장소/향기/아이템 행운 항목을 대표 아이콘 1개가 아닌 **항목별 전용 아이콘**으로 표시. imageset은 `<cat>-NN`(drink/place/scent/litem, NN=`elementItems` 오행순 1~25). 엔진 한글값→에셋은 `LuckyAssets`의 카테고리별 맵이 담당
**근거**:
- 사용자가 항목별 아이콘을 새로 제작 → 각 행운 값에 1:1 매칭이 목적
- 번호명 채택: 100개 항목에 정확한 영어 의미명(DEC-008 선호)을 부여하는 것은 비현실적·모호. `elementItems` 순서와 1:1이라 검증 쉬움. 맵 주석에 한글값 병기로 가독성 보완
- `litem-` 접두사: 운세 컨디션이 쓰는 `item-01..10`과 네임스페이스 충돌 방지
- 매칭은 Python NFC 정규화로 (macOS 한글 NFD 파일명 이슈 회피, DEC-008 교훈), 표기 불일치는 오버라이드로 명시 처리
**대안 검토**: ① 영어 의미명(DEC-008) — 100개 수작업·모호로 반려 ② 기존 `item-NN` 재사용 — 컨디션과 충돌로 반려 ③ 한글 파일명 그대로 — NFD/툴링 문제로 반려
**관련 파일**: `App/Assets.xcassets/{drink,place,scent,litem}-NN.imageset`, `assets-src/{drinks,places,scents,luckyitems}`, `App/LuckyAssets.swift`, `App/Views/Home/HomeView.swift`
**관련**: DEC-008(ASCII 명명·assets-src), 구버전 `place-<이름>` 24개 삭제

### DEC-013: 행운 아이템 항목 설명 = 오행 기반 카테고리 템플릿 (2026-06-21)

**결정**: 행운 아이템 `>` 상세의 항목별 설명을 **용신 오행 × 카테고리 25개 템플릿**(자체 작성)으로 제공. 운세 컨디션 `>` 상세는 **엔진 `DailyFortuneCard.description`** 사용
**근거**:
- 사용자 요청(항목별 설명). 운세 컨디션은 엔진이 카드별 설명 보유 → 근거 있는 텍스트 그대로 사용
- 행운 아이템은 엔진에 항목별 설명이 없음(reason은 용신 설명 1개 공통). 항목별 125문구는 과도, 용신 1개는 항목별 아님 → 절충으로 오행(용신)×카테고리 5×5=25 템플릿. 오행 이론(목생기/화활기/토안정/금명료/수지혜) 근거. 엔진 텍스트가 아닌 **자체 작성 콘텐츠**임을 파일 주석에 명시
**대안 검토**: ① 용신 설명 1개 공통 — 항목별 아님 ② 항목별 125문구 — 작업량 과도(추후 AI 생성 여지) ③ 엔진 확장 — 범위 큼. 25 템플릿이 균형
**관련 파일**: `App/Views/Home/LuckyItemReason.swift`, `App/Views/Home/HomeView.swift`(LuckyItemsDetailView/ConditionsDetailView), `App/Views/Home/HomeConditions.swift`(grade/desc)
**관련**: 페이저 선택 요일 기준으로 표시(DEC-011)

### DEC-014: 일일운세 명리 신빙성 강화 + daily-fortune 픽스처 자체화 (2026-06-21)

**결정**: ① 일일 점수에 전치(일진) **합충형파해 가중치**(relationMod)를 명시 반영 ② 컨디션 설명·달빛 편지를 **경향/조언 톤**으로 ③ 달빛 편지를 점수대 고정풀 → **그날 일주·십성·12운성·합충형파해 기반** 생성으로 전환(현대어). 이에 따라 **daily-fortune 골든 픽스처를 새 알고리즘 기준으로 재생성**(saju-api 재현 → 자체 알고리즘)
**근거**:
- 사용자 요청(명리 신빙성↑, 경향/조언 톤). 십성·12운성은 이미 점수에 반영돼 있었고 합충형파해(transitRelations)만 계산되고 미반영이라 이를 가중치로 연결
- 픽스처: 점수/설명/요약이 daily-fortune.json에 잠겨 있어 알고리즘 개선 시 충돌. daily-fortune은 게임화 레이어라 saju-api 재현보다 자체 개선이 사용자 가치에 부합 → 픽스처 재생성. **코어(saju-core·saju-analysis·natal·lunar·ziwei) 픽스처는 불변**으로 정통 재현 가치 유지
- 신살: 현재 `findSinSals`는 natal 기준 → 전치 신살은 후속(사용자 합의). 1차는 per-day 가용 요소(일주·십성·합충)로
**가중치 설계**: 합 +6, 충 -6~-8, 형 -7, 파 -4, 해 -5 / 일주 관계 1.5배 / ±18 클램프 (전반 점수 보정)
**대안 검토**: 앱 레이어 보정(이중구조)·별도표시만 — 사용자가 "엔진 개선+픽스처 갱신" 선택
**관련 파일**: `Engine/Sources/SajuKit/DailyFortune.swift`, `Engine/Tests/SajuKitTests/Resources/daily-fortune.json`, `App/Views/Home/MoonLetter.swift`, `App/Views/Home/HomeView.swift`
**주의**: daily-fortune은 더 이상 saju-api와 비트 동일하지 않음(의도된 분기). 표현은 "경향/조언"으로 단정 금지
**후속 완료(전치 신살)**: 그날 일진 신살(천을귀인·역마·도화·화개·공망)을 `HoshinSinSal.transitSinSals`로 온디바이스 판정해 달빛 편지에 반영. 신살 있으면 제목 헤드라인으로 승격. AI 편지는 비용·지연·심사(4.3) 고려해 홈 카드 대신 별도 심층해석 후보로 보류. 점수에는 미반영(질적 코멘트만, 픽스처 불변)

### DEC-015: AI 심층 편지 — 온디맨드 별도 시트 + 서버 일일 해석 엔드포인트 (2026-06-22)

**결정**: 달빛 편지의 AI 해석은 홈 카드 자동 호출이 아니라 **탭 시 온디맨드 시트**(`AILetterSheet`)로. 서버에 `/api/daily/interpret`(saju-api)를 신설해 그날 명리 데이터를 받아 LLM 편지를 스트리밍. 홈 카드 자체는 기존 온디바이스 명리 편지 유지(즉시·무비용)
**근거**:
- AI를 매 카드/매 스와이프 호출하면 비용·지연·심사(4.3) 부담 → 글랜서블 카드엔 부적합. 사용자가 "받기" 누를 때만 1회 스트리밍이 적절
- 서버 엔드포인트 부재(404) 확인 → saju-api에 기존 `saju/interpret`·`tarot/interpret`와 동일 패턴(streamText/toTextStreamResponse)으로 신설. 클라이언트는 검증된 `AIProxy.stream`+`AIInterpretationView` 재사용
- 프롬프트는 온디바이스 엔진이 계산한 사실(일주·십성·12운성·점수·합충·신살)만 전달 → 환각 없이 근거 기반 해석. 톤은 경향/조언·단정 금지(명시)
**대안 검토**: ① 홈 카드 직접 AI — 비용/지연으로 반려 ② 기존 saju/interpret 재사용 — 원국 해석이라 일일 부적합 ③ 온디바이스만 — 사용자가 "더 끌어올려" 요청
**배포 의존성**: saju-api를 vercel 배포 + `AI_API_KEY`(+선택 `AI_MODEL`) 설정해야 프로덕션 동작. 미배포 시 앱은 graceful 에러
**관련 파일**: `saju-api/app/api/daily/interpret/route.ts`, `App/AIProxyClient.swift`(interpretDaily), `App/Views/Home/HomeView.swift`(AILetterSheet, 라벨 탭)

### DEC-016: 운세 상세 도식 — 온디바이스 렌더(자미 명반·점성 원형차트) (2026-06-23)

**결정**: 웹(saju-api) 수준의 상세 페이지를 iOS로 이관. 1단계로 두 도식을 온디바이스 SwiftUI로 직접 렌더 — 자미 명반은 `GeometryReader+ZStack` 4×4 그리드, 점성 차트는 `Canvas`. 단계별(도식→사주 섹션→궁합)로 진행
**근거**:
- 조사 결과 온디바이스 엔진(ZiweiChart 12궁/성요/사화/대한, NatalChart 행성/하우스/각/어스펙트)이 웹과 동일 데이터를 이미 계산 → **AI와 달리 서버 없이** 렌더 가능
- 도식 먼저(사용자 선택): 사용자가 "명반·점성 도식화"를 명시. SVG(웹) → Canvas/Path(iOS) 기하 포팅
- 규모가 커 단계 분할(각 단계 빌드·스크린샷 검증)
**관련 파일**: `App/Views/Fortune/ZiweiGridChart.swift`, `NatalWheelChart.swift`, `NatalZiweiViews.swift`
**남은 단계**: 사주 상세(지장간/합충형파해/공망/신살/세운/월운 + 분포 차트 — 엔진 EngineAnalysis 함수 public 노출 확인 필요), 궁합 고도화

### DEC-017: 홈 히어로 '오늘의 운세 한 줄' — 하이브리드(AI 한 줄 7일 캐시 + 규칙 폴백) (2026-06-27)

**결정**: 홈 달빛 편지 히어로 문구를 **AI 한 줄(3줄) 주력 + 규칙 기반 요약 폴백**으로 구성. AI는 `/api/daily/interpret`의 신규 `style:"oneline"` 모드로 그날 일진 기반 짧은 3줄을 생성하고, **페이저 범위 7일치(오늘±3)를 한 번에 생성→날짜별 `UserDefaults` 캐시**(키=날짜+프로필). 첫 줄=큰 글귀, 나머지=본문 매핑. 짧은 3줄 검증(1~3줄·첫줄≤20자·각줄≤32자)을 통과해야만 채택, 아니면 규칙 폴백
**근거**:
- 규칙 기반 템플릿(점수 구간+영역)은 본질적으로 유한 → "몇 번 쓰면 반복" 지적. 진짜 매일 다른 글은 LLM이 적합
- 정확도: `daily-one-liner` 콘텐츠 라우트는 그날 일진을 계산하지 않아 LLM이 환각 → 이미 정확한 일진을 받는 `/api/daily/interpret`에 모드 추가가 정확
- 히어로는 즉시 로드돼야 함 → 캐시(하루 1호출 분량, 7일치는 주간 진입 시 1회) + 오프라인/실패 시 규칙 폴백으로 항상 즉시 표시
**대안 검토**: ① 앱에서 직접 LLM 호출 — 키 노출로 반려(기존 결정 유지) ② 규칙 풀만 확장 — 결국 반복이라 반려 ③ 매 진입 실시간 AI — 지연·비용으로 반려(캐시로 대체) ④ 인앱 A/B 토글 — 비교 후 단일안 확정으로 제거
**관련 파일**: `App/AppState.swift`(`ensureHeroLines`/캐시/`parseHeroLine`), `App/AIProxyClient.swift`(`style`), `App/Views/Home/HomeView.swift`, `App/Views/Home/MoonLetter.swift`(규칙 폴백), saju-api `app/api/daily/interpret/route.ts`(oneline, 커밋 a2b3d4a)
**관련**: DEC-015(AI 심층 편지 — 전체 편지는 ✨탭 유지)

### DEC-018: 사주 상세 일목요연화 — 명식표 + 신살·길성 표 (2026-06-27)

**결정**: 흩어져 있던 사주 분석 카드를 두 개의 기둥별 표로 통합. ① 명식표(천간·십성·지지·십성·지장간·12운성·12신살을 시·일·월·년 4열로) ② 신살과 길성 표(요약 줄 + 기둥별 귀속, 길흉 색 구분). 만세력 참고 이미지의 정보 구조만 차용하고 디자인은 달토끼 톤
**근거**: 사용자 피드백("사주 페이지가 너무 어렵다 → 일목요연하게"). 엔진이 이미 기둥별 귀속(12신살 `.pillar`, 특수살 `.pillarIndices`, 십성/운성/지장간 per pillar)을 제공 → 표로 재구성만 하면 됨(추가 계산 불필요)
**대안 검토**: ① 참고 이미지를 천간/지지 신살 분리까지 그대로 복제 — 특수살의 천간/지지 축을 엔진이 명시하지 않아 부정확 위험으로 반려(기둥 단위 통합으로 대체) ② 기존 나열식 유지 — 가독성 낮아 반려
**관련 파일**: `App/Views/Fortune/SajuDetailView.swift`(`SajuChartTable`/`SajuColumn`/`makeChartColumns`), `App/Views/Fortune/SajuAnalysisSections.swift`(`sinsalCard` 표 재작성)
**관련**: DEC-016(사주 상세 온디바이스 이관), 십성 배치표·12운성·신살 나열 카드 제거

### DEC-019: AI 콘텐츠 정확도 — 엔진값 주입 + 출력 레벨 검증 원칙 (2026-06-28)

**결정**: LLM은 명리/천체/자미 사실을 **절대 생성하지 않고** 엔진 계산값만 해석한다. ① 사주 콘텐츠는 서버가 `ftCalculateSaju`+`ftFullAnalysis`로 풀분석 재계산(음력 정확), ② 일진·월간달력·행운(시간/색/방위/숫자)·topArea·주말은 온디바이스 엔진값을 payload로 주입, ③ 점성 트랜짓은 `calculateNatal(오늘)`, 자미 생년사화는 per-star siHua, ④ daily 콘텐츠는 (id·날짜·프로필) 캐시 + 톤 warm 고정으로 화면 간 동일, ⑤ 영역은 상위 3개 날짜 시드 회전(직장/재물 편중 탈피) + 주말 업무영역 제외. **검증은 컴파일/골든이 아니라 배포 후 실제 호출 출력 대조로 한다.**
**근거**: 사용자 반복 지적 — 컴파일·골든 통과만으로 "검증"이라 했으나 실제 출력엔 환각/모순/단조(직장·재물)/요일무시가 남아 있었음. 엔진 무결성(계산)과 출력 정확성(LLM 해석)은 별개이며, 후자는 출력을 직접 까봐야 잡힘.
**대안 검토**: ① 앱이 FullAnalysisResult 전체 직렬화 — 형태 방대·취약으로 반려, 서버 재계산 채택 ② LLM 자체 추론 신뢰 — 환각으로 반려 ③ 톤별 daily 캐시 — 화면 간 톤 불일치로 톤 무관 캐시 채택
**관련 파일**: saju-api `app/api/saju/content/[id]/route.ts`, `app/api/daily/interpret/route.ts`, `lib/ai/now-context.ts`, `lib/ai/format-{saju,natal,ziwei}-for-ai.ts`, `lib/ai/prompts/content/*`; iOS `App/AppState.swift`(dailyAreas·todayDailyPayload·cachedDailyStream), `App/AIProxyClient.swift`
**남은 과제**: daily-one-liner가 `BASE_KNOWLEDGE` 장문 강제로 3줄 미반영 — 메뉴 제거(달빛편지와 중복) 또는 BASE 예외 결정 대기
**관련**: DEC-014(일일운세 자체 분기), DEC-017(홈 한 줄 하이브리드)

---

### DEC-020: 글로벌 출생지 지원 — 세계 87개 도시 큐레이션 (2026-06-29)

**결정**: 앱이 글로벌 대상임에도 출생지가 한국 20개 도시뿐이고 타임존이 `Asia/Seoul`로 하드코딩되어 비한국 출생자의 점성/사주가 KST로 잘못 해석되던 문제를 해결. **세계 주요 87개 도시**(한국 20 + 세계 67)를 (이름·위경도·IANA 타임존·대륙 그룹)으로 큐레이션·번들. ① 점성술(natal)은 `RegionCoords.tz`를 `NatalEngine`에 전달(서울 하드코딩 제거), ② 사주는 **비한국 출생지만** `overrideTimezone`/`overrideLongitude`로 진태양시 보정 — 한국 경로(서울 tz·KDT·골든 픽스처)는 무손상 유지, ③ 서버는 `REGION_DATA` 마스터 테이블(앱과 1:1 정합)에서 타임존·좌표·그룹 파생, 사주 경도는 한국 골든값 고정·세계는 파생, content 라우트 natal 재계산에 region 좌표·타임존 주입. 검색형 지역 피커를 온보딩·마이 공용으로 신설.
**근거**: 사용자 지적 — "글로벌인데 왜 한국 도시만 있어?". 출생시각을 출생지 타임존으로 해석하지 않으면 ASC/MC(점성)와 진태양시(사주)가 전부 틀어짐. 큐레이션 방식 채택(전수 지오코딩 대비 범위 명확·오프라인·앱스토어 심사 단순).
**대안 검토**: ① 전체 지오코딩(도시 자유입력+좌표 API) — 오프라인 불가·심사 복잡으로 반려 ② 타임존 버그만 우선 수정 — 도시 목록 글로벌화 없이는 반쪽으로 반려 ③ 앱이 타임존을 payload로 전송 — 서버가 region→tz 룩업(REGION_DATA)으로 자체 해결 가능해 불필요
**검증(출력 레벨, DEC-019 원칙)**: 동일 벽시계(1990-06-15 14:30) 진태양시 — 서울 -30분(기존 불변)·뉴욕 -54분·런던 -59분(시주 乙未→甲午로 바뀜)·시드니 +7분. 엔진 골든 13건(iOS)·vitest 236건(서버) 통과로 한국 경로 불변 확인. `vercel --prod` 배포 후 `daltokkie.vercel.app` 뉴욕 출생 요청 → HTTP 200 + 실제 사주 콘텐츠 스트리밍.
**관련 파일**: iOS `App/Models/UserProfile.swift`(RegionCoords 87도시·tz·grouped), `App/AppState.swift`(ensureNatal tz·ensureSaju override), `App/Views/Misc/RegionPicker.swift`(신설), `App/Views/OnboardingView.swift`·`TalismanMyViews.swift`(피커 연결), `Engine/Sources/SajuKit/SajuCalculator.swift`(override 파라미터·timezoneOffsetMin tzId판); saju-api `lib/saju/constants.ts`(REGION_DATA/COORDS/TIMEZONES/GROUPS), `app/api/saju/content/[id]/route.ts`(natal 재계산 region 주입)
**관련**: DEC-016(온디바이스 렌더), DEC-019(엔진값 주입·출력 검증)

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
