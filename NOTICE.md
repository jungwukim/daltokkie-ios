# 제3자 데이터·알고리즘 고지 (NOTICE)

이 앱의 천체력(NatalKit)은 다음의 자유 이용 가능한 출처로만 구성되어 있습니다.
**Swiss Ephemeris(AGPL) 코드·데이터는 포함되어 있지 않습니다.**

## astronomia (MIT License)

달(Meeus ch.47)·명왕성(Meeus ch.37) 주기항 테이블과 황도 세차(EclipticPrecessor)
알고리즘은 astronomia v4.1.1에서 포팅했습니다.

> The MIT License (MIT)
> Copyright (c) 2013 Sonia Keys
> Copyright (c) 2016 Commenthol
>
> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the "Software"), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
> the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
> FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
> COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
> IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
> CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## VSOP87 행성 이론

행성 위치는 VSOP87B 해석 이론(P. Bretagnon & G. Francou,
"Planetary theories in rectangular and spherical variables. VSOP87 solutions",
Astronomy & Astrophysics 202, 1988)의 공개 시리즈 데이터를 사용합니다.
데이터는 천문학계에 자유 배포되어 왔으며 astronomia 패키지 동봉본에서 추출했습니다.

## JPL Horizons (퍼블릭 도메인)

키론(2060 Chiron)의 위치 테이블(1900~2100, 10일 간격)은 NASA/JPL Horizons
시스템에서 생성했습니다. 미국 정부 저작물로 퍼블릭 도메인입니다.
출처: https://ssd.jpl.nasa.gov/horizons/

## 공개 표준 공식

다음은 공개 천문학 표준 공식의 자체 구현입니다:
- 율리우스일, 평균 황도경사(IAU 1980), 항성시(IAU 1982)
- 간이 장동 (J. Meeus, "Astronomical Algorithms" ch.22 저정밀 공식)
- ΔT 다항식 (F. Espenak & J. Meeus, NASA Eclipse 웹사이트)
- 평균 달 교점, MC/ASC 구면삼각 공식, Placidus 반호 분할 반복법

## 기타 의존성

- 사주 계산: @hoshin/saju-mcp-server 포팅 (MIT)
- 음력 변환: lunar-javascript 테이블 추출 (MIT)
- 타로/캐릭터/배경 일러스트: 달토끼 프로젝트 자체 제작 에셋

## 번들 폰트

- **Pretendard** (길형진/orioncactus) — SIL Open Font License 1.1.
  `App/Fonts/Pretendard-{Regular,Medium,SemiBold,Bold}.otf`로 번들 (앱 전체 타이포 통일).
  OFL은 폰트 자체 판매만 금지하며 앱 임베딩·배포는 허용. 출처: https://github.com/orioncactus/pretendard
