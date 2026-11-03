# design — InstinctFace 리소스 생성

워치 페이스의 비트맵·폰트·지명표는 손으로 그리지 않고 이 폴더의 스크립트로 만든다.
결과물은 `InstinctFace/`에 커밋되어 있으므로 디자인을 바꿀 때만 다시 실행한다.

화면 크기마다 따로 만든다. 스크립트 한 번에 두 화면이 모두 나온다.

| 화면 | 기기 | 리소스 / 배치 상수 | 한글 폰트 | 이모지 |
|---|---|---|---|---|
| 176 | Instinct 3 Solar | `resources-176/`, `source-176/` | 갈무리11 Bold 12px | 12px |
| 280 | Fenix 7X | `resources-280/`, `source-280/` | 갈무리14 15px (가로 1px 굵게) | 15px |

배너·시각 숫자는 280에서 176의 1.5배로 다시 그린다 (확대가 아니라 같은 모양을 큰 해상도로 렌더링).
`source-<화면>/Layout.mc`(글자·칸·서브스크린 좌표)는 손으로 쓰고, `Banner.mc`는 `gen_banner.py`가 만든다.

```sh
cd design
uv run --no-project --with pillow --with numpy python <스크립트> [명령]
```

## 생성 스크립트 → 결과물

| 스크립트 | 입력 | 결과물 (`InstinctFace/` 기준) |
|---|---|---|
| `gen_banner.py export` | `fonts/AlfaSlabOne-Regular.ttf` | `resources-<화면>/drawables/banner/`, `time/` (시각 숫자 41장), `banner.xml`, `time.xml`, `source-<화면>/Banner.mc` |
| `gen_emoji.py` | `fonts/NotoEmoji.ttf` | `resources-<화면>/drawables/emoji/`, `emoji.xml` |
| `gen_korfont.py` | `fonts/Galmuri11-Bold.ttf`, `Galmuri14.ttf`, 문구 목록(`TEXTS`), 지명표 | `resources-<화면>/fonts/kor.fnt`, `kor.png`, `fonts.xml` |
| `gen_places.py` | `places/sigungu.csv`, `places/mountains.csv` | `resources/jsonData/places_*.json`, `places.xml`, `source/PlaceChunks.mc` (화면 공통) |

주의
- 화면에 새 한글 문구를 넣으면 `gen_korfont.py`의 `TEXTS`에 추가하고 다시 실행한다. 폰트에 없는 글자는 시계에서 빈칸으로 나온다.
- 지명표 CSV를 고치면 `gen_places.py` → `gen_korfont.py` 순서로 실행한다 (지명 글자도 폰트에 들어가야 함).
- 2026-11-03 기준 네 스크립트 모두 커밋된 리소스와 픽셀 단위로 같은 결과를 낸다.
- 배너 크기·위치를 바꾸면 `gen_banner.py`의 `TARGETS`와 `source-<화면>/Layout.mc`를 함께 맞춘다
  (`BEZEL`·`TEXT_BOTTOM`은 고라니가 서브스크린 원이나 좌상단 글자와 겹치지 않게 하는 경계).

## 시안 비교용 (리소스를 바꾸지 않음)

| 명령 | 결과 |
|---|---|
| `gen_banner.py preview` | `previews/banner_options.png` — 숫자 안 산그리메 방식 A/B/C 비교 (채택: C `solid`, 176) |
| `gen_banner.py spots` | `previews/deer_spots.png` — 고라니가 설 수 있는 자리 모음 (176) |
| `preview_emoji.py` | `previews/emoji_options.png` — 12px·16px 이모지 후보 |

`base_screen.png`는 시뮬레이터 화면(176×176, 1bpp)으로, `gen_banner.py preview`가 배너를 합성하는 배경이다.
시뮬레이터 스크린샷을 2배 해상도로 잘라 176×176으로 줄이고 흑백 이진화해서 만든다.

## 폴더
- `fonts/` — 쓰는 서체와 OFL 라이선스: Alfa Slab One(시각 숫자), Galmuri11 Bold·Galmuri14(한글), Noto Emoji(아이콘)
- `places/` — 지명표 원본과 출처 ([README](places/README.md))
- `previews/` — 위 시안 이미지

## 이력
초기 시안(펙 숫자, 능선컷 숫자 `gen_digits.py`, Barlow·Big Shoulders·Zilla Slab 서체)은 배너 방식으로 바뀌면서 지웠다.
필요하면 초기 커밋에서 꺼낼 수 있다.
