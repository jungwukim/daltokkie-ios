#!/usr/bin/env node
// 라이선스 클린 천체력 데이터 추출 — 외부 코드 실행 없이 텍스트 파싱만 사용
// 출처: astronomia v4.1.1 (MIT, Sonia Keys & commenthol) — /tmp/astronomia-pkg/package
//  - VSOP87B 행성 시리즈 (Bretagnon & Francou, 자유 배포 천문 데이터)
//  - Meeus 달(ch.47)/명왕성(ch.37) 주기항 테이블
// 출력: Engine/Sources/NatalKit/Resources/clean-ephemeris.json

const { readFileSync, writeFileSync } = require("node:fs");
const path = require("node:path");

const PKG = "/tmp/astronomia-pkg/package";
const OUT = path.join(__dirname, "../Engine/Sources/NatalKit/Resources/clean-ephemeris.json");

// ── VSOP87B 텍스트 파서 (줄 단위 상태 기계 — require/실행 금지)
function parseVsop87(file) {
  const src = readFileSync(file, "utf8");
  const series = { L: [[], [], [], [], [], []], B: [[], [], [], [], [], []], R: [[], [], [], [], [], []] };
  let curSeries = null;
  let curPower = -1;
  for (const rawLine of src.split("\n")) {
    const line = rawLine.trim();
    const seriesMatch = line.match(/^([LBR]): \{$/);
    if (seriesMatch) { curSeries = seriesMatch[1]; curPower = -1; continue; }
    const powerMatch = line.match(/^"(\d)": \[$/);
    if (powerMatch && curSeries) { curPower = Number(powerMatch[1]); continue; }
    const termMatch = line.match(/^\[([-\d.eE]+), ([-\d.eE]+), ([-\d.eE]+)\],?$/);
    if (termMatch && curSeries && curPower >= 0) {
      series[curSeries][curPower].push([Number(termMatch[1]), Number(termMatch[2]), Number(termMatch[3])]);
    }
  }
  return series;
}

const planets = {};
for (const name of ["mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune"]) {
  const s = parseVsop87(`${PKG}/lib/data/vsop87B${name}.cjs`);
  const total = ["L", "B", "R"].reduce((acc, k) => acc + s[k].reduce((a, p) => a + p.length, 0), 0);
  if (total < 100) throw new Error(`${name} 파싱 실패: ${total}항`);
  planets[name] = s;
}

// ── 달 주기항 (moonposition.cjs 텍스트 추출)
const moonSrc = readFileSync(`${PKG}/lib/moonposition.cjs`, "utf8");

function extractRows(src, startMarker, endMarker, perRow) {
  const start = src.indexOf(startMarker);
  const end = src.indexOf(endMarker, start);
  if (start < 0 || end < 0) throw new Error(`마커 못 찾음: ${startMarker}`);
  const block = src.slice(start, end);
  const rows = [];
  const re = /\[([-\d.,\s]+)\]/g;
  let m;
  while ((m = re.exec(block))) {
    const nums = m[1].split(",").map((s) => Number(s.trim())).filter((n) => !Number.isNaN(n));
    if (nums.length === perRow) rows.push(nums);
  }
  return rows;
}

// ta: [d, m, m_, f, Σl, Σr] / tb: [d, m, m_, f, Σb]
const moonTa = extractRows(moonSrc, "const ta =", "return ta.map", 6);
const moonTb = extractRows(moonSrc, "const tb =", "return tb.map", 5);
if (moonTa.length !== 60 || moonTb.length !== 60) {
  throw new Error(`달 테이블 추출 실패: ta=${moonTa.length}, tb=${moonTb.length} (기대 60/60)`);
}

// ── 명왕성 주기항 (Meeus ch.37): new Pt(i,j,k, lA,lB, bA,bB, rA,rB)
const plutoSrc = readFileSync(`${PKG}/lib/pluto.cjs`, "utf8");
const pluto = [];
const ptRe = /new Pt\(([^)]+)\)/g;
let pm;
while ((pm = ptRe.exec(plutoSrc))) {
  const nums = pm[1].split(",").map((s) => Number(s.trim()));
  if (nums.length === 9) pluto.push(nums);
}
if (pluto.length !== 43) throw new Error(`명왕성 테이블 ${pluto.length}항 (기대 43)`);

const out = {
  source: "astronomia v4.1.1 (MIT) — VSOP87B + Meeus moon(ch.47)/pluto(ch.37)",
  planets,
  moon: { ta: moonTa, tb: moonTb },
  pluto,
};

writeFileSync(OUT, JSON.stringify(out));
const sizeKB = Math.round(JSON.stringify(out).length / 1024);
console.log(`clean-ephemeris.json 생성 (${sizeKB}KB)`);
for (const [name, s] of Object.entries(planets)) {
  const total = ["L", "B", "R"].reduce((acc, k) => acc + s[k].reduce((a, p) => a + p.length, 0), 0);
  console.log(`  ${name}: ${total}항`);
}
console.log(`  moon: ta ${moonTa.length} + tb ${moonTb.length}, pluto: ${pluto.length}`);
