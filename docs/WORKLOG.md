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

#### 10. 하단 탭바 구조 검토 → 중앙 배지 높이 정렬 (2026-06-13)
- **경과**: 사용자가 "하단 탭바를 iOS 표준 SwiftUI 탭바로" 요청 → 중앙을 일반 탭 아이템(`Label`/`Image`)으로 여러 차례 전환 시도
- **문제**: 표준 `.tabItem`은 아이콘 크기를 시스템이 강제(~25pt)해 "큰 중앙 토끼 + 표준 탭바"가 양립 불가 → 중앙 아이콘이 작아짐. 임의 변경 반복으로 혼선
- **사용자 결정**: "마지막 커밋으로 원복" → `git restore --source=HEAD App/Views/MainTabView.swift` 로 원래 CenterBadge(돌출 배지) 복원
- **최종 요청·반영**: "중앙 배지 높이를 다른 아이콘과 맞춰줘" → `CenterBadge.offset(y: -20)`(돌출) → `offset(y: 0)`(같은 높이) 한 줄 변경
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드·설치·실행, 중앙 배지가 돌출 없이 다른 탭 아이콘과 같은 높이 정렬 확인 ✅
- **커밋**: `6314dd3` (MainTabView.swift)
- **결정 기록**: DEC-007 (DEC-001 갱신 — 배지 유지하되 비돌출)
- **교훈**: 표준 탭바 ↔ 큰 중앙 아이콘은 기술적으로 양립 불가. 요청 범위를 벗어난 임의 디자인 변경 반복 금지 — 불확실하면 먼저 질문

#### 11. 행운 아이콘 한글→ASCII 정리 + assets-src 이관 (2026-06-14)
- **요청**: `~/Desktop/Dal Tokkie/아이콘`(카테고리별 한글 파일명)을 앱 개발에 쓸 수 있게 이름 정리 + 프로젝트로 이관
- **결정**(사용자 확인): 영어 의미명 (`color-green`, `place-library`, `dir-north`, `item-01`)
- **작업**:
  - 색깔25·장소24·방향9·운세아이템10을 ASCII 이름 + 360px(@2x)로 `assets-src/<카테고리>/`에 복사(원본 보존)
  - `App/Assets.xcassets` 한글 imageset 전부 제거 → ASCII 재생성 (잔여 한글 0)
  - `LuckyAssets.swift` colorMap/placeMap 값을 영어 에셋명으로 갱신
  - `prepare-assets.sh`: Desktop 카테고리 블록 제거(→assets-src 출처), assets-src 임포트 하위폴더 재귀로 보강
  - 함께: 탭바 중앙 배지 `offset(y:4)`·달토끼 이미지 `0.9`배
- **함정**: 셸이 zsh(배열 1-인덱스)라 첫 변환에서 매핑 오프바이원 발생 → bash 강제(0-인덱스)로 정정, 폴더 번호와 일치 검증
- **검증**: 빌드 성공, 홈 행운 아이템 일러스트 정상 렌더(폴백 아님)
- **커밋**: `0d0c61e` (352파일) / **결정**: DEC-008

#### 12. 오늘의 행운 아이템 — 컬러를 유리구슬(orb) 이미지로 교체 (2026-06-20)
- **요청**: "오늘의 행운 아이템 컬러를 orb 이미지로 교체해줘"
- **작업**:
  - 5×5 유리구슬 마블 그리드(`orb-r{행}c{열}`) 25개를 `assets-src/orbs/` 원본 + `Assets.xcassets` imageset 25개로 등록
  - `LuckyAssets.colorOrbMap`(오행 25색 → orb) + `colorOrb(_:)` 신설
  - `HomeView` 컬러 카드: `colorOrb(...) ?? colorAsset(...)` 폴백 체인 (orb 우선, 없으면 기존 color-* 일러스트)
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·설치·실행, 홈 컬러 항목이 SF Symbol 폴백이 아닌 실제 orb 이미지(갈색→orb-r3c2)로 렌더 확인 ✅
- **미해결(확인 필요)**: `colorOrbMap`에 그리드 색 부족으로 인한 **중복 매핑 3쌍** — `황토색`+`아이보리`→r3c5, `베이지`+`골드`→r3c1, `라이트그레이`+`차콜`→r4c3 (25색 중 22종만 시각 구분). 주석에 "근사"로 명시됨
- **후속 메모**: `prepare-assets.sh`는 orbs를 자동 처리하지 않음 (imageset 수동 등록 상태) — DEC-008 재현성 원칙상 추후 보강 대상

