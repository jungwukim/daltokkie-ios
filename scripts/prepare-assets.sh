#!/bin/bash
# 에셋 준비 — Desktop/Dal Tokkie 원본 + saju-api/public → Assets.xcassets
# 타로 카드는 폭 700px로 다운스케일 (53MB → 약 10MB)
set -euo pipefail

SRC_DESIGN="/Users/jaecheolkim/Desktop/Dal Tokkie"
SRC_PUBLIC="/Users/jaecheolkim/dev/saju-api/public"
XCASSETS="$(cd "$(dirname "$0")/.." && pwd)/App/Assets.xcassets"

rm -rf "$XCASSETS"
mkdir -p "$XCASSETS"

cat > "$XCASSETS/Contents.json" <<'EOF'
{ "info": { "author": "xcode", "version": 1 } }
EOF

# 단일 스케일 이미지셋 생성: add_image <에셋이름> <원본경로> [다운스케일폭]
add_image() {
  local name="$1" src="$2" width="${3:-}"
  local dir="$XCASSETS/${name}.imageset"
  mkdir -p "$dir"
  local ext="${src##*.}"
  local dest="$dir/${name}.${ext}"
  if [ -n "$width" ]; then
    sips --resampleWidth "$width" "$src" --out "$dest" >/dev/null
  else
    cp "$src" "$dest"
  fi
  cat > "$dir/Contents.json" <<EOF
{
  "images": [ { "filename": "${name}.${ext}", "idiom": "universal", "scale": "2x" } ],
  "info": { "author": "xcode", "version": 1 }
}
EOF
}

echo "── 코어 이미지"
add_image "moon-rabbit" "$SRC_PUBLIC/moon-rabbit.png"
add_image "dal-tokkie-icon" "$SRC_PUBLIC/dal-tokkie-icon.png"
add_image "carrot-icon" "$SRC_PUBLIC/carrot-icon.png"
add_image "moon-window" "$SRC_PUBLIC/moon-window.png"
add_image "rabbit-master" "$SRC_PUBLIC/rabbit-master.png"
add_image "tarot-back" "$SRC_PUBLIC/tarot/card-back.webp"

echo "── 캐릭터/배경 (1000px 다운스케일)"
add_image "char-wolya" "$SRC_DESIGN/달토끼-캐릭터-월야.png" 1000
add_image "char-baekhwa" "$SRC_DESIGN/달토끼-캐릭터-백화.png" 1000
add_image "char-yeonmong" "$SRC_DESIGN/달토끼-캐릭터-연몽.png" 1000
add_image "char-yunsan" "$SRC_DESIGN/달토끼-캐릭터-윤산.png" 1000
add_image "char-hongmae" "$SRC_DESIGN/달토끼-캐릭터-홍매.png" 1000
add_image "bg-01" "$SRC_DESIGN/달토끼-배경-01.png" 1200
add_image "bg-02" "$SRC_DESIGN/달토끼-배경-02.png" 1200
add_image "bg-03" "$SRC_DESIGN/달토끼-배경-03.png" 1200

echo "── 타로 메이저 아르카나 22장 (700px)"
MAJOR="$SRC_DESIGN/타로카드/타로-오리지널카드/tarot-cards-78/major-arcana"
for f in "$MAJOR"/*.jpg; do
  base=$(basename "$f" .jpg)           # 00-fool
  num="${base%%-*}"                    # 00
  add_image "tarot-major-${num}" "$f" 700
done

echo "── 타로 마이너 아르카나 56장 (700px)"
MINOR="$SRC_DESIGN/타로카드/타로-오리지널카드/tarot-cards-78/minor-arcana"
for suit in cups pentacles swords wands; do
  for f in "$MINOR/$suit"/*.jpg; do
    base=$(basename "$f" .jpg)         # cups-02
    add_image "tarot-${base}" "$f" 700
  done
done

echo "── 앱 아이콘"
ICON_DIR="$XCASSETS/AppIcon.appiconset"
mkdir -p "$ICON_DIR"
# dal-tokkie-icon은 145×127 — 1024 정사각 캔버스에 패딩 배치
sips --resampleHeight 1024 "$SRC_PUBLIC/dal-tokkie-icon.png" --out /tmp/dt-icon-big.png >/dev/null
sips --padToHeightWidth 1024 1024 --padColor 2A2F50 /tmp/dt-icon-big.png --out "$ICON_DIR/AppIcon.png" >/dev/null 2>&1 || cp /tmp/dt-icon-big.png "$ICON_DIR/AppIcon.png"
cat > "$ICON_DIR/Contents.json" <<'EOF'
{
  "images": [ { "filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024" } ],
  "info": { "author": "xcode", "version": 1 }
}
EOF

COUNT=$(find "$XCASSETS" -name "*.imageset" | wc -l | tr -d ' ')
SIZE=$(du -sh "$XCASSETS" | cut -f1)
echo "완료: 이미지셋 ${COUNT}개, ${SIZE}"
