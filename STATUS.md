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
- 에셋: 92개 이미지셋 40MB (토끼/캐릭터 5종/배경/타로 78장+뒷면/아이콘) — scripts/prepare-assets.sh
- 화면: 온보딩(생년월일 영구 저장) / 홈(달빛편지 배너·행운지수 차트·행운아이템·레이더·막대·CTA) /
  운세 메뉴 + 사주 상세(십성·12운성·신강신약·용신·격국·대운 + AI 해석) + 점성술 상세 + 자미두수 상세 + 궁합 /
  타로(78장 도감 + 3장 뽑기) / 부적함(캐릭터 5종) / 마이(프로필·재설정)
- 차트: LuckyLineChart / FortuneRadarChart / FortuneBarChart (Path/Canvas)
- AIProxyClient: daltokkie.vercel.app 스트리밍 (실서버 스키마 검증 완료 — 평문 마크다운 스트림)
- 검증: 시뮬레이터(iPad 10th, iOS 18.0) 설치·실행·홈 화면 스크린샷 확인 ✅
  (iPhone 시뮬레이터 런타임 미설치 — Xcode에서 다운로드 후 iPhone으로 실행 권장)

## 남은 작업 (다음 단계)
- Noto Sans/Serif KR 폰트 번들 (현재 시스템 serif/sans)
- 행운 아이콘: 웹 SVG 125종 대응 (현재 SF Symbols 5종)
- 타로/궁합 AI 해석 연결 (AIProxy.stream 사용, 엔드포인트만 추가)
- 사주 상세에 신살/공망/합충형파해/지장간 섹션 추가 (엔진 함수는 모두 준비됨)
- 채팅(마이) 탭 고도화, 앱스토어 메타데이터/심사 대응

## 빌드 명령
- 엔진 테스트: `cd Engine && swift test`
- 프로젝트 생성: `xcodegen generate` (루트, project.yml)
- 앱 빌드: `xcodebuild -project DalTokkie.xcodeproj -scheme DalTokkie -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build`

## 주의/결정 사항
- 천체력은 라이선스 클린 재구현 완료 (VSOP87B + astronomia MIT + JPL Horizons — NOTICE.md 고지). AGPL 의존성 없음
- natal 1905~1908 서울 DST gap 에러는 의도된 TS 버그 재현 (saju-api 칩 task_3270ee30)
- 디자인 토큰: 배경 #f8f2e8, 카드 #faf6ee, 포인트 #d4789c, 텍스트 #2a2520/#8b7e6a, 탭바 보더 #e8dcc4, 밤하늘 #2a2f50