#### 13. 홈 UI 다듬기 + 홈 타이틀 Poppins 적용 (2026-06-20)
- **요청**(연속): ① 행운 아이템 카드 안쪽 점(`...`) 인디케이터 제거 ② 운세 컨디션 카드 별점 아래 게이지 바 제거 ③ "자세히 보기" 버튼 축소 ④ 홈 타이틀 `DAL TOKKIE`(대문자 시스템 세리프) → `dal tokkie`(소문자 Poppins)
- **①②③ 변경**: `HomeView.luckyCard` 점3개 HStack 삭제 / `HomeConditions.ConditionCard` 게이지 바(GeometryReader) 삭제 / "자세히 보기" 폰트 13→11·패딩 축소·chevron 11→9
- **④ 폰트 작업** (사용자 선택: Poppins 번들 = The Coffee 룩 정확 매칭):
  - `App/Fonts/Poppins-Bold.ttf` 번들 (Google Fonts, OFL 1.1) — PostScript명 `Poppins-Bold`
  - `Theme.swift`: `DT.geo(_:)` 토큰 + `DTFonts.register()`(런타임 등록, `import CoreText`) 추가
  - `DalTokkieApp.init()`에서 `DTFonts.register()` 호출 — Info.plist UIAppFonts 대신 런타임 등록 (`GENERATE_INFOPLIST_FILE: YES` 유지 위해)
  - `HomeView` 헤더: `Text("dal tokkie").font(DT.geo(24)).tracking(0.5)`
  - `xcodegen generate`로 .ttf를 번들 리소스에 반영
  - `NOTICE.md`에 Poppins OFL 고지 추가
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·설치·실행. 번들에 `Poppins-Bold.ttf` 포함 확인, 타이틀이 Poppins 소문자(둥근 a·o·d)로 렌더 — 폴백 아님 ✅
- **결정 기록**: DEC-009

#### 14. 앱 전체 타이포 Pretendard 단일 통일 (2026-06-20)
- **요청**: "이 서비스 특성상 어떤 폰트로 통일하는게 좋을까" → 분석 후 사용자 결정 **"Pretendard 단일"**
- **분석 요지**: 운세/사주 = 감성 카피 + 한글 95%. 시스템 폰트(SF/New York)는 한글이 기기별 폴백(산돌고딕/AppleMyungjo)이라 브랜드 일관성 약함. Pretendard(OFL)는 한국 앱 표준·고가독성·라틴까지 커버
- **변경**:
  - `App/Fonts/Pretendard-{Regular,Medium,SemiBold,Bold}.otf` 번들 (실제 사용 weight 4종만)
  - `Theme.swift`: `DT.serif`/`DT.sans` 모두 Pretendard로 매핑(`pretendard(weight)` 헬퍼 — weight별 정적 파일 직접 참조해 faux-bold 방지). `DTFonts.register()` Pretendard 4종 등록
  - 호출부 99곳(serif 22·sans 77)은 토큰 시그니처 유지로 **무수정**
  - **DEC-009(Poppins) 되돌림**: `DT.geo` 제거, 타이틀 `DT.geo(24)`→`DT.sans(24,.bold)`, `Poppins-Bold.ttf` 삭제, `NOTICE.md` Poppins→Pretendard 교체
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·설치·실행. 번들에 Pretendard 4종 포함·Poppins 제거 확인, 한글/숫자/타이틀 전부 Pretendard 렌더 ✅
- **결정 기록**: DEC-010 (DEC-009 supersede)

