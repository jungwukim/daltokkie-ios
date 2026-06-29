# 달토끼(DalTokkie) 개인정보처리방침 / Privacy Policy

**시행일 / Effective date:** 2026-06-29
**앱 / App:** 달토끼 (DalTokkie), iOS · `com.daltokkie`
**문의 / Contact:** jungwu.kim@gmail.com

> 이 방침은 App Store 제출용 호스팅(예: GitHub Pages·웹사이트)을 위한 초안입니다.
> 배포 전 운영자(개인정보 보호책임자) 정보·호스팅 URL을 확정하세요.

---

## 한국어

### 1. 개요
달토끼는 사용자가 입력한 생년월일시 등을 기반으로 사주·점성술·자미두수·타로 운세를 제공하는 앱입니다. 모든 핵심 운세 **계산은 사용자의 기기 안에서** 수행되며, 입력 정보는 **기기에만 저장**됩니다. 별도의 회원가입·로그인·계정이 없습니다.

### 2. 수집·이용하는 정보
사용자가 직접 입력하는 정보:
- **이름**(선택) — 화면 표시용. **기기에만 저장되며 외부로 전송되지 않습니다.**
- **생년월일·태어난 시간**(시간은 선택) — 운세 계산용.
- **성별** — 운세 계산용.
- **출생 지역**(도시) — 진태양시·점성 좌표 보정용.

수집하지 **않는** 정보:
- 위치정보(GPS), 연락처, 사진, 마이크, 기기 식별자(UDID·광고 식별자), 로그인 정보, 결제 정보.
- 사용 분석·추적(advertising/analytics) 데이터.

### 3. 정보의 저장
- 입력 정보는 iOS의 앱 전용 저장소(`UserDefaults`)에 저장되며, 기기 잠금 시 iOS 데이터 보호로 암호화됩니다.
- 마이 → "생년월일 다시 입력하기"로 언제든 삭제할 수 있으며, 앱 삭제 시 모든 정보가 함께 삭제됩니다.

### 4. 제3자 전송 (AI 심층 해석 기능 사용 시)
AI 심층 해석을 요청할 때에 한해, 해석 생성을 위해 **생년월일시·성별·출생 지역과 계산된 명식(사주/점성/자미) 데이터**가 다음으로 전송됩니다.
- **달토끼 해석 서버** (`daltokkie.vercel.app`, HTTPS 암호화): 요청 처리를 위한 중계 역할만 하며, **어떠한 사용자 정보도 데이터베이스·파일에 저장하지 않습니다(무상태/stateless).**
- **OpenAI** (`api.openai.com`): 해석 문구 생성을 위해 위 정보가 프롬프트에 포함되어 전달됩니다. OpenAI는 API 데이터를 모델 학습에 사용하지 않으며, 오·남용 모니터링 목적으로 최대 30일간 보관 후 삭제합니다(OpenAI 정책에 따름).
- **전송되지 않는 항목:** 이름, 기기 식별자, 위치(GPS), 연락처.
- 전송되는 정보에는 이름·계정·기기 식별자가 포함되지 않으므로 **특정 개인을 직접 식별하지 않습니다.**

### 5. 정보를 이용하는 목적
- 사주·점성술·자미두수·타로 운세 계산 및 AI 해석 문구 생성(앱 기능 제공).
- 광고·마케팅·프로파일링·제3자 판매에 **이용하지 않습니다.**

### 6. 보유 기간
- 기기 내 정보: 사용자가 삭제하거나 앱을 삭제할 때까지.
- 해석 서버: 보관하지 않음(요청 처리 후 즉시 소멸).
- OpenAI: 해당 사업자 정책에 따라 최대 30일.

### 7. 이용자의 권리
- 입력 정보의 열람·수정·삭제는 앱 내에서 직접 가능합니다(마이 화면).
- 기타 문의·요청은 위 이메일로 연락해 주세요.

### 8. 아동의 개인정보
- 본 앱은 만 14세 미만 아동을 대상으로 하지 않으며, 아동의 정보를 고의로 수집하지 않습니다.

### 9. 방침 변경
- 본 방침이 변경되면 앱 또는 본 페이지를 통해 시행일과 함께 고지합니다.

### 10. 면책
- 운세 해석은 오락·참고 목적이며, 의료·법률·재무 등 전문적 조언을 대체하지 않습니다.

---

## English

### 1. Overview
DalTokkie provides Korean Saju, Western astrology, Ziwei Doushu, and tarot readings based on the user's birth information. All core calculations run **on your device**, and your input is **stored only on your device**. There is no sign-up, login, or account.

### 2. Information we collect & use
Entered by the user:
- **Name** (optional) — for on-screen display only; **stored on device, never transmitted.**
- **Date of birth / birth time** (time optional) — for readings.
- **Gender** — for readings.
- **Birthplace** (city) — for true-solar-time and astrological coordinate correction.

We do **not** collect: location (GPS), contacts, photos, microphone, device identifiers (UDID/IDFA), login/credentials, payment info, or analytics/advertising/tracking data.

### 3. Storage
Input is stored in the app's sandboxed `UserDefaults`, encrypted at rest via iOS Data Protection when the device is locked. You can delete it anytime ("Re-enter birth info") or by deleting the app.

### 4. Third parties (only when using AI in-depth readings)
When you request an AI in-depth reading, your **birth date/time, gender, birthplace, and computed chart data** are sent to:
- **DalTokkie reading server** (`daltokkie.vercel.app`, HTTPS): acts only as a relay; **stores no user data (stateless).**
- **OpenAI** (`api.openai.com`): receives the above within the prompt to generate the reading text. OpenAI does not use API data to train its models and retains it for up to 30 days for abuse monitoring before deletion (per OpenAI policy).
- **Not sent:** name, device identifiers, location (GPS), contacts.
- No name, account, or device identifier is included, so the data does **not directly identify you.**

### 5. Purpose
- Calculating readings and generating AI interpretation text (app functionality only).
- **Never** used for advertising, marketing, profiling, or sale to third parties.

### 6. Retention
- On device: until you delete it or remove the app.
- Reading server: not retained (discarded after the request).
- OpenAI: up to 30 days per their policy.

### 7. Your rights
View/edit/delete your input directly in the app (My screen). For other requests, contact the email above.

### 8. Children
Not directed to children under 14; we do not knowingly collect children's data.

### 9. Changes
Updates will be posted in the app or on this page with a new effective date.

### 10. Disclaimer
Readings are for entertainment/reference and are not a substitute for professional medical, legal, or financial advice.
