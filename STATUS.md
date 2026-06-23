# 달토끼 iOS — 진행 상태 (자동 작업 로그)

> 계획 원본: saju-api/docs/ios-native-plan.md
> 구성: SwiftUI 네이티브 + 순수 Swift 엔진 + 템플릿 해석 + AI 프록시 1개

## 완료 (2026-06-11 새벽)

### Engine (SPM 패키지, `Engine/`) — swift test 13건 전부 통과
| 킷 | 내용 | 골든 픽스처 |
|----|------|------------|
| LunarKit | 음력 변환 (lunar-javascript 테이블 + ft-lib 레거시) | 2,464건 ✅ |
| ZiweiKit | 자미두수 명반/유년/대한 | 366건 ✅ |
| NatalKit | **라이선스 클린 천체력** — VSOP87B+Meeus(MIT)+JPL Horizons. 허용오차 검증(행성≤0.003°, 달≤0.018°, 커스프≤0.0002°) | 408건 ✅ |
| SajuKit | 만세력/절기/사주팔자 + 분석(십성/신살/격국/용신/대운) + 일일운세 | 1,001+106+53건 ✅ |

핵심 재현 사항:
- seeded PRNG: JS double 반올림 의미론까지 재현 (DailyFortuneEngine.SeededRandom)
- 12절 리스트: TS 원본 그대로 (소설 포함·소한 제외 — 정통과 다르지만 픽스처 기준)
- REGION_LONGITUDES: constants.ts와 정확히 동일 (울릉도 없음 → 서울 폴백)
- 시각 해석: 모든 컴포넌트 추출 Asia/Seoul 기준

### 픽스처 재생성 (saju-api에서)
`npm run golden` → tests/golden/fixtures/*.json → Engine/Tests/*/Resources/로 복사

## 완료 (이어서)

### 앱 (App/, xcodegen)
- 프로젝트: project.yml → DalTokkie.xcodeproj (iOS 17+, iPhone 전용)
- 폰트: **Pretendard 단일 통일**(번들 OFL, DT.serif/sans 매핑, 런타임 등록 — DEC-010)
- 에셋: 토끼/캐릭터/배경/타로 + **행운 아이템 항목별 아이콘**(음료/장소/향기/아이템 100 + 컬러 orb 25) — 일괄 정규화(바닥·크기·가로중앙 정렬, DEC-012)
- 화면: 온보딩(생년월일 영구 저장) /
  **홈** — 헤더(중앙 타이틀·흰 상단바·당근 아이콘) / **상단 카드 주간 페이저(오늘 중심 7일, 요일 점 인디케이터, 명리 기반 달빛 편지)** / 행운 아이템·운세 컨디션(요일 연동, 각 `>` 항목별 설명 시트) / 달빛 편지 ✨탭 → AI 심층 편지 시트 /
  운세 메뉴 + **사주 상세**(오행분포·격국·십성표·12운성·신강신약·용신·공망·합충형파해·삼합·천간합충·지장간·신살·대운·세운·오늘의운세·월운·운세달력 + AI 해석 + AI 콘텐츠) + **점성술 상세**(원형차트·4대축·행성·하우스·어스펙트 + AI 해석/콘텐츠) + **자미두수 상세**(명반그리드·기본정보·12궁·대한유년 + AI 해석/콘텐츠) + 궁합(온디바이스 약식) /
  타로(78장 도감 + 3장 뽑기) / 부적함(캐릭터 5종) / 마이(프로필·재설정)
- 차트: LuckyLineChart / FortuneRadarChart / FortuneBarChart (Path/Canvas)
- AIProxyClient: daltokkie.vercel.app 스트리밍. `interpretSaju`(원국) + **`interpretDaily`(일일 심층 편지 → `/api/daily/interpret`, saju-api 신설, 배포 필요)**
- 검증: iPhone 16 Pro(iOS 18.0) 빌드·설치·실행 ✅

## 남은 작업 (다음 단계)
- 타로/궁합 AI 해석 연결 (AIProxy.stream 사용, 엔드포인트만 추가)
- **AI 심층 편지 프로덕션 배포**: saju-api vercel 배포 + `AI_API_KEY` 설정 (코드 완료, DEC-015)
- 사주 상세 페이지에 신살/공망/합충형파해/지장간 섹션 추가 (홈 일일운세엔 전치 신살·합충 이미 반영)
- 마이 탭 고도화, 앱스토어 메타데이터/심사 대응

## 빌드 명령
- 엔진 테스트: `cd Engine && swift test`
- 프로젝트 생성: `xcodegen generate` (루트, project.yml — 신규 소스 추가 시 필수)
- 앱 빌드: `xcodebuild -project DalTokkie.xcodeproj -scheme DalTokkie -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`

## 주의/결정 사항
- 천체력은 라이선스 클린 재구현 완료 (VSOP87B + astronomia MIT + JPL Horizons — NOTICE.md 고지). AGPL 의존성 없음
- **daily-fortune 일일운세는 자체 알고리즘으로 분기**(합충형파해 가중치·경향톤·명리 편지 — DEC-014). saju-api 비트재현 아님. 코어 사주/천체력/자미두수는 정통 재현 유지
- natal 1905~1908 서울 DST gap 에러는 의도된 TS 버그 재현 (saju-api 칩 task_3270ee30)
- 일일 점수·편지는 명리 요소 기반이나 해석 콘텐츠 — "경향/조언" 톤, 단정 금지 (App Store 4.3 오락 카테고리)
- 디자인 토큰: 배경 #f8f2e8, 카드 #faf6ee, 포인트 #d4789c, 텍스트 #2a2520/#8b7e6a, 탭바 보더 #e8dcc4, 밤하늘 #2a2f50
