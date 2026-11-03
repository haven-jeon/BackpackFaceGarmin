"""워치 페이스용 한글 비트맵 폰트(BMFont) 생성기.

기기 기본 폰트는 시계 언어가 한국어일 때만 한글을 그리므로, 화면에 쓰는 글자만 담은 폰트를 앱에 넣는다.
서체 (SIL OFL, fonts/OFL-Galmuri.txt): 화면별로 픽셀이 딱 맞는 크기를 쓴다.
  176 (Instinct 3 Solar) = 갈무리11 Bold 12px
  280 (Fenix 7X)         = 갈무리14 15px. Bold가 없어 가로로 1px 두껍게 그린다 (176과 같은 굵은 인상)

  python gen_korfont.py   → ../InstinctFace/resources-<화면>/fonts/kor.fnt, kor.png, fonts.xml

화면에 새 한글 문구를 쓰면 TEXTS에 추가하고 다시 실행할 것 (없는 글자는 기기에서 빈칸으로 나온다).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
# 화면 → (서체 파일, 크기 px, 가로 1px 굵게, BMFont face 이름)
TARGETS = {
    "176": ("Galmuri11-Bold.ttf", 12, False, "Galmuri11 Bold"),
    "280": ("Galmuri14.ttf", 15, True, "Galmuri14"),
}

# InstinctFaceView.mc 에서 이 폰트로 그리는 문구
TEXTS = [
    "일월화수목금토", "월", "일",                          # 날짜
    "맑아짐", "유지", "흐려짐", "폭풍 주의",                # 날씨 전망
    "이동 중", "측정 중", "기압계 없음",                    # 판단 불가 이유
    "일몰", "일출",                                        # 서브스크린 (다음 일몰·일출까지)
    "BB", "거리",                                          # 정보 칸 이름표 (걸음·알림은 이모지)
    "0123456789 +-%~:,.°mkd",                              # 값과 단위 (배터리 5d)
]


def export(target, font_file, size, bold, face):
    from gen_places import labels        # 지명 칸 (시·군·구, 100대 명산)
    chars = sorted(set("".join(TEXTS + labels())))
    font = ImageFont.truetype(str(HERE / "fonts" / font_file), size)
    ascent, descent = font.getmetrics()

    glyphs = []
    for ch in chars:
        bb = font.getbbox(ch)            # 원점(왼쪽 위) 기준
        w, h = max(bb[2] - bb[0], 0), max(bb[3] - bb[1], 0)
        img = Image.new("L", (max(w, 1), max(h, 1)), 0)
        if w and h:
            ImageDraw.Draw(img).text((-bb[0], -bb[1]), ch, fill=255, font=font)
            img = img.point(lambda v: 255 if v > 127 else 0)
        adv = round(font.getlength(ch))
        if bold and w and h:
            a = np.pad(np.array(img) > 0, ((0, 0), (0, 1)))
            a[:, 1:] |= a[:, :-1].copy()        # 오른쪽으로 1px 겹쳐 찍기
            img = Image.fromarray((a * 255).astype(np.uint8))
            w += 1
            adv += 1
        glyphs.append((ch, img, w, h, bb[0], bb[1], adv))

    # 한 줄씩 채우는 단순 아틀라스
    atlas_w, pad = 256, 1
    x = y = row_h = 0
    places = []
    for ch, img, w, h, *_ in glyphs:
        if x + w + pad > atlas_w:
            x, y, row_h = 0, y + row_h + pad, 0
        places.append((x, y))
        x += w + pad
        row_h = max(row_h, h)
    atlas_h = y + row_h + pad

    atlas = Image.new("RGBA", (atlas_w, atlas_h), (255, 255, 255, 0))
    lines = []
    for (ch, img, w, h, xo, yo, adv), (px, py) in zip(glyphs, places):
        if w and h:
            atlas.paste(Image.new("RGBA", (w, h), (255, 255, 255, 255)), (px, py), img)
        lines.append(f"char id={ord(ch)} x={px} y={py} width={w} height={h} "
                     f"xoffset={xo} yoffset={yo} xadvance={adv} page=0 chnl=15")

    out = HERE.parent / "InstinctFace" / f"resources-{target}" / "fonts"
    out.mkdir(parents=True, exist_ok=True)
    atlas.save(out / "kor.png")
    fnt = [
        f'info face="{face}" size={size} bold=1 italic=0 charset="" unicode=1 '
        f'stretchH=100 smooth=0 aa=0 padding=0,0,0,0 spacing=1,1',
        f"common lineHeight={ascent + descent} base={ascent} scaleW={atlas_w} scaleH={atlas_h} pages=1 packed=0",
        'page id=0 file="kor.png"',
        f"chars count={len(lines)}",
        *lines,
    ]
    (out / "kor.fnt").write_text("\n".join(fnt) + "\n")
    (out / "fonts.xml").write_text(
        '<fonts>\n    <font id="Kor" filename="kor.fnt" antialias="false" />\n</fonts>\n')
    print(f"[{target}] {len(chars)} glyphs, atlas {atlas_w}x{atlas_h}, lineHeight {ascent + descent} → {out}")


def main():
    for target, cfg in TARGETS.items():
        export(target, *cfg)


if __name__ == "__main__":
    main()
