"""백패킹 워치 페이스용 시각 숫자 비트맵 생성기 (Instinct 3 Solar, 1bpp).

스타일마다 0-9와 콜론을 흑백 비트맵으로 만들고, 실제 화면(base_screen.png)에 합성한 미리보기를 저장한다.

  python gen_digits.py preview           → previews/digit_options.png (4개 스타일 비교)
  python gen_digits.py export <style>    → ../InstinctFace/resources/drawables/time/ 에 PNG 출력

서체: Barlow Condensed, Big Shoulders Stencil Display (둘 다 SIL OFL, fonts/ 참고)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONTS = HERE / "fonts"
DIGIT_H = 44          # 숫자 높이(px)
SS = 4                # 슈퍼샘플링 배율
TIME_CY = 92          # 화면에서 시각 중심 y
TRACK = 3             # 숫자 사이 간격


# ---------------- 마스크 유틸 (True = 흰 픽셀) ----------------

def erode(m, r):
    out = m.copy()
    for _ in range(r):
        p = np.pad(out, 1, constant_values=False)
        out = p[1:-1, 1:-1] & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return out


def edge(m):
    return m & ~erode(m, 1)


def render_glyph(font_path, ch, variation=None):
    """문자를 DIGIT_H 높이로 렌더링한 bool 마스크 (세로는 숫자 높이에 딱 맞춘다)."""
    size = DIGIT_H * SS
    font = ImageFont.truetype(str(font_path), size)
    if variation is not None:
        font.set_variation_by_axes(variation)
    # '0'의 실제 높이로 크기 보정
    b = font.getbbox("0")
    font = ImageFont.truetype(str(font_path), int(size * size / (b[3] - b[1])))
    if variation is not None:
        font.set_variation_by_axes(variation)
    b0 = font.getbbox("0")
    bb = font.getbbox(ch)
    w = bb[2] - bb[0]
    im = Image.new("L", (w + 2 * SS, DIGIT_H * SS), 0)
    ImageDraw.Draw(im).text((SS - bb[0], -b0[1]), ch, fill=255, font=font)
    small = im.resize((im.width // SS, DIGIT_H), Image.BOX)
    m = np.array(small) > 110
    cols = np.where(m.any(axis=0))[0]
    return m[:, cols[0]:cols[-1] + 1]


def pad_to(m, w):
    """가운데 정렬로 폭 w에 맞춘다 (모든 숫자를 같은 폭으로 → 시각이 바뀔 때 흔들리지 않음)."""
    left = (w - m.shape[1]) // 2
    out = np.zeros((m.shape[0], w), bool)
    out[:, left:left + m.shape[1]] = m
    return out


def dot_colon(r=2, gap=16, square=False):
    m = np.zeros((DIGIT_H, 2 * r + 1), bool)
    for cy in (DIGIT_H // 2 - gap // 2, DIGIT_H // 2 + gap // 2):
        for y in range(-r, r + 1):
            for x in range(-r, r + 1):
                if square or x * x + y * y <= r * r + 1:
                    m[cy + y, r + x] = True
    return m


# ---------------- 스타일 ----------------
# 각 스타일은 (digits: dict[str, mask], colon: mask, post: 함수 or None) 을 만든다.
# post는 시각 전체를 이어 붙인 뒤 적용하는 효과 (능선 컷처럼 숫자를 가로지르는 것).

def style_topo():
    """등고선: 굵은 숫자의 외곽선 + 안쪽 등고선 2개."""
    f = FONTS / "BarlowCondensed-ExtraBold.ttf"
    digits = {}
    for c in "0123456789":
        m = render_glyph(f, c)
        digits[c] = edge(m) | edge(erode(m, 3)) | edge(erode(m, 6))
    return digits, dot_colon(2), None


def style_stitch():
    """스티치 패치: 꽉 찬 숫자 안쪽을 박음질 점선이 따라간다."""
    f = FONTS / "BarlowCondensed-ExtraBold.ttf"
    digits = {}
    for c in "0123456789":
        m = render_glyph(f, c)
        line = edge(erode(m, 2))
        ys, xs = np.nonzero(line)
        out = m.copy()
        dash = ((xs + ys) // 2) % 2 == 0
        out[ys[dash], xs[dash]] = False
        digits[c] = out
    return digits, dot_colon(2), None


def style_ridge():
    """능선 컷: 꽉 찬 숫자를 산 능선이 가로지르고, 능선 아래는 가로 해칭."""
    f = FONTS / "BarlowCondensed-Bold.ttf"
    digits = {c: render_glyph(f, c) for c in "0123456789"}

    def post(m):
        h, w = m.shape
        xs = np.arange(w)
        # 겹친 사인파로 만든 능선 (숫자 높이의 55~75% 사이)
        ridge = (h * 0.64 + 3.2 * np.sin(xs / w * 2 * np.pi * 1.6 + 0.6)
                 + 2.0 * np.sin(xs / w * 2 * np.pi * 4.3)).astype(int)
        out = m.copy()
        for x in xs:
            r = ridge[x]
            out[r:r + 2, x] = False                       # 능선 틈
            below = np.arange(r + 2, h)
            out[below[(below % 2) == 1], x] = False       # 아래는 해칭
        return out

    return digits, dot_colon(2), post


# 뾰족한 봉우리가 모인 산군 (x, y 모두 시각 줄 폭/숫자 높이에 대한 비율, y=0이 위)
SKYLINE = [(0.00, 0.66), (0.05, 0.58), (0.09, 0.63), (0.15, 0.47), (0.19, 0.53),
           (0.25, 0.33), (0.28, 0.40), (0.33, 0.18), (0.36, 0.30), (0.39, 0.24),
           (0.43, 0.39), (0.48, 0.31), (0.53, 0.46), (0.60, 0.41), (0.67, 0.55),
           (0.74, 0.49), (0.81, 0.60), (0.88, 0.55), (0.94, 0.63), (1.00, 0.60)]


def skyline(w, h):
    xs = np.arange(w) / max(w - 1, 1)
    px, py = zip(*SKYLINE)
    return np.round(np.interp(xs, px, py) * h).astype(int)


def style_alpine(banded_sky=True):
    """알파인: 아래는 꽉 찬 산, 위 하늘은 위로 갈수록 촘촘해지는 가로 띠, 경계는 1px 틈."""
    f = FONTS / "BarlowCondensed-Bold.ttf"
    digits = {c: render_glyph(f, c) for c in "0123456789"}
    gap_rows = [1, 4, 7, 10, 14, 18, 23, 29]   # 하늘 띠 사이 틈 (아래로 갈수록 간격이 넓어짐)

    def post(m):
        h, w = m.shape
        ridge = skyline(w, h)
        out = m.copy()
        for x in range(w):
            r = ridge[x]
            out[max(r - 2, 0):r, x] = False            # 능선 위 틈
            if banded_sky:
                for g in gap_rows:
                    if g < r - 2:
                        out[g, x] = False
        return out

    return digits, dot_colon(2), post


def style_stencil():
    """스텐실: 장비 상자·배낭에 찍힌 글씨."""
    f = FONTS / "BigShouldersStencilDisplay.ttf"
    digits = {c: render_glyph(f, c, variation=[800]) for c in "0123456789"}
    return digits, dot_colon(2, square=True), None


STYLES = {
    "topo": ("1. 등고선", style_topo),
    "stitch": ("2. 스티치 패치", style_stitch),
    "ridge": ("3. 능선 컷", style_ridge),
    "stencil": ("4. 스텐실", style_stencil),
    "alpine": ("3-A. 알파인 (하늘 띠)", lambda: style_alpine(True)),
    "alpine_plain": ("3-B. 알파인 (틈만)", lambda: style_alpine(False)),
}


def build(style):
    digits, colon, post = STYLES[style][1]()
    cell = max(d.shape[1] for d in digits.values())
    digits = {c: pad_to(d, cell) for c, d in digits.items()}
    return digits, colon, post, cell


def compose_time(style, text="09:41"):
    digits, colon, post, _ = build(style)
    parts = [colon if ch == ":" else digits[ch] for ch in text]
    gap = np.zeros((DIGIT_H, TRACK), bool)
    row = np.concatenate([p for part in parts for p in (part, gap)][:-1], axis=1)
    return post(row) if post else row


def preview(keys=None, name="digit_options.png", scale=2):
    base = np.array(Image.open(HERE / "base_screen.png").convert("L")) > 128
    panels = []
    for key in keys or STYLES:
        label = STYLES[key][0]
        scr = base.copy()
        scr[66:117, :] = False
        t = compose_time(key)
        y0 = TIME_CY - DIGIT_H // 2
        x0 = (176 - t.shape[1]) // 2
        scr[y0:y0 + DIGIT_H, x0:x0 + t.shape[1]] = t
        panels.append((label, scr))

    pad, top = 16, 34
    W = len(panels) * (176 * scale + pad) + pad
    sheet = Image.new("RGB", (W, 176 * scale + top + pad), (40, 40, 40))
    kfont = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", 20)
    d = ImageDraw.Draw(sheet)
    for i, (label, scr) in enumerate(panels):
        img = Image.fromarray((scr * 255).astype(np.uint8)).resize((176 * scale,) * 2, Image.NEAREST)
        x = pad + i * (176 * scale + pad)
        sheet.paste(img.convert("RGB"), (x, top))
        d.text((x, 6), label, fill=(240, 240, 240), font=kfont)
    out = HERE / "previews" / name
    out.parent.mkdir(exist_ok=True)
    sheet.save(out)
    print(out)


def export(style):
    """자리(0~3)별 숫자 비트맵 40장 + 콜론, drawables XML, 배치 상수 Monkey C 모듈을 생성한다.
    능선이 시각 줄 전체를 가로지르므로 같은 숫자라도 자리마다 모양이 다르다."""
    digits, colon, post, cell = build(style)
    proj = HERE.parent / "InstinctFace"
    out_dir = proj / "resources" / "drawables" / "time"
    out_dir.mkdir(parents=True, exist_ok=True)

    # 자리별 x 오프셋: [d0, d1, colon, d2, d3]
    widths = [cell, cell, colon.shape[1], cell, cell]
    xs, x = [], 0
    for w in widths:
        xs.append(x)
        x += w + TRACK
    total = x - TRACK

    def row_with(pos_digit):
        parts = []
        for slot in range(5):
            if slot == 2:
                parts.append(colon)
            else:
                pos = slot if slot < 2 else slot - 1
                parts.append(digits[pos_digit.get(pos, "0")])
        gap = np.zeros((DIGIT_H, TRACK), bool)
        row = np.concatenate([p for part in parts for p in (part, gap)][:-1], axis=1)
        return post(row) if post else row

    def save(mask, name):
        Image.fromarray((mask * 255).astype(np.uint8)).convert("1").save(out_dir / f"{name}.png")

    xml = ["<drawables>"]
    slots = [0, 1, 3, 4]
    for pos in range(4):
        for d in "0123456789":
            row = row_with({pos: d})
            x0 = xs[slots[pos]]
            save(row[:, x0:x0 + cell], f"t{pos}_{d}")
            xml.append(f'    <bitmap id="T{pos}_{d}" filename="time/t{pos}_{d}.png">'
                       f'<palette disableTransparency="true"><color>000000</color><color>FFFFFF</color></palette></bitmap>')
    save(colon, "colon")   # 콜론은 능선 효과 없이 꽉 찬 점 (띠 틈에 걸리면 깨져 보임)
    xml.append('    <bitmap id="TColon" filename="time/colon.png">'
               '<palette disableTransparency="true"><color>000000</color><color>FFFFFF</color></palette></bitmap>')
    xml.append("</drawables>")
    (out_dir.parent / "time.xml").write_text("\n".join(xml) + "\n")

    ids = ",\n            ".join(
        "[" + ", ".join(f"Rez.Drawables.T{p}_{d}" for d in "0123456789") + "]" for p in range(4))
    (proj / "source" / "TimeGlyphs.mc").write_text(f"""import Toybox.Lang;

// design/gen_digits.py export {style} 로 생성된 파일. 직접 고치지 말고 스크립트를 다시 실행할 것.
module TimeGlyphs {{
    const H = {DIGIT_H};
    const TOTAL_W = {total};
    const XS = [{xs[0]}, {xs[1]}, {xs[3]}, {xs[4]}];   // 숫자 자리 0~3의 x 오프셋
    const COLON_X = {xs[2]};

    // [자리][숫자] → 리소스 ID
    function ids() as Array<Array<ResourceId>> {{
        return [
            {ids}
        ];
    }}
}}
""")
    print(f"exported {style}: cell={cell} total={total} → {out_dir}")


if __name__ == "__main__":
    if sys.argv[1:2] == ["export"]:
        export(sys.argv[2])
        sys.exit()
    if sys.argv[1:2] == ["preview"]:
        keys = sys.argv[2:] or None
        preview(keys, "digit_options.png" if keys is None else "_".join(keys) + ".png", 2 if keys is None else 3)
    else:
        print(__doc__)
