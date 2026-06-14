# assets-src — 레포 내 이미지 원본

앱에서 쓰는 아이콘/이미지 **원본을 이 폴더에 보관**합니다.
`scripts/prepare-assets.sh`가 이 폴더를 자동으로 읽어 `App/Assets.xcassets`에 등록하므로,
카탈로그를 재생성(`rm -rf` 후 rebuild)해도 여기 있는 파일은 보존됩니다.

## 규칙

- **파일명이 곧 에셋 이름** — `foo.png` → 코드에서 `Image("foo")`
- **포맷**: `@2x` 해상도 PNG 권장 (universal `2x`로 등록됨). jpg/jpeg/webp/pdf도 가능
- **한글 파일명 허용** (기존 `color-초록` 등과 동일 규칙)
- 같은 이름이 기존 파이프라인(Desktop/saju-api)에도 있으면 **이 폴더 것이 우선**(나중에 등록)

## 추가 방법

1. 이미지 파일을 이 폴더에 복사
2. 재생성: `bash scripts/prepare-assets.sh` (단, Desktop·saju-api 원본이 모두 있어야 전체 재생성 성공)
   - 새 파일만 빠르게 반영하려면 해당 `<이름>.imageset`만 직접 생성해도 됨
3. `xcodegen generate` 불필요 (에셋은 폴더 참조). 빌드만 다시.
