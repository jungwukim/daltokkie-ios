# App Store Connect — App 개인정보(App Privacy) 입력 정리

> App Store Connect → 앱 → **App Privacy** 설문 작성용. 2026-06-29 코드 감사(WORKLOG #65) 기준.
> 정책 출처: 온디바이스 계산(엔진), 전송은 `daltokkie.vercel.app` 단일 HTTPS, 서버 무상태, 제3자 OpenAI.

## 0. Apple "수집(Collect)" 정의 적용
Apple은 **기기 밖으로 전송되어 실시간 처리 이상으로 접근/보관되는** 데이터를 "수집"으로 본다.
- 기기에만 저장되고 전송되지 않는 항목(예: **이름**)은 신고 대상 아님.
- AI 해석 시 전송되는 생년월일시·성별·출생지는 OpenAI가 최대 30일 보관 → **수집으로 신고**.

## 1. Data Collection 여부
**Yes, we collect data**(단, AI 심층 해석 기능 사용 시에 한함).

## 2. 신고할 데이터 타입 (Data Types)

| Apple 카테고리 | 항목 | 전송처 | Linked to user? | Tracking? | Purpose |
|---|---|---|---|---|---|
| **Other Data Types** (Other data) | 생년월일·태어난 시간·성별·출생 도시 + 계산된 명식(사주/점성/자미) | daltokkie 서버 → OpenAI | **Not Linked** | **No** | App Functionality |

- 마땅한 표준 카테고리가 없으므로 **"Other Data Types"** 로 신고하고 설명에 "birth date/time, gender, birth city used to generate the reading" 기재.
- (참고) **Name**은 기기에만 저장·미전송 → 신고하지 않음.

## 3. 각 질문별 답변

**Q. 이 데이터가 사용자 신원에 연결됩니까? (Linked to the user's identity)**
→ **아니오 (Not Linked to You).** 이름·계정·기기 식별자·이메일 등 식별자를 함께 전송하지 않음. 익명 단건 요청.

**Q. 이 데이터를 추적(Tracking)에 사용합니까?**
→ **아니오.** 광고 식별자·데이터 브로커·앱 간 결합·타깃 광고 없음. (`NSUserTrackingUsageDescription`/ATT 미사용.)

**Q. 사용 목적(Purposes)**
→ **App Functionality** (운세 계산·AI 해석 생성)만 선택. Analytics/Advertising/Product Personalization/기타 **선택 안 함.**

## 4. 신고하지 않는 항목 (근거)

| 항목 | 이유 |
|---|---|
| 이름 | 기기에만 저장, 전송 안 함 |
| 위치(Precise/Coarse Location) | GPS·위치권한 미사용. 출생 도시는 사용자가 고른 텍스트(좌표 보정용)이며 현재 위치 아님 |
| 기기 ID / User ID / IDFA | 생성·전송 안 함 |
| Contacts / Photos / Audio | 접근 안 함 |
| Crash/Analytics/Diagnostics | 분석·크래시 SDK 미탑재 |
| Purchases / Financial | 결제·인앱구매 없음 |

## 5. Privacy Nutrition Label 요약(예상 표기)
- **Data Used to Track You:** None
- **Data Linked to You:** None
- **Data Not Linked to You:** Other Data (birth date/time, gender, birth city, computed chart) — App Functionality

## 6. 출시 전 체크리스트
- [ ] PRIVACY.md를 공개 URL로 호스팅(GitHub Pages 등) → App Store Connect **Privacy Policy URL**에 입력
- [ ] App Privacy 설문을 위 표대로 작성·제출
- [ ] (권장) OpenAI 데이터 처리 정책을 PRIVACY.md 작성 시점 기준으로 재확인
- [ ] (선택) AI 해석 최초 사용 시 "정보가 해석 생성을 위해 서버로 전송됨" 1회 안내 고려
- [ ] 운영자/개인정보 보호책임자 정보·문의 이메일 최종 확정

## 7. 참고
- 데이터 흐름 상세: `docs/ARCHITECTURE.md`(출생지 데이터 계약), 보안 감사: `docs/WORKLOG.md` #65
- 서버는 별도 레포(saju-api): DB/KV/파일/분석 SDK 전무(stateless) 확인됨
