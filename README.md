# daltokkie-ios (달토끼)

운세/사주/타로 iOS 앱. SwiftUI 네이티브, iOS 17+, iPhone 전용.
순수 Swift 계산 엔진(음양력·사주·천체력·자미두수) + 템플릿 해석 + AI 프록시.

## 구조

```
App/            SwiftUI 앱 레이어 (뷰/상태/에셋)
Engine/         SPM 패키지 — UI 의존 없는 순수 Swift 엔진
  ├ LunarKit    음양력 변환
  ├ SajuKit     사주팔자 + 용신/대운/일운
  ├ NatalKit    서양 천체력 (VSOP87B + Meeus, AGPL-free)
  └ ZiweiKit    자미두수
assets-src/     앱 이미지 원본 (prepare-assets.sh가 Assets.xcassets로 등록)
docs/           WORKLOG / DECISIONS / PROCESS (작업 앵커·결정 기록)
```

## 빌드 & 테스트

```bash
xcodegen generate          # project.yml 변경 후
xcodebuild -project DalTokkie.xcodeproj -scheme DalTokkie \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
cd Engine && swift test     # 엔진 골든 픽스처 테스트 (4,398건)
```

## 에셋 추가

`assets-src/<카테고리>/` 에 **ASCII 파일명**으로 PNG(@2x)를 넣으면
`scripts/prepare-assets.sh` 가 하위폴더까지 재귀로 `App/Assets.xcassets`에 등록합니다.
코드에서는 `Image("<파일명>")` 으로 참조합니다.

## 라이선스/심사

- 천체력은 라이선스 클린 자체 구현 (AGPL 의존성 없음 — `NOTICE.md`)
- App Store fortune telling 포화 카테고리 대응: 천체력 자체 구현·한국 사주 특화가 차별점
