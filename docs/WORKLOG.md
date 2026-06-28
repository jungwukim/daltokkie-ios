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
- **최신 빌드**: 성공 (2026-06-28, iPhone 16 Pro). 최근: **운세 달력 상세화**(간지·십성 칸 + 날짜 탭 그날의 기운 + 전체 화면·홈 달력 버튼, #57)·**사주 상세 일목요연화**(명식표+신살·길성 표, DEC-018)·**홈 히어로 '오늘의 운세 한 줄' 하이브리드**(AI 한 줄 7일 캐시 + 규칙 폴백, DEC-017)
- **엔진 테스트**: 13건 전부 통과 (단, **daily-fortune 픽스처는 자체 알고리즘 기준으로 재생성** — saju-api 비트재현 아님, DEC-014. 코어 사주/천체력/자미두수 픽스처는 정통 재현 유지)
- **AI 서버**: `saju-api`(daltokkie.vercel.app) 배포·동작 중. `/api/daily/interpret`에 `style:"oneline"` 모드 포함(커밋 a2b3d4a)

## 작업 히스토리

#### 60. AI 콘텐츠 명리/점성/자미 정확도 전수 감사 + 1차 수정 (2026-06-28)
- **요청**: "AI가 엔진 계산이 아니라 환각·추측으로 만드는 콘텐츠 전부 찾아 고쳐라" (사주·자미·점성)
- **감사(Explore 4도메인 병렬)**: 공통 근본 원인 = **온디바이스/서버 엔진이 정확히 계산하는데 LLM에 안 넘겨 다시 추측**. 발견:
  - 사주: `content/[id]` 라우트가 `analysis`(십성·용신·격국·신살·대운·월간달력)를 안 받아 `formatSajuForAI`가 "LLM이 알아서 분석" 폴백 → ~20개 콘텐츠 환각/부분. lucky-day·fortune-calendar는 날짜별 일진까지 LLM이 지어냄
  - 자미: `ziwei-sihua` 생년사화를 포맷터에 안 넘김(환각). liunian/daxian/monthly 등은 라우트가 `new Date().getFullYear()`로 앱 currentYear 무시
  - 점성: `natal-transit`·`natal-monthly`는 현재 트랜짓(행성 위치) 계산이 없어 LLM이 환각
  - 멀티: life-roadmap/graph 전체 대운이 포맷터에 없음(현재 대운만)
- **1차 수정(이번 커밋)**:
  - **사주: 서버가 정통 엔진으로 풀분석 재계산** — 라우트 saju 분기에서 `ftCalculateSaju`(음력·진태양시·지역 정확 처리)+`ftFullAnalysis` → `formatSajuForAI(analysis)`. 앱은 `isLunar/isLeapMonth/useTrueSolarTime` 전달. → 십성·용신·격국·신살 전부 정확
  - **포맷터**: 전체 대운 타임라인 추가(life-roadmap/age-guide/전환점), lucky-day·fortune-calendar엔 **실제 월간 달력(일별 간지·점수)** 주입 → 날짜 환각 제거
  - **자미·멀티 연도 버그**: `currentYear ?? new Date()`로 앱 시점 존중
- **검증**: 서버 tsc + **골든 236건 전부 통과**(엔진 무결성). 앱 빌드 ✅

#### 61. AI 콘텐츠 정확도 2차 — 자미 생년사화 + 점성 트랜짓 (2026-06-28)
- **자미 생년사화**: `format-ziwei-for-ai`에 생년사화 요약 섹션 추가(per-star `s.siHua` 집계). ziwei-sihua가 이제 실제 사화 배치 사용
- **자미 음력 정확도 버그**: 자미 content가 `profile.month/day`(음력 원본)를 보내 서버 `createChart`(양력 기대)가 음력 출생을 오계산 → **앱이 양력 변환값 전달**(`AppState.solarBirthYMD()`, `isLunar:false`)
- **점성 트랜짓**(가장 큰 신규): natal-transit·natal-monthly가 현재 행성 위치 없이 LLM 환각 → 라우트가 `calculateNatal(오늘)`로 **실제 트랜짓 계산**, `formatNatalForAI(transit)`에 주입, 두 프롬프트는 "제공된 트랜짓만 사용(추정 금지)"로 수정. 어스펙트 슬라이스 20→40
- **검증**: 서버 tsc + 골든 236 + 앱 빌드 ✅
- **결과**: 사주·자미·점성 daily/시점 콘텐츠 전부 엔진 계산값 기반. **saju-api 재배포 시 적용**

#### 59. daily AI 콘텐츠 일진 정확도 + 홈 자세히 보기 = 오늘의 운세 (2026-06-28)
- **배경**: 사주 "세부 해석"의 daily 콘텐츠(오늘의 한마디·오늘의 운세·할일피할일 등)가 `/api/saju/content/[id]`에서 **그날 일진(日辰)을 계산하지 않아** LLM이 오늘 기운을 추론(환각) → 명리 정확도 미흡. (원국 팔자·십성·용신은 엔진 정통 계산, '오늘' 시점만 부정확)
- **해결(앱→서버 데이터 전달)**: 앱 온디바이스 `DailyFortuneEngine`이 계산한 정확한 일진(일주·십성·12운성·점수·영역 컨디션·합충·신살)을 `AppState.todayDailyPayload()`로 만들어 `AIProxy.content(daily:)`로 전송. 서버 `now-context.buildDailyJinContext()`가 이를 프롬프트에 주입(콘텐츠 라우트 `daily` 스키마 추가). → **모든 daily-* 콘텐츠가 정확한 일진 기반**
- **홈 자세히 보기 = 오늘의 운세**: `LuckyIndexDetailView` 최상단에 **AI 오늘의 운세(daily-fortune) 인라인 스트리밍**(점수 헤더 + 오늘의 에너지·분야별·행운 포인트·한줄 정리, `FormattedAIText`/`AISkeleton`). 이전 점수+별점 카드는 이 AI 콘텐츠로 대체. 기존 5일 흐름·행운 시간대 유지
- **검증**: iOS 빌드·서버 tsc ✅. TEMP로 자세히보기 AI 오늘의 운세 렌더 확인(51점 + 분야별) 후 원복
- **주의**: 일진 정확도·구체형 달빛 편지 모두 **saju-api 재배포 필요**(미배포 시 구버전 동작)

#### 58. 달빛 편지 = 오늘의 한마디(구체형) + 자세히 보기에 오늘의 운세 (2026-06-28)
- **피드백**: 홈 달빛 편지(AI 시적 비유)가 "너무 뜬구름·갑분싸". 사주 페이지의 오늘의 운세/한마디 톤이 더 맞음
- **달빛 편지 구체화**: 서버 `/api/daily/interpret` oneline 프롬프트를 **비유 금지·영역(재물·연애·건강 등) 콕 집는 구체적 한마디**로 변경(예: "재물 흐름이 든든한 하루 / 무리한 지출만 조심하면 좋아요 / 필요한 데 먼저 쓰고 나머진 모아둬요"). 점수·컨디션과 앞뒤 맞게
- **캐시 무효화**: iOS `heroLineCacheKey` → `heroAILine.v2`로 버전 올려 기존 시적 캐시 폐기(재배포 후 첫 진입 시 구체형 재생성)
- **자세히 보기 = 오늘의 운세 + 기존**: 홈 `LuckyIndexDetailView` 최상단에 **오늘의 운세 카드(점수·등급 + 영역별 컨디션 별점)** 추가, 타이틀 "오늘의 행운지수"→"오늘의 운세". 기존 5일 흐름·행운 시간대 유지
- **검증**: iOS 빌드·서버 tsc ✅. TEMP로 자세히보기(51점+영역 컨디션+5일흐름+시간대) 렌더 확인 후 원복
- **주의**: 구체형 달빛 편지는 **saju-api 재배포 필요**(미배포 시 구버전 시적 한마디 반환). v2 캐시라 배포 후 자동 갱신

#### 57. 운세 달력 상세화 — 간지·십성 표시 + 날짜 탭 상세 (2026-06-28)
- **요청**: "운세 달력이 그냥 날짜랑 점만 있다 → 자세히" (참고: 만세력 달력 스크린샷)
- **변경**(`MonthlyFortuneCalendar` 신규, `SajuAnalysisSections`): 각 칸에 **날짜 + 간지(한자, 오행 색) + 십성 + 점수 점**. 기존 날짜+점만 → 정보량↑
- **날짜 탭 → 그날의 기운 상세**: 간지(한자+한글)·십성·점수(색)·한 줄 경향(십성 기반 매핑 + 점수 톤). 선택 칸 강조 보더, 재탭 해제
- `monthlyCalendarCard` computed → 상태 보유 위해 별도 `View` 구조체로 분리(@State 선택일). 간지 한자/오행은 `SajuTables`로 변환
- **전체 화면 달력**(`FortuneCalendarView`): 월 전환(◀▶)·범례(좋음/보통/주의/휴식)·날짜 탭 상세. **홈 헤더 달력 아이콘 → 버튼화 → fullScreenCover**로 진입(기존엔 동작 없던 아이콘). 인라인 달력 헤더에도 전체화면 확대 버튼 추가(`showHeader`로 인라인/풀스크린 헤더 분기)
- **버그 수정**: 풀스크린에서 `LazyVGrid` 높이 collapse로 달력 중간만 보이던 문제 → **주(週) 단위 수동 HStack 그리드**로 교체(인라인/풀스크린 모두 전체 월 정상 표시)
- **검증**: 빌드 ✅. TEMP로 인라인 달력·탭 상세(15일 "庚申·정재의 날·54점")·풀스크린(1~30일 전체·월 전환·범례) 렌더 확인 후 전부 원복

#### 56. 사주 상세 일목요연화 — 명식표 + 신살·길성 표 통합 (2026-06-27)
- **요청**: "사주 페이지가 너무 어렵다 → 참고 이미지(만세력 표)처럼 일목요연하게" (이미지 그대로 복사 X)
- **① 명식표(命式表)**(`SajuChartTable`, `SajuDetailView`): 시·일·월·년 4열 × 천간·십성·지지·십성·지장간·12운성·12신살 7행 통합표. 오행 색·음양(±목/-수), 일간(생일) 열 은은한 강조 틴트, 일간 십성=“(본인)”. 흩어져 있던 **십성 배치표·12운성 카드 제거**(`tenGodRow`/`stageRow` 헬퍼 삭제)
- **② 신살과 길성 표**(`sinsalCard` 재작성, `SajuAnalysisSections`): 상단 요약 줄(전체 신살·길성) + 기둥별(시/일/월/년) 표에 각 기둥 귀속 신살·길성 나열, 길신(초록)·흉살(빨강)·중성(회색) 색 구분, 없으면 ×. 기존 나열식 리스트 카드 대체(`salRow` 삭제). 12신살=`.pillar`, 특수살=`.pillarIndices`([년,월,일,시]) 매핑
- **검증**: 빌드 ✅. TEMP 루트 스왑으로 두 표 렌더 확인 후 전부 원복(작업트리 깨끗)
- **미적용(선택)**: 히어로 큰 기둥 타일 ↔ 명식표 기둥 중복 제거, 지장간 상세(비율) 카드 유지 여부 — 사용자 피드백 대기

#### 55. 홈 달빛 편지 → 오늘의 운세 한 줄 요약 (하이브리드: AI 한 줄 캐시 + 규칙 폴백) (2026-06-27)
- **요청 흐름**: "달빛 편지를 오늘의 운세 한 줄 정리로" → 인앱 토글 A/B → **B(점수 기반 요약)** 확정 → 토끼 축소·한 줄·박스 392→282·날짜라인 우측 정렬로 공간 절약 → "며칠 같은 문구"·"몇 번 쓰면 반복" 지적 → **최종: AI 한 줄(하루 1회 캐시) + 오프라인/실패 시 규칙 기반 폴백**
- **UI 정리**: 시적 A안(`MoonLetters.generate`)·`HeroLetterStyle` 토글 제거. 히어로 제목 한 줄(`lineLimit(1)`+축소), 토끼 220→150, 달빛 편지 라벨을 날짜 라인 우측 끝으로, 박스 높이 392→**282**, 본문 `lineLimit(2)`+축소(AI 길이 편차 흡수)
- **규칙 폴백**(`MoonLetters.summary`): 점수 구간+최고 영역, 날짜 시드로 변형 순환(`areaBest`/`areaCaution`). "다만" 접두 제거
- **AI 한 줄(주력)**: 서버 `/api/daily/interpret`에 **`style:"oneline"` 모드 신설**(별도 레포 saju-api, 커밋 a2b3d4a·배포 완료) — 정확한 그날 일진(일주·십성·12운성·점수·합충·신살) 기반 **짧은 3줄**(비유 14자/의미·행동 20자). 짧은 3줄 형식만 수용하는 검증(`parseHeroLine`: 1~3줄·첫줄≤20자·각줄≤32자)으로 구버전/이상 출력 거부→폴백
- **주간 7일치 프리페치**(`AppState.ensureHeroLines()`): 오늘만이 아니라 **페이저 범위(오늘±3, 7일) 한 번에** 생성→날짜별 `UserDefaults` 캐시(키=날짜+프로필). 이후 같은 날·요일 스와이프 모두 즉시. `heroLines: [날짜:MoonLetter]` 딕셔너리, 진행중 `Set`로 중복 방지
- **레이아웃 마감**: 토끼 `offset y 18`로 내려 밑선이 박스 하단에 클립(부유선 제거)
- **검증**: iOS 빌드·서버 tsc 클린. 프로덕션 라이브 — oneline 정상, 7일치(06-24~30) 각기 다른 AI 3줄 캐시 확인, 히어로 표시 ✅ (첫줄=큰 글귀, 나머지=본문)

#### 54. 궁합 입력 재설계 — 나↔상대 + 상대 시간 (2026-06-27)
- **피드백**: "내 정보가 왜 안 나오나" + "화면이 구리다"
- **변경**(`CompatibilityView`): 상단 **나↔상대 헤더**(내 프로필 생년월일·일간·띠 표시 + 하트, 상대는 입력 실시간/계산후 일간·띠) + 온보딩 `field()` 스타일 입력(성별·생년월일 3피커·시간 토글+시/분). 4피커 줄바꿈 깨짐 해소
- **상대 태어난 시간** 입력 추가(모름 시 nil) → 자정 경계 일주 정밀도↑
- **사주 상세 하단부 QA**: 공망·합충형파해·삼합·천간합충·지장간·세운·오늘운세(별점=1+score/100×4 일치)·월운·운세달력 — 버그 없음 확인

#### 53. 타로 카드 뒤집기 높이 고정 (2026-06-27)
- 뒤집으면 이름·키워드가 추가돼 셀이 커지고 카드가 위로 올라가던 문제 → 이름·키워드 영역 항상 고정 높이(34) 예약(뒤집기 전 opacity 0). 셀 높이 일정·카드 상단 정렬

#### 52. 은색 동전(litem-20) 이미지 교체 (2026-06-27)
- 사용자 제공 입체 3D 동전으로 교체. 기존 footprint(220 캔버스·하단 baseline·콘텐츠 높이 176·중앙)에 맞춰 정규화(DEC-012 일관). assets-src/luckyitems 원본 갱신

#### 51. AI 연도 정확도 마감 — 서버 프롬프트 주입 + 배포 (2026-06-27, saju-api 별도 레포)
- **원인 확정**: 서버 `contentRequestSchema`가 currentYear/timeline 등을 zod로 드롭 + 프롬프트에 현재 날짜 앵커 없음 → LLM이 2024 환각
- **수정(saju-api)**: `lib/ai/now-context.ts`(`buildNowContext`/`nowContextFromBody`, 앱 값 우선·서버 Asia/Seoul 폴백) → content + interpret(saju/natal/ziwei/tarot/daily) **6개 라우트** 프롬프트 상단 주입. tsc 0 에러
- **배포·검증**: `vercel --prod` 후 라이브 검증 — 재물/연인 타이밍·점성(이번 6월)·자미(올해 丙午)·달빛·타로·사주종합 모두 **2026 기준** 정상, 표 불릿 렌더 확인
- 앱은 #50에서 이미 정확 데이터 전송 → 서버 소비까지 엔드투엔드 완결

#### 50. AI 콘텐츠 정확도 — 표 렌더·공통 컨텍스트·실제 타임라인 (2026-06-27)
- **문제**: 재물 타이밍 등에서 ① 연도 환각(2024) ② 마크다운 표 raw 깨짐 ③ 지역/날짜/나이 미전달
- **아키텍처 확인**: 계산은 전부 온디바이스 엔진, 서버(daltokkie.vercel.app/saju-api)는 **LLM 텍스트 생성 프록시**(차트 재계산 안 함). 버그=정확한 온디바이스 값을 LLM에 안 먹임
- **표 렌더(앱, 즉효)**: `FormattedAIText` 마크다운 표 파싱 — 구분/헤더행 제거, 데이터행 비어있지 않은 셀 " · " 불릿. 공용이라 전 콘텐츠 일괄
- **공통 컨텍스트**: `AIProxy.commonContext(birthYear,region)` → currentYear/today/age/koreanAge/region을 6개 엔드포인트(saju/natal/ziwei/tarot/daily/content) 전부 merge. 호출부 region 전달(타로는 appState 주입)
- **실제 타임라인**: `AppState.sajuTimelineJSON()` — 대운(실제 startYear/endYear)·세운(올해+4년)·월운(올해 12개월)을 사주 content/interpret payload에 주입 → LLM이 연도 환각 대신 엔진 계산값 사용
- **남은 일**: 서버(saju-api) 프롬프트가 timeline/context 필드를 실제 소비하도록 갱신해야 텍스트에 반영
- **검증**: 빌드 성공, 표 렌더 샘플 확인 ✅

#### 49. 히어로 톤 라이트화 — 크래프트지 하우징 (2026-06-27)
- **피드백**: 인스트루먼트 히어로(점성·자미·사주)가 너무 어둡다(앱 크림 톤과 이질)
- **사용자 선택**: 크래프트지 라이트 — 하우징을 앱과 동일 크림 카드로, 메탈/브라스/아이보리는 포인트로
- **변경**: 3개 히어로 하우징 그래파이트 radial → `DT.card`(크림) + 브라스 보더(0.30). 타이틀/식별 텍스트 cream→ink, 강조 champagne→딥브라스
  - `DarkStatChip`·`big3Cell`: 다크 칩 → **라이트 칩**(크림/브라스 틴트 + 잉크 텍스트)
  - 다크 메탈 다이얼 베젤·브라스 프레임·아이보리 셀/기둥은 유지 → "크림 종이 위 럭셔리 계기" 느낌
- **검증**(iPhone 17 Pro/iOS 26.2): 점성/자미/사주 히어로 라이트 렌더 확인 ✅

#### 48. 사주 히어로 인스트루먼트 통일 (2026-06-27)
- **요청**: 사주 상세 히어로도 같은 인스트루먼트 톤으로
- **변경**: `sajuHero` 밤하늘 보라+별 → **그래파이트 하우징**(radial 23211E→100F0E)·브라스 보더, champagne 강조
- `PillarGrid` **instrument 모드** 추가: 사주팔자 기둥을 **아이보리 타일 + 잉크 한자 + 원소색 점(천간·지지) + 브라스 보더**(출생차트 다이얼·명반 셀과 동일 언어)
- **결과**: 점성(원형 다이얼)·자미(격자)·사주(기둥) **3개 상세 히어로 모두 그래파이트·브라스·아이보리 인스트루먼트로 통일**
- **검증**(iPhone 17 Pro/iOS 26.2): 사주 히어로 렌더 확인 ✅

#### 47. 명반 절제 리파인 + 음력 입력 버그 수정 (2026-06-27)
- **피드백**: 명반 안 예쁨 + ASTRA 왜 넣음 + 음력 프로필인데 왜 음력 변환?
- **ASTRA 제거**: 레퍼런스(시계 브랜드 각인) 흉내로 임의 삽입했던 무의미 문구 — 삭제
- **명반 리파인(절제)**: 중앙 다크 플레이트→아이보리(다크홀 제거), 밝기색 네온5색→깊은 3톤, 사화 파스텔 배지→텍스트 색만, 격자 헤어라인 브라스, 라운드 프레임
- **음력 버그 수정(중요)**: ZiweiEngine/NatalEngine은 **양력 입력**(내부 solar→lunar)인데 `ensureZiwei`/`ensureNatal`이 음력 프로필을 그대로 넘겨 오인 처리 → 사주와 동일 `LegacyLunarConverter`로 음→양 선변환(`solarBirth`) 추가
  - **검증**: 음력1974-3-18 →양력1974-4-10 →엔진→음력1974-3-18 복원 ✓ / 미변환 시 음력2-25 오인(=사용자가 본 버그)
- **검증**(iPhone 17 Pro/iOS 26.2): 명반 리파인 렌더 + 기본정보 음력 3-18 정확 표시 ✅

#### 46. 자미두수 명반 인스트루먼트 톤 통일 (2026-06-27)
- **요청**: 명반도 출생차트(계기판) 같은 인스트루먼트 톤으로
- **방향**: 명반은 격자라 다이얼화 X → **재질·색 언어 통일**(그래파이트 하우징·브라스 인레이·아이보리 셀·그래파이트 중앙 플레이트)
- **변경**:
  - `ZiweiGridChart`: 셀 `DT.card`→아이보리 그라데이션, 보더 `DT.line`→브라스, 命궁 셀 champagne 틴트, 命/身 배지 브라스/스틸, 중앙 정보 라이트→**그래파이트 플레이트**(champagne 紫微斗數). 고정 인스트루먼트색(다이얼과 통일)
  - `ZiweiDetailView`: 밤하늘 히어로+별도 라이트 그리드 카드 → **단일 그래파이트 인스트루먼트 카드**(`ziweiInstrument`): 브라스 ASTRA + 브라스 프레임 명반 + 핵심 3칩
- **검증**(iPhone 17 Pro/iOS 26.2): 명반 인스트루먼트 렌더 확인 ✅. 데이터/레이아웃 무변경(표현만)

#### 45. 점성술 정확도 — whole-sign·진교점·출생지역 좌표 (2026-06-27)
- **요청**: astro-seek 교차검증 후 whole-sign 구현 / 진교점 전환 / 출생 지역을 마이페이지에서 설정해 좌표 보정
- **검증 결론**: 행성·MC는 우리 엔진 == astro-seek 일치. astro-seek는 좌표 0,0(적도)로 계산돼 ASC/하우스가 서울 기준 아님 → ASC는 서울 좌표 쓴 우리 쪽이 정확
- **엔진**:
  - `Houses.calcHouses`: **whole-sign("W")** 구현 — ASC 사인의 0°부터 30°씩 커스프
  - `NatalEngine.calculateNatal(trueNode:)`: **진교점(오스큘레이팅 승교점)** — 달 순간 위치·속도로 각운동량 h=r×v, Ω=atan2(hₓ,−h_y). 기본값 false(골든 무회귀, mean node 유지)
  - **근거**: whole-sign=표준 정의, 진교점=고전 천체역학(임의 아님). 진교점 값은 평균교점 대비 ~1.5°(±1.6° 진동 범위 내) — 외부 수치 1:1 대조는 미완(플래그)
  - **골든 13/13 통과**(P·mean node 기본값 무회귀 확인)
- **앱**:
  - `RegionCoords`(사주 region 20개와 동일 이름 + 시청 좌표), `ensureNatal`이 `coords(for: region)` + houseSystem "W" + trueNode true 사용
  - **마이페이지 '출생 지역' 메뉴** 추가 → 선택 시 캐시 무효화·재계산
  - 점성 하우스 라벨 "Placidus"→"홀사인"
- **검증**(iPhone 17 Pro/iOS 26.2): whole-sign 커스프(각 사인 0°)·진교점·지역 메뉴 확인 ✅

#### 44. 출생 차트 재해석 — 계기판형 3D + 진입 애니메이션 (2026-06-27)
- **요청**: 출생 차트가 전형적 AI 그림(보라/청록 밤하늘 + 컬러 이모지 별자리) 같다 → 고급 기계식 계기판(레퍼런스 영상: 크로노그래프·나침반)처럼 세련되게 + 애니메이션
- **레퍼런스 분석**(ffmpeg 프레임): 두툼한 메탈 베젤(베벨 음영)·유리 반사·음각 챕터링·빨간 바늘 스윕 정착
- **신규**(`NatalDialChart.swift`): 따뜻한 럭셔리 인스트루먼트 재해석 — 그래파이트 코닉 메탈 베젤 + 브라스 인레이 + 아이보리 라디얼 다이얼 + 유리 돔 하이라이트 + 음각 챕터링(5°/30°) + 행성 브라스림 마커 + ASC 옥스블러드/MC 그래파이트 바늘 + 메탈 허브. 천체 매핑(`lonToAngle`)은 검증값 유지
- **핵심 버그 수정**: 별자리 유니코드(♈…)가 iOS에서 **컬러 이모지로 렌더**되던 것("보라 배지" = AI 느낌 주범) → **U+FE0E 텍스트 변형 셀렉터**로 모노크롬 음각 글리프화
- **애니메이션**: `TimelineView(.animation)` 시간 기반 구동(Canvas는 withAnimation만으론 보간 redraw 안 됨) — 챕터링/바늘이 오버슈트 후 정착(easeOutBack), 2.4s 후 paused로 정지. 시뮬 녹화로 진입→정착 검증
- **히어로**: 밤하늘 보라+별 → 그래파이트 인스트루먼트 하우징(별 제거), 브라스 "ASTRA"
- **정리**: 미사용 `NatalWheelChart.swift` 삭제. (사주/자미 히어로의 StarField는 유지 — 이번 범위 아님)

#### 43. 다크 모드 마감 — 의미색 분기 + 상단 바 (2026-06-26)
- **요청**: 의미색까지 dtDyn 분기 + 상단 바(헤더+상태바)가 다크에서 흰색이라 안 어울림
- **상단 바**: `DT.topBar = dtDyn(0xFFFFFF, 0x1B1D26)` 신설, `HomeView` 헤더 배경 `Color.white` → `DT.topBar`(상태바 세이프에어리어까지)
- **의미색 dtDyn 분기**(라이트→다크 밝게 보정): `sajuElementColor`(오행5), `natalElementColor`(원소4), `aspectColor`(어스펙트5), 궁합 강점/약점/조언+scoreColor, `SajuAnalysisSections` elColor/relColor/salColor/scoreColor, `ZiweiGridChart` brightnessColor, HomeConditions 카테고리5
- **유지**: 밤하늘 히어로 고정색, siHua 배지(자체 bg/fg), 공망 슬레이트 배지(흰 텍스트)
- **검증**(iPhone 17 Pro/iOS 26.2): 다크 홈(상단 바 어두움)·점성 상세(원소색 밝게) 확인 ✅

#### 42. UI/UX 2차 개선 묶음 (#1~#6) (2026-06-26)
- **요청**: 남은 UI/UX 작업을 to-do로 정리하고 하나씩 체크하며 수행
- **#1 카피 톤**: "이번 주 최고예요!" → "기운이 좋은 흐름"(과장 완화)
- **#2 ShareLink**: AI 해석 시트·타로 리딩·궁합 결과 공유. `aiPlainText`(마크다운/이모지 제거 평문, 공유·렌더 공용 `aiIsEmojiScalar`)
- **#3 타로 3D 플립**: `TarotCardView` rotation3DEffect Y축(중간 90°서 앞↔뒤, 거울상 보정) + AI 버튼 `symbolEffect(.bounce)`
- **#4 새로고침**: 홈 `refreshable` + `AppState.refresh()`. (시트 `.thinMaterial`은 크래프트지 톤 충돌로 의도적 보류)
- **#5 다크 모드**: `dtDyn(light,dark)`로 DT 토큰 8종 분기(크래프트지↔나이트), `.preferredColorScheme(.light)` 해제. 시뮬 라이트/다크 양모드 검증
- **#6 TipKit+접근성**: 주간 페이저 코치마크(`WeeklyPagerTip`, `Tips.configure`), DT 폰트 `relativeTo: .body` Dynamic Type + 루트 `dynamicTypeSize(...accessibility1)` 클램프, 천궁도/명반 `accessibilityLabel`
- **#7 위젯/Live Activity**: **보류**(실기기·App Group/서명 환경 필요, 시뮬 검증 불가 — 사용자 결정)
- 전부 표현 레이어, 엔진/스트림/데이터 무변경. iPhone 17 Pro/iOS 26.2 빌드·검증

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

#### 21. 행운 아이템·운세 컨디션 항목별 설명 상세 시트 (2026-06-21)
- **요청**: 행운 아이템/운세 컨디션 제목 옆 `>` 탭 시 항목별 설명 표시 (ⓘ처럼)
- **데이터 점검**: 운세 컨디션=엔진 `DailyFortuneCard.description` 보유(바로 사용) / 행운 아이템=항목별 설명 없음 → 사용자 선택 **오행 기반 카테고리 설명**(5오행×5카테고리=25 템플릿) 자체 작성
- **구현**:
  - `LuckyItemReason.swift` 신규 — 용신 오행(Wood/Fire/Earth/Metal/Water)×카테고리별 설명 템플릿(오행 이론 근거, 엔진 텍스트 아님 명시)
  - `HomeConditions.ConditionItem`에 `grade`/`desc` 추가, `from()`이 엔진 카드에서 채움
  - `LuckyItemsDetailView`(용신 헤더 + 5항목 아이콘·값·오행설명), `ConditionsDetailView`(5항목 아이콘·등급·별점·점수·엔진설명) 추가
  - 두 섹션의 `>`를 Button으로 연결 → `.sheet`. **선택 요일** 기준 데이터 전달, 타이틀도 "{요일}의 …"
  - 새 파일 추가로 `xcodegen generate` 재실행
- **검증**: iPhone 16 Pro(iOS 18.0) 빌드 성공. 행운 아이템 시트(용신 토土 + 항목별 오행 설명)·운세 컨디션 시트(등급·별점·엔진 설명) 렌더 확인 ✅ (컨디션은 기본표시 토글로 결정적 검증 후 원복)
- **결정 기록**: DEC-013

#### 22. 명리 신빙성 강화 — 합충 가중치·경향톤·명리기반 달빛편지 (2026-06-21)
- **요청**: ① 표현을 경향/조언 톤으로 ② 일일 점수에 십성·합충형파해 가중치 명시 ③ 달빛 편지를 그날 일주·십성·합충형파해 기반 명리 코멘트로(현대어/쉽게). 사용자 결정: 엔진 개선+픽스처 갱신 / 신살은 다음 단계
- **엔진(`DailyFortune.swift`)**:
  - `relationWeight`(천간합·육합 +6, 천간충 -6, 육충 -8, 형 -7, 파 -4, 해 -5) + `relationModifier`(일주관계 1.5배, ±18 클램프)
  - `calculateDailyFortune`: 전치 합충형파해를 카드 base에 `relationMod`로 명시 반영(십성·12운성은 기존대로). rand 소비 순서 불변
  - `fortuneDescriptions` 50문구 전부 경향/조언 톤(해요체)으로 재작성
- **앱(`MoonLetter.swift` 전면 재작성)**: `MoonLetters.generate(from: DailyFortuneResult)` — 십성→제목 테마(10), 12운성→기운 경향, 합충형파해→조언 한 줄. 전문용어 없이 현대어+조언 톤. heroBanner가 사용(점수대 고정풀 방식 폐기)
- **골든 픽스처**: daily-fortune.json 재생성(임시 재생성 테스트→실행→삭제). daily `cases` 50건 갱신, 월간 달력 3건은 합충 미적용이라 사실상 동일. **→ daily-fortune은 saju-api 재현이 아닌 자체 알고리즘으로 전환**(코어 사주/천체력/자미두수 픽스처는 불변)
- **검증**: `cd Engine && swift test` 13건 통과 ✅ / iPhone 16 Pro 빌드·실행, 달빛 편지 명리 기반(정관→"원칙과 책임", 합→협력 조언)·점수 합충 반영 확인 ✅
- **결정 기록**: DEC-014
- **주의(신빙성 표기)**: 일일 점수·편지는 명리 요소 기반이나 여전히 해석 콘텐츠 — "경향/조언" 톤 유지, 단정 금지. 전치 신살/공망은 후속
- **수정(레이아웃)**: 새 편지 본문이 길어 고정높이(360) 히어로에서 4줄로 줄바꿈→행운지수/자세히보기 밀림. 1차로 본문 2줄 축약
- **개선(콘텐츠 구체화)**: "너무 뻔하다" 피드백 → 본문 line2를 일반론 대신 **십성별 구체 행동 제안 10종**(정관="약속·마감 같은 책임을 먼저 챙겨보세요" 등)으로. 충·형 있으면 **걸린 기둥별 영역 주의**(일주=가까운 사람, 월주=일/집안, 년주=윗사람, 시주=아랫사람)로 대체. heroHeight 360→392로 3줄 본문 수용
- **심화(전치 신살)**: "더 끌어올려" → 그날 일진의 **전치 신살** 반영(온디바이스). `HoshinSinSal.transitSinSals(transitBranch, natalDayStem, natalDayBranch)` 신규 — [natal 일지, 전치 지지] 조합에 기존 규칙 적용해 천을귀인·역마·도화·화개·공망 판정. 신살 있으면 **제목=신살 테마**(천을귀인="귀인의 손길이 함께하는 날"), 본문 행동=신살 행동. 우선순위: 충·형 경고 > 신살 행동 > 십성 행동. heroBanner가 `bundle.saju.raw.day` 일주 전달. 엔진 픽스처 영향 없음(DailyFortuneResult 불변)·swift test 13건 통과. 6/21 천을귀인 발현 확인 ✅

#### 23. AI 심층 편지 (서버 엔드포인트 + 클라이언트) (2026-06-22)
- **요청**: 달빛 편지를 AI 심층 해석까지 — "더 끌어올려"
- **설계**: 홈 카드(매 스와이프)엔 온디바이스 명리 편지 유지, **AI는 탭 시 온디맨드 별도 시트**(비용·지연·심사 고려)
- **서버**(`saju-api`): `app/api/daily/interpret/route.ts` 신규 — 그날 명리(일주·십성·12운성·점수·컨디션·합충형파해·전치신살)를 받아 `streamText`(gpt-4o-mini)로 편지 스트리밍. system: 달토끼 상담가, 경향/조언 톤·단정 금지·현대어, 형식(오늘의 흐름/이런 점을/달토끼의 한마디). `npx tsc` 통과 + **로컬 dev에서 실제 스트리밍 검증**(재물 낮음·천을귀인 반영 확인)
- **클라이언트**: `AIProxy.interpretDaily(day:weekday:sinsals:gender:birthYear:)` → `/api/daily/interpret`. 달빛 편지 라벨에 ✨ 추가하고 탭 → `AILetterSheet`(명리 요약 칩 + 재사용 `AIInterpretationView` 지연 "받기" 버튼). 선택 요일 기준
- **검증**: 앱 빌드 성공, 시트 오픈·명리 요약("정묘일·편관·절 / 신살 역마,공망 / 37점")·받기 버튼 렌더 확인 ✅
- **⚠️ 배포 필요**: 프로덕션(daltokkie.vercel.app)에 아직 라우트 미배포(404) → **saju-api를 vercel 배포 + `AI_API_KEY` 설정**해야 실제 동작. 미배포 시 앱은 graceful 에러 표시
- **결정 기록**: DEC-015

#### 24. 운세 상세 도식화 1단계 — 자미 명반 그리드 + 점성 원형 차트 (2026-06-23)
- **요청**: 웹의 상세 해석·도식을 iOS 운세 세부 페이지로 이관 (1순위: 도식). 조사로 웹=saju-api(`components/{saju,ziwei,natal}`) 확인, **엔진이 데이터 대부분 보유**(서버 불필요)
- **자미두수 명반**: `ZiweiGridChart.swift` 신규 — 12지지 고정 4×4 배치(巳午未申/辰·酉/卯·戌/寅丑子亥) + 중앙 2×2 정보. 궁별 성요(밝기색 廟旺得利平陷)·사화 배지(化祿/權/科/忌)·대한 나이·命/身 배지·명궁 강조. `GeometryReader+ZStack` 절대배치. ZiweiDetailView 상단 카드로 추가
- **점성 원형 차트**: `NatalWheelChart.swift` 신규(`Canvas`) — 황도 12별자리 섹터(원소색)+글리프, 12하우스 라인·번호, ASC/MC 축, 행성 글리프(충돌분산+역행R), 어스펙트 라인(타입별 색·점선). 웹 기하(lonToAngle/polar) 포팅. NatalDetailView 상단 + 하우스 보완
- **검증**: 빌드 성공. 임시 진입점 스왑으로 두 도식 렌더 확인 ✅ (명반 12궁·중앙정보 / 원형차트 별자리·하우스·행성·어스펙트)
- **결정 기록**: DEC-016

#### 25. 운세 상세 도식화 2단계 — 사주 상세 확장 (2026-06-23)
- **요청**(이어서, "a"=계속): 사주 상세를 웹 수준으로
- **확인**: `EngineAnalysis`의 분석 함수 전부 **public** — 엔진 변경 없이 사용 가능
- **신규**(`SajuAnalysisSections.swift`): 격국 다음에 삽입
  - 오행 분포(원소색 가로 막대 + 강/약), 지장간(기둥별 본기/중기/여기·십성·비율%), 합충형파해+삼합+천간합충(타입 배지+설명), 공망(궁+영향 기둥+설명), 신살(12신살+특수살, 길신/흉살/중성 색)
  - 데이터: `calculateHiddenStems/BranchRelations/MultiRelations/StemRelations/GongMang/TwelveSpirits/SpecialSals`
- **검증**: 빌드 성공, 임시 최상단 배치로 렌더 확인(오행 막대·지장간·합충 배지) ✅

#### 26. 운세 상세 도식화 3단계 — 세운 + 궁합 고도화 (2026-06-23)
- **세운**(`SajuAnalysisSections`): 올해 세운 카드(간지·오행·십성·12운성·띠) — `calculateYearFortune`. 월운은 엔진 전용 함수 없어 보류
- **궁합 고도화**(`CompatibilityView`, 온디바이스 — 엔진에 궁합 함수 없음): 
  - 종합 궁합 점수(띠 관계 + 일간 십성 양방향 + 오행 보완) + 별점 + 코멘트
  - 일간 관계(십성): `getTenGod`로 상대→나/나→상대 십성 + 의미
  - 두 사람 사주·띠 관계·오행 보완 유지
- **검증**: 빌드 성공·엔진 테스트 13건 통과. 임시 자동계산으로 렌더 확인(61점·편관/편재·육합) ✅
- **운세 상세 도식화 완료**: 자미 명반·점성 차트·사주 확장(오행/지장간/합충/공망/신살/세운)·궁합 고도화

#### 27. 월운 엔진 추가 + 사주 상세 표시 (2026-06-23)
- **요청**: 월운도 엔진에 추가해 표시
- **엔진**(`EngineAnalysis.calculateMonthlyPillars`): 한 해 12개월 월주를 오호둔갑법으로 — saju-engine.ts `calculateMonthlyPillars` 포팅(년간 idx→baseMonthStemIdx, 1월=寅). `MonthlyPillar` 타입 신규. **추가 함수라 골든 픽스처 무영향(13건 통과 확인)**
- **표시**(`SajuAnalysisSections`): 월운 카드(12개월 가로 스크롤 — 간지·십성·12운성, 이달 강조)
- **검증**: 엔진 13건 통과·빌드 성공. 임시 배치로 렌더 확인(2026 1월 庚寅 겁재… 오호둔갑법 정확) ✅

#### 28. 사주·점성·자미 페이지를 웹 모바일 구성과 정렬 (2026-06-23)
- **요청**: 원본 웹(saju-api) **모바일** 페이지 구성과 동일하게 (3개 페이지). **전부 네이티브 엔진 데이터** (서버 AI는 추가 안 함 — 사용자 지적: 네이티브 엔진 쓸 것)
- **사주**(`SajuDetailView`+`SajuAnalysisSections` phase화): 웹 모바일 순서로 재배치 — 히어로·사주팔자·**오행분포**·격국·**십성표·12운성(분리)**·신강신약·용신·**공망·합충형파해·삼합·천간합충(분리)·지장간·신살**·대운·**세운·오늘의운세·월운·운세달력**·AI. `SajuAnalysisSections`를 `.elements/.relations/.timeline` 3단계로 분리. 오늘의운세(dailyBundle)·운세달력(calculateMonthlyCalendar 7열 그리드) 신규
- **점성술**(`NatalDetailView`): **하우스(Placidus) 섹션 추가**(누락분) → 원형차트·4대축·행성·하우스·어스펙트
- **자미두수**: 명반그리드·기본정보·12궁·대한유년 (이미 모바일 구성 일치)
- **검증**: 빌드 성공. 임시 배치로 사주 timeline(세운·오늘운세·월운·달력)·점성 하우스 렌더 확인 ✅
- **참고**: ① "AI 해석" 섹션은 LLM(서버)이라 점성/자미엔 미추가(네이티브 우선). 사주는 기존 AI 카드 유지 ② 사주 "입력정보(절기·시간보정)"는 데이터 확보 전까지 보류 ③ 궁합은 이번 요청 범위 외(3개 페이지만)

#### 29. 점성/자미 AI 해석 + 3엔진 AI 콘텐츠 패널 (2026-06-24)
- **요청**: 점성/자미에도 AI 해석 + 웹의 AI 콘텐츠 항목들 이관
- **AIProxy**: `interpretNatal`(/api/natal/interpret)·`interpretZiwei`(/api/ziwei/interpret)·`content(id:tone:…)`(/api/saju/content/{id}, 48종) 추가. 엔진 Codable 차트 전송(`jsonValue`), 사주는 기존 `sajuResultJSON`
- **`AIContentPanel`**: 톤 선택(MZ/따뜻/전통)+섹션별 콘텐츠 버튼, 탭 시 스트리밍. `AIContentSections`(saju 31·natal 10·ziwei 10, 웹 그대로)
- **연결**: 사주(콘텐츠 패널)·점성(AI 해석+패널)·자미(AI 해석+패널)
- **검증**: 라우트 전부 프로덕션 라이브(400) / content 실제 스트리밍 확인(natal-monthly) / 패널 UI 렌더 ✅. 빌드·엔진 13건 통과. **이 AI 라우트는 기존 서버 배포 상태라 추가 배포 불필요**(daily-fortune AI 편지만 미배포 DEC-015)

#### 30. 서비스화 정리 (2026-06-24)
- TEMP 코드 전무·진입점 정상·빌드·엔진 통과·앱 실행 확인 후 일괄 커밋
- **알려진 후속(서비스 지장 없음)**: ① 궁합 웹수준(강점/약점/조언/AI) 미반영 ② 사주 입력정보·일주성향 별도 섹션 미추가 ③ daily-fortune AI 편지 서버 배포 필요

#### 33. 타로 웹 수준 정교화 (2026-06-24)
- **요청**: 타로도 웹 수준으로 정교하게
- **데이터**(`TarotData.swift`, 웹 lib/tarot/cards.ts 포팅): 78장(메이저22+마이너56) name/nameKo/keywords/keywordsReversed, 스프레드(원카드/쓰리카드/켈틱10 + positions), 주제 6종, **결정적 드로우**(makeSeed/drawCards 그대로), 에셋 매핑 수정(ace/02-10/page/knight/queen/king — 기존 01..14 오류 정정)
- **AIProxy.interpretTarot** → /api/tarot/interpret (라이브)
- **TarotView 전면 재작성**: 스프레드 선택 → 주제 → 질문(선택) → 카드 뽑기 → **카드 플립**(뒷면→앞면, 역방향 회전+빨강 "(역)"+역키워드) → 전부 공개 시 **AI 타로 리딩**. 78장 도감(이미지·이름 정확) 유지
- **검증**: 빌드 성공. 리딩(쓰리카드 과거/현재/미래·역방향·키워드)·설정 화면·도감 렌더 확인 ✅, 타로 AI 엔드포인트 실제 스트리밍 확인(태양 카드)
- **참고**: 카드 데이터·드로우는 온디바이스(웹 동일), AI 리딩만 서버(기존 라우트 라이브, 배포 불필요)

#### 41. UI/UX 감사 리포트 + 1차 개선 묶음 (2026-06-25)
- **요청**: AI스러운 표현 영역 + iOS 네이티브 개선안 리포팅 → 1차 묶음 구현
- **감사 요지**: 잔존 이모지(타로 주제·버튼), 과장 카피("이번 주 최고예요!"), 빈/에러 제각각, 네이티브 미사용(햅틱/Charts/ShareLink/ContentUnavailableView/redacted/위젯/다크모드 등)
- **1차 구현**:
  - **이모지 정리**: `TarotData.topics` emoji 필드 제거, "🃏 카드 뽑기"→"카드 뽑기", 리딩 주제 라벨 이모지 제거 (점성·자미 도메인 글리프는 유지)
  - **햅틱**(`.sensoryFeedback`, 기존 0): 탭 전환(MainTabView), 주간 페이저(Home), 타로 카드 플립, AI 시트 오픈(2곳)
  - **로딩 스켈레톤**(`AISkeleton`): AI 시트 로딩을 redacted 라인 + 쉬머로(기존 ProgressView 텍스트)
  - **빈/에러 통일**(`ContentUnavailableView`): 홈/사주/점성/자미 계산 실패 + AI 에러(다시 시도 액션) 표준화
- **검증**(iPhone 17 Pro/iOS 26.2): 스켈레톤·에러 시트 스샷 확인 ✅. 표현 레이어만
- **남은 권고**: 2차(ShareLink·카드 3D 플립·다크모드), 3차(위젯/Live Activity), 서버 프롬프트 톤 지침

#### 40. 세부 해석 메뉴 정돈 — 이모지 제거 + 라벨 자연어화 (2026-06-25)
- **요청**: 세부 해석 메뉴(섹션 버튼)에도 AI스러운 표현 많음
- **변경**:
  - 버튼을 `[이모지 라벨]` → **텍스트 전용 칩**(은은한 보더). `AIContentItem.emoji` 필드/데이터 전면 제거(48종)
  - 어색/영문/게임체 라벨 자연어화: `DO / DON'T`→`할 일·피할 일`, `밸런스 게이지`→`기운 균형`, `3엔진 크로스`→`통합 리포트`, `3엔진 올해 전망`→`올해 통합 전망`
- **검증**(iPhone 17 Pro/iOS 26.2): 텍스트 칩 메뉴 렌더 확인 ✅. id(서버 라우트) 무변경 — 표시 라벨만

#### 39. 세부 해석 'AI스러운 표현' 제거 — 이모지 살균 (2026-06-25)
- **요청**: 세부 해석의 AI스러운 표현(예: 이모티콘) 제거 — 노련한 기획자/디자이너 관점 방안
- **진단**: ①이모지 남발 ②마크다운 잔재(이미 #37 처리) ③과장 어투/상투구(톤)
- **방안/구현**:
  - 클라이언트 살균(`FormattedAIText.deAI`): 이모지/픽토그램/변형 셀렉터/ZWJ 제거(유니코드 1F000–1FAFF, 2600–27BF, 2B00–2BFF, 국기, 키캡, FE0E/F, 200D) + 연속 공백 정리. **본문 의미·느낌표는 보존**. 공용 컴포넌트라 세부/심층 해석·달빛 편지에 일관 적용
  - 세부 해석 시트 제목에서 이모지 제거(`📊 출생차트 종합` → `출생차트 종합`)
  - 섹션 버튼 이모지는 큐레이션 아이콘이라 유지(필요 시 SF Symbols 교체 가능)
  - **권고(미적용)**: 어투/상투구는 서버(`saju-api`) 프롬프트에 금지 지침 추가가 정석(별도 레포)
- **검증**(iPhone 17 Pro/iOS 26.2): 이모지 섞인 샘플로 제목·본문·글머리표·인용 전부 제거 확인 ✅

#### 38. AI 해석을 grabber 바텀 시트로 (2026-06-25)
- **요청**: AI 해석이 화면 하단 인라인 표시 → 새 grabber(드래그 핸들) 창으로
- **추가**(`AIInterpretationView.swift`): `AIResultSheet` — `.presentationDragIndicator(.visible)` + `.presentationDetents([.large, .medium])` 바텀 시트, 상단 동그라미 X(`CircleCloseButton`), 로딩/에러/다시시도, 본문 `FormattedAIText`
- **변경**:
  - `AIInterpretationView`(심층/점성/자미 해석): 인라인 결과 → 카드엔 버튼만, 탭 시 시트. 로딩 완료 후 "해석 다시 보기"
  - `AIContentPanel`(세부 해석): 섹션 항목 탭 → 인라인 결과 제거하고 시트로 표시(제목=항목 라벨, 톤 유지)
- **검증**(iPhone 17 Pro/iOS 26.2): grabber·제목·X·서식 본문·medium↔large 드래그 확인 ✅. 스트림/엔진 무변경(표현 레이어만)

#### 37. AI 해석 마크다운 예쁘게 렌더 — FormattedAIText (2026-06-25)
- **요청**: 세부/심층 해석이 날것의 AI 답변(##, **, ---, • 등 마커·특수문자 노출)이라 보기 안 좋음 → 예쁘게
- **추가**(`AIInterpretationView.swift`): `FormattedAIText` 공용 뷰 — 스트리밍 마크다운을 블록 파싱(제목 #/##/###·한줄 굵게 소제목·글머리표 -/*/•·번호 1./1)·인용 >·구분선 ---)해 네이티브 스타일로 렌더, 인라인은 `AttributedString(markdown: .inlineOnlyPreservingWhitespace)`로 **굵게**/*기울임*/`코드` 처리, 실패 시 마커 제거 폴백
- **적용**: `AIInterpretationView`(심층/점성/자미 해석)·`AIContentPanel`(세부 해석)의 `Text(text)` → `FormattedAIText`
- **렌더 결과**: 굵은 세리프 제목, 핑크 글머리표 점, 핑크 번호, 좌측 바 인용, 구분선 — 대표 마크다운 샘플로 시뮬 확인 ✅
- **검증**(iPhone 17 Pro/iOS 26.2): 빌드 성공, 표현 레이어만(엔진/스트림 무변경)

#### 36. 'AI' 표기 제거 — 사용자 노출 제목 정리 (2026-06-25)
- **요청**: "달토끼 AI 심층해석 → 달토끼 심층 해석으로 모두" → 적용 범위 확인 후 **모든 'AI' 표기 제거** 선택
- **변경**(사용자 노출 문구 10종): 달토끼 심층/점성/자미 해석, 달토끼 해석 받기(버튼), 타로 리딩, (사주/점성술/자미두수)콘텐츠 패널, (홈) ○요일의 심층 편지·심층 편지
- **유지**: 코드 식별자(`AIInterpretationView`/`AIContentPanel`/`AIProxy`)와 내부 주석/문서는 그대로(비노출)
- **검증**: 빌드 성공, grep로 잔여 사용자 노출 'AI' 없음 확인 ✅. 표현 레이어만

#### 35. 사주·자미두수 네이티브 리디자인 — 밤하늘 히어로 통일 (2026-06-25)
- **요청**: (점성 리디자인 후) "자미두수·사주 상세도 같은 톤으로" → 응
- **공용화**: `sajuElementColor`/`sajuElementKo`(목화토금수 색, Theme.swift), `DarkStatChip`(밤하늘 요약 칩, 원소색 틴트 옵션), `StarField` 재사용
- **사주팔자**(`SajuDetailView`): 상단 2카드(일간 프로필+사주팔자) → **밤하늘 히어로** 1장으로 통합
  - 일간 정체성(displayHanja+성향) + `PillarGrid(onDark:)`(천간/지지 한자를 **원소색**으로) + 핵심 3칩(일간/강한오행/약한오행, 원소색 틴트). 띠 영문→한글 변환
- **자미두수**(`ZiweiDetailView`): 최상단 **밤하늘 히어로** 추가(紫微斗數 + 핵심 3칩: 명궁 주성/오행국/신궁). 명반 그리드는 정통 다이어그램이라 라이트 카드 유지
- **검증**(iPhone 17 Pro/iOS 26.2): 사주 히어로(원소색 기둥+칩)·자미 히어로 렌더 확인 ✅. 엔진/데이터 무변경(표현 레이어만). 미사용 `elementsLine` 제거
- **점성/사주/자미 3개 상세 페이지 톤 통일 완료**

#### 34. 점성술 페이지 네이티브 리디자인 — 밤하늘 히어로 + Big3 (2026-06-25)
- **요청**: "iOS SwiftUI 네이티브인데 점성술 페이지가 너무 웹페이지 같다 → 네이티브하게 멋있게"
- **방향 확정**(사용자 선택): ① 원형 차트를 **밤하늘 히어로**(다크 #303663→#1C1F38 그라데이션 + 별 배경)로 ② 상단 **Big3**(태양·달·상승궁) 요약
- **변경**
  - `NatalWheelChart`: `onDark` 테마 추가 — 다크 배경용 원소색(translucent jewel)·글리프(크림)·링/하우스선/축(골드 ASC)·어스펙트(채도↑) 재매핑
  - `NatalDetailView` 전면 리디자인:
    - **밤하늘 히어로 카드**(`celestialHero`): `StarField`(sin 해시 결정적 별, Date/random 미사용) + 다크 원형 차트 + **Big3 칩**(글리프+별자리+라벨, 골드 강조)
    - **4대 축**: `DetailRow` 나열 → 2×2 그리드 카드(원소색 점)
    - **행성 배치**: 평면 텍스트 행 → 원소색 글리프 원 + 별자리 칩(Capsule) + 하우스/역행 캡션
    - **하우스**: 긴 목록 → 2열 그리드(밤하늘 번호 뱃지 + 원소색 별자리)
    - **어스펙트**: 텍스트 표 → 색상 글리프(☌⚹□△☍) + 색상 타입 칩 + 오차
  - 원소색 헬퍼(`natalElementColor`/`natalElementKo`, 별자리 index%4=불/흙/바람/물) 파일 공용화
- **검증**(iPhone 17 Pro/iOS 26.2): 히어로/Big3/4대축/행성/하우스/어스펙트 전 섹션 렌더 확인 ✅. 엔진/데이터 변경 없음(표현 레이어만)
- **참고**: 자미두수 페이지는 이번 범위 아님(요청 시 동일 톤으로 후속 가능)

#### 33. 타로 네이티브 내비게이션 + 동그라미 X 닫기 버튼 (2026-06-25)
- **요청 1**: "타로 페이지에서 이전 페이지로 어떻게 이동?" → "ios 네이티브 방식을 왜 사용 안 해?"
  - **변경**(`TarotView`): 커스텀 상태 토글(`if let drawn`) → `NavigationStack` + `.navigationDestination(item: $session)` push. 시스템 뒤로 버튼/엣지 스와이프 백 동작. 리딩 화면을 별도 `TarotReadingView`로 분리, `TarotSession: Identifiable, Hashable`(id 기반)
  - **검증**: 빌드 성공. push 시 좌상단 시스템 뒤로(원형 chevron) + 중앙 타이틀 "쓰리카드 리딩" 확인 ✅
- **요청 2**: "앱 내 페이지들 상단 닫기 버튼은 동그라미버튼에 X로 표시"
  - **추가**(`Theme.swift`): `CircleCloseButton`(동그라미 + X, 시스템 뒤로 버튼 원형과 통일) + `.dtCloseToolbar { }` 모디파이어
  - **적용**: 홈 시트 4개(행운지수/행운아이템/운세컨디션/달빛편지)의 `Button("닫기")` → `.dtCloseToolbar { dismiss() }`
  - **검증**: 빌드 성공. 상단 우측 동그라미 X 렌더 확인 ✅
- **최종 검증 (iPhone 17 Pro / iOS 26.2)**: 정식 빌드(MainTabView 루트) 설치·실행, 홈/시트/타로 정상 ✅
- **이슈/교훈**: 사용자가 "X 눌러도 안 닫힌다"고 한 화면은 **닫기 버튼 캡처용 임시 미리보기 루트**가 시뮬레이터에 설치된 채 남아 있던 것(루트라 dismiss 대상 없음). 소스는 이미 정상 복원·커밋 상태였음. → **검증용 TEMP 빌드는 캡처 직후 정식 빌드로 재설치할 것**(소스 revert만으로는 시뮬 설치본이 안 바뀜)
- **버그픽스 — 타로 카드 뒷면 미표시**: `tarot-back` 에셋만 유일하게 `.webp`(나머지 78장은 `.jpg`)였고 asset 카탈로그 단일 webp가 렌더 안 됨. `sips`로 webp→jpg 변환 후 교체(Contents.json 2x 슬롯 `tarot-back.jpg`). iPhone 17 Pro/iOS 26.2 리딩 화면에서 뒷면 정상 렌더 확인 ✅

#### 32. 궁합 웹 수준 고도화 — 강점/약점/조언 (네이티브 포팅) (2026-06-24)
- **요청**: 궁합도 웹 수준으로 강점/약점/조언까지
- **포팅**(`CompatibilityView`, 온디바이스): 웹 `fortuneteller.ts` `ftCheckCompatibility`/`computeCompatibilityScore`/`generateCompatAnalysis`/`getZodiacRelation` 규칙을 Swift로 그대로 이식 — 서버 불필요
  - 일간 조화(상생/비화/상극 + 방향), 오행 보완(count 0 상호 보완), 띠 관계(육합92/삼합85/상충45/상형55/같은띠70/인접65/일반68), 점수(=띠점수+상생8/비화3/상극-5+보완×4≤12, 30~98 클램프)
  - 섹션: 두 사람의 사주 → 궁합 결과(점수+요약) → 일간(日干) 관계 → 띠 관계 → 오행 보완 관계 → **강점 → 약점 → 조언** (웹 모바일 구성과 동일)
- **검증**: 빌드 성공. 임시 자동계산으로 호랑이띠↔돼지띠 95점(육합92−상극5+보완8, 웹 공식 일치)·강점/약점/조언 텍스트 웹 로직 동일 확인 ✅
- **참고**: AI 궁합 해석(/api/saju/compatibility-interpret)은 미연결(원하면 추가 가능). 계산·강약점·조언은 전부 네이티브

#### 31. 웹↔iOS 결과 동일성 검증 (2026-06-24)
- **방법**: 골든 픽스처(웹 saju-api 생성 테스트 케이스)로 교차 검증 — ① iOS `swift test` 재현 ② **현재 웹 코드로 골든 재생성**(`npm run golden`) 후 iOS 픽스처와 NFC 정규화 비교
- **결과 (핵심 엔진 100% 동일)**: 음력변환·사주기본(1001)·사주분석(106: 십성/신살/공망/지장간/합충/용신/대운/세운)·점성(408)·자미(366) — **현재 웹 == iOS 비트 단위 동일**, iOS swift test 13/13 통과
- **예외**: daily-fortune(일일운세)는 **DEC-014 의도된 분기 유지**(웹 53 vs iOS 50, 합충 가중치·경향톤·명리 편지). 사용자 결정: 분기 그대로 둠
- **결론**: 사주·점성·자미 계산/분석은 웹과 동일 검증됨. 궁합은 픽스처 대상 아님(온디바이스 약식). 검증 중 코드 변경 없음

| 우선순위 | 작업 | 상태 |
|---------|------|------|
| 1 | ~~탭바 중앙 배지 높이 시뮬레이터 확인 및 미세 조정~~ | ✅ 완료 (2026-06-13, 커밋 6314dd3 — offset 0 정렬) |
| 2 | ~~Noto Sans/Serif KR 폰트 번들~~ → **Pretendard 단일 통일로 대체 완료** | ✅ 완료 (2026-06-20, WORKLOG #14, DEC-010) |
| 3 | ~~행운 아이콘 항목별 대응~~ → **음료/장소/향기/아이템 100종 + 컬러 orb 적용** | ✅ 완료 (2026-06-21, WORKLOG #20, DEC-012) |
| 4 | 타로/궁합 AI 해석 연결 | 미착수 (참고: **일일운세 AI 심층 편지는 별도 신설** WORKLOG #23/DEC-015) |
| 5 | 사주 상세 신살/공망/합충형파해/지장간 섹션 추가 | 부분 (홈 일일운세에 전치 신살·합충 반영 #22-23 / 사주 상세 페이지 섹션은 미착수) |
| 6 | 마이 탭 고도화 | 미착수 |
| 7 | 앱스토어 메타데이터/심사 대응 | 미착수 |
| 8 | **AI 심층 편지 프로덕션 배포** (saju-api vercel + AI_API_KEY) | 대기 (코드 완료, DEC-015) |

## 주의사항

- 달토끼는 App Store 기준 "fortune telling" — 포화 카테고리이므로 고유 가치 입증 필요 (App Store Review Guidelines 4.3)
- 디자인 토큰: 배경 #f8f2e8, 카드 #faf6ee, 포인트 #d4789c, 텍스트 #2a2520/#8b7e6a, 탭바 보더 #e8dcc4, 밤하늘 #2a2f50
- 천체력은 라이선스 클린 재구현 (AGPL 의존성 없음)