#### 15. 홈 헤더 타이틀 중앙 정렬 + CTA 버튼 사이즈 통일 (2026-06-20)
- **요청**: ① `DAL TOKKIE` 타이틀을 화면 정중앙으로(좌측 치우침 해소) ② 배너 "오늘의 부적 보기" 버튼을 "자세히 보기"와 동일 사이즈/모양 + 하단 정렬
- **원인**: 헤더가 `좌(아이콘1)–Spacer–타이틀–Spacer–우(아이콘2)` 구조라 우측 그룹이 넓어 타이틀이 왼쪽으로 밀림
- **변경**(`HomeView.swift`):
  - 헤더를 `ZStack`으로 — 타이틀 `.frame(maxWidth:.infinity, alignment:.center)`(화면 기준 중앙) + 아이콘 HStack(좌/우) 오버레이
  - CTA 버튼: `DT.sans(12,.bold)`·chevron10·패딩14/9 → `DT.sans(11,.semibold)`·chevron9·spacing3·패딩12/6 (자세히 보기와 동일). 색(흰+핑크)은 어두운 배너 가독성 위해 유지. `HStack(alignment:.bottom)`로 하단 정렬
  - 상단 바 배경: 헤더 `DT.bg`(#F8F2E8 크래프트지=누르스름) → **흰색**, `ignoresSafeAreaEdges:.top`으로 상태바 영역까지 채움 (페이지 본문 크래프트지는 유지)
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·실행, 타이틀 정중앙·CTA 버튼 축소/하단 정렬·상단 바 흰색 확인 ✅

#### 16. 상단 편지 아이콘 → 당근 아이콘 교체 (2026-06-20)
- **요청**: 헤더 우측 편지(envelope) 아이콘을 에셋 당근 아이콘으로
- **변경**(`HomeView.swift`): `Image(systemName:"envelope")`(SF Symbol) → `Image("carrot-icon")`(컬러 에셋, resizable·scaledToFit·24x24). "6" 알림 배지 유지. 컬러 일러스트라 `foregroundStyle` 제거
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·실행, 당근 아이콘 컬러 렌더 확인 ✅

#### 17. 상단 히어로 카드 코너 꺾쇠 장식 제거 (2026-06-20)
- **요청**: 메인 상단 카드 4모서리의 꺾쇠(┌ ┐ └ ┘) 제거
- **변경**(`HomeView.swift`): `cornerFrame`에서 코너 브래킷 `GeometryReader`/`Path` 오버레이 삭제. 둥근 테두리 stroke(`DT.line`)는 유지
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·실행, 꺾쇠 사라지고 테두리 유지 확인 ✅

#### 18. 홈 상단 카드 주간 페이징(7일) + 요일 점 인디케이터 (2026-06-20)
- **요청**: 상단 카드 아래 7개 점(요일) + 카드 좌우 스와이프 페이징 / 오늘 요일은 다른 색 점 + 현재 페이지도 점에 표시 / 내용도 해당 요일로 / (후속) 카드 좌우 간격 + 오늘을 점 정중앙에
- **데이터**(`AppState`): 5일(오늘±2) → **오늘 중심 7일(오늘±3)**. 오늘이 항상 index 3(7개 점의 정중앙). `fortunes` 공유라 "자세히 보기" 차트도 주간 7포인트로 자연 확장
- **UI**(`HomeView`):
  - `heroBanner(_ bundle:)` → `heroBanner(_ day:_ index:_ bundle:)`로 리팩터 — 모든 `bundle.today`를 선택 요일 `day`로, `trendText`는 인덱스 기준(월요일격 첫날은 추세 "")
  - 카드 높이 `heroHeight=360`으로 통일(편지 글귀가 제목3줄·본문2줄로 균일) → 페이저 정렬·클리핑 방지
  - `heroPager`: `TabView(.page, indexDisplayMode:.never)` + 커스텀 `weekDots`. selection 바인딩 `selectedDayIndex ?? todayIndex`
  - `weekDots`: 오늘=다른 색(`DT.accent`), 현재 페이지=길쭉한 캡슐(16x6, 비오늘은 `DT.inkSoft`). 둘 겹치면 accent 캡슐
  - 캐러셀 간격: 각 페이지 카드 `.padding(.horizontal,7)` + TabView `.padding(.horizontal,-7)`(카드 본체 폭 유지하며 카드 사이 14pt 간격)
- **검증**: 빌드 성공. 오늘(6/20 토) 카드+정중앙 분홍 캡슐 확인 ✅. selectedDayIndex 기본값을 임시로 0(월)으로 바꿔 검증 → 6/15 MON·점수54·편지 변경·첫 점 선택 캡슐·오늘 점 분홍 유지 확인 후 nil 원복 ✅
- **결정 기록**: DEC-011
- **참고(범위)**: 페이징은 "상단 카드"만 — 단, 행운 아이템/컨디션 섹션도 선택 요일 연동(WORKLOG 후속)

#### 19. 페이징 시 행운 아이템·컨디션 연동 + "달빛 편지" 라벨 요일화 (2026-06-20)
- **요청**: ① 카드 페이징 시 "오늘의 행운 아이템"·"오늘의 운세 컨디션"도 함께 페이징 ② "오늘의 달빛 편지" 라벨을 보는 요일에 맞게
- **①**(이미 반영): `Engine` `DailyFortuneBundle.fortunesLucky[]`(일자별 행운 아이템) 추가, `HomeView` 두 섹션이 선택 인덱스(`sel = selectedDayIndex ?? todayIndex`) 받아 `fortunesLucky[i]`/`fortunes[i].cards` 렌더
- **②**: heroBanner 라벨을 `"\(dayLabel)의 달빛 편지"`/`"\(dayLabel)의 행운지수"`로 — 오늘=「오늘」, 그 외=한글요일(`weekdayKo`, 예 "일요일의 달빛 편지", "목요일의 행운지수")
- **검증**: 빌드 성공. 오늘=「오늘의 …」, 스와이프 시 6/21 「일요일의 달빛 편지」·6/18 「목요일의 달빛 편지/행운지수」+ 점수·글귀·행운 아이템 변경, 점 인디케이터 이동·오늘 점 유지 확인 ✅

#### 20. 음료·장소·향기·아이템 항목별 전용 아이콘 적용 (2026-06-21)
- **요청**: `~/Desktop/Dal Tokkie/아이콘`의 음료수/장소/향기/아이템 디렉토리에 새로 만든 항목별 아이콘을 프로젝트에 적용
- **작업**: 각 카테고리 25개(=오행5×5) → ASCII 번호명 imageset 100개 생성
  - `drink-01..25`, `place-01..25`, `scent-01..25`, `litem-01..25` (NN은 엔진 `elementItems` 오행순)
  - 운세 컨디션이 쓰는 `item-01..10`과 충돌 피해 행운 아이템은 **`litem-`** 접두사
  - `assets-src/{drinks,places,scents,luckyitems}`에 원본 보존(DEC-008)
  - `LuckyAssets`: `drinkMap/placeMap(신규)/scentMap/luckyItemMap` + `drinkAsset/placeAsset/scentAsset/luckyItemAsset`. 대표 아이콘 `itemAsset`/`ItemCategory` 제거
  - `HomeView`: 음료/장소/향기/아이템 카드가 항목별 아이콘 사용(폴백 SF Symbol 유지)
  - 구버전 word 기반 `place-<이름>` imageset 24개 삭제
- **함정**: 한글 파일명 NFD + 표기 불일치(`햇볓쬐기`↔`햇볕 쬐기`, `베이커리까페`↔`베이커리 카페`, `썬글라스`↔`선글라스`) → Python NFC 정규화 + 공백제거 매칭 + 오버라이드 3건으로 100/100 매칭
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공·실행, 음료(곡물라떼)·장소(전통시장)·향기(바닐라향)·아이템(갈색노트) 전용 아이콘 렌더 확인 ✅
- **결정 기록**: DEC-012
- **후속**: `prepare-assets.sh`는 신규 카테고리 미처리(수동 imageset) — orbs와 함께 추후 보강
- **수정(바닐라향)**: scent-11 내용 비율 1.69(와이드)+상하 여백 과다로 홈에서 작고 납작해 보임 → 1차 트림
- **수정(아이콘 정렬 일괄)**: 각 PNG의 투명 여백·비율 불균일로 홈 카드에서 아이콘 바닥선·크기·가로중앙이 들쭉날쭉 → **125개(drink/place/scent/litem + orb) 일괄 정규화**:
  - 알파 bbox 트림 → 정사각 캔버스 S=220에 box=176로 비율유지 스케일 → 하단 22px **바닥 정렬**
  - 가로 중앙: 처음 bbox중심 → 비대칭 일러스트(향기 꽃 좌측 등) 어긋남 → **불투명(α≥200) 픽셀 무게중심** 기준으로 재정렬(반투명 그림자 제외 → orb는 구 중심 유지). 위치만 이동(리샘플 없음)
  - imageset+assets-src 동시 갱신. 홈에서 크기·바닥선·가로중앙 정렬 확인 ✅

---

## 남은 작업 (STATUS.md에서 이관)

| 우선순위 | 작업 | 상태 |
|---------|------|------|
| 1 | ~~탭바 중앙 배지 높이 시뮬레이터 확인 및 미세 조정~~ | ✅ 완료 (2026-06-13, 커밋 6314dd3 — offset 0 정렬) |
| 2 | ~~Noto Sans/Serif KR 폰트 번들~~ → **Pretendard 단일 통일로 대체 완료** | ✅ 완료 (2026-06-20, WORKLOG #14, DEC-010) |
| 3 | 행운 아이콘 웹 SVG 125종 대응 (현재 SF Symbols 5종) | 미착수 |
| 4 | 타로/궁합 AI 해석 연결 | 미착수 |
| 5 | 사주 상세 신살/공망/합충형파해/지장간 섹션 추가 | 미착수 |
| 6 | 마이 탭 고도화 | 미착수 |
| 7 | 앱스토어 메타데이터/심사 대응 | 미착수 |

## 주의사항

- 달토끼는 App Store 기준 "fortune telling" — 포화 카테고리이므로 고유 가치 입증 필요 (App Store Review Guidelines 4.3)
- 디자인 토큰: 배경 #f8f2e8, 카드 #faf6ee, 포인트 #d4789c, 텍스트 #2a2520/#8b7e6a, 탭바 보더 #e8dcc4, 밤하늘 #2a2f50
- 천체력은 라이선스 클린 재구현 (AGPL 의존성 없음)
