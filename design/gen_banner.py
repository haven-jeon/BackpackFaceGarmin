"""파타고라니 오마주 배너 생성기 (Instinct 3 Solar, 1bpp).

배너 = 물결 띠 하늘(흰 바탕) + 뾰족한 산맥(검정) + 봉우리 위 고라니. 시각 숫자는 흰 슬랩 세리프로 산 위에 얹는다.

  python gen_banner.py preview   → previews/banner_options.png (숫자 서체 비교)
  python gen_banner.py export    → ../InstinctFace/resources/ 에 배너·고라니 비트맵, 숫자 폰트 출력
  python gen_banner.py spots     → previews/deer_spots.png (고라니가 설 수 있는 자리 모음)

서체: Zilla Slab Bold, Alfa Slab One (SIL OFL, fonts/ 참고)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
FONTS = HERE / "fonts"
PROJ = HERE.parent / "InstinctFace"

# 화면 좌표. 서브스크린 베젤(중심 144,31 반경 약 40)을 피하려고 배너는 y=72부터.
BX, BY, BW, BH = 8, 72, 160, 60
DIGIT_H = 32                 # 숫자 높이
DIGIT_Y = BY + BH - DIGIT_H - 2   # 숫자 윗변(화면 좌표)

# 산맥 꼴: (x 비율, 배너 안 y px). 봉우리 4~5개, 고라니는 DEER_PEAK 봉우리 위에 선다.
RIDGE = [(0.00, 25), (0.04, 21), (0.08, 23), (0.13, 16), (0.17, 19), (0.21, 14), (0.24, 18),
         (0.30, 20), (0.36, 17), (0.42, 21), (0.50, 19), (0.56, 12), (0.60, 15), (0.63, 13),
         (0.68, 19), (0.74, 16), (0.80, 22), (0.85, 14), (0.88, 17), (0.93, 21), (1.00, 24)]
DEER_PEAK = (0.56, 12)   # 발 4개가 봉우리 꼭대기 근처에 닿는다
SUN_Y = (11, 5)              # 해 높이: 일출·일몰 때 y, 정오 때 y (배너 안 좌표)


def ridge_y():
    xs = np.arange(BW) / (BW - 1)
    px, py = zip(*RIDGE)
    return np.round(np.interp(xs, px, py)).astype(int)


def make_banner():
    """True = 흰 픽셀. 하늘은 흰 바탕에 물결 띠, 능선 아래는 검정."""
    m = np.ones((BH, BW), bool)
    xs = np.arange(BW)
    # 물결 띠: (기준 y, 두께, 진폭, 주기, 위상)
    for y0, th, amp, per, ph in [(3, 1, 0.8, 70, 0.0), (11, 1, 0.8, 80, 2.1)]:
        ys = np.round(y0 + amp * np.sin(xs / per * 2 * np.pi + ph)).astype(int)
        for x, y in zip(xs, ys):
            m[y:y + th, x] = False
    # 로고의 주황 띠 → 체크무늬(디더링) 띠
    ys = np.round(6.5 + 0.9 * np.sin(xs / 64 * 2 * np.pi + 0.7)).astype(int)
    for x, y in zip(xs, ys):
        for yy in range(y, y + 2):
            if (x + yy) % 2 == 0:
                m[yy, x] = False
    # 산맥
    r = ridge_y()
    for x in xs:
        m[r[x]:, x] = False
    return m


# 고라니 픽셀 아트 (왼쪽을 보고 선 모습). 뿔 없이 크고 둥근 귀, 긴 목, 가는 다리. '#' = 검정
DEER = [
    "...##.##............",
    "...##.##............",
    "....#####...........",
    "...######...........",
    ".#######............",
    "#######.............",
    "..#####.............",
    "...####.............",
    "...####.............",
    "....####............",
    "....#############...",
    "....###############.",
    "....################",
    "....################",
    ".....###########.##.",
    ".....##.##.....###..",
    ".....#...#.....#.#..",
    ".....#...#....#..#..",
    ".....#...#....#..#..",
    ".....#...#....#..#..",
]


def make_deer():
    return np.array([[c == "#" for c in row] for row in DEER])


def digit_font(path, h):
    """숫자 높이가 h가 되는 크기로 연다."""
    f = ImageFont.truetype(str(path), 100)
    b = f.getbbox("0")
    return ImageFont.truetype(str(path), round(100 * h / (b[3] - b[1])))


def render_text(font, text, track=2):
    """시각 문자열을 1bpp 마스크로. 숫자는 고정 폭 칸 가운데 정렬 (시각이 바뀌어도 흔들리지 않게)."""
    cell = max(font.getbbox(c)[2] - font.getbbox(c)[0] for c in "0123456789")
    top = font.getbbox("0")[1]
    parts = []
    for ch in text:
        bb = font.getbbox(ch)
        w = bb[2] - bb[0]
        cw = cell if ch.isdigit() else w
        im = Image.new("L", (cw * 4, DIGIT_H * 4), 0)
        big = ImageFont.truetype(font.path, font.size * 4)
        bb4 = big.getbbox(ch)
        ImageDraw.Draw(im).text(((cw * 4 - (bb4[2] - bb4[0])) // 2 - bb4[0], -big.getbbox("0")[1]), ch, fill=255, font=big)
        parts.append(np.array(im.resize((cw, DIGIT_H), Image.BOX)) > 110)
        parts.append(np.zeros((DIGIT_H, track), bool))
    return np.concatenate(parts[:-1], axis=1)


# 숫자 안의 산그리메: 먼 능선과 가까운 능선 (x 비율, 숫자 안 y px). 가까운 능선이 늘 3px 이상 아래.
FAR_RIDGE = [(0.00, 11), (0.08, 9), (0.15, 12), (0.24, 7), (0.30, 10), (0.38, 8), (0.47, 12),
             (0.55, 9), (0.63, 6), (0.70, 10), (0.80, 8), (0.90, 11), (1.00, 9)]
NEAR_RIDGE = [(0.00, 20), (0.10, 17), (0.18, 19), (0.27, 14), (0.34, 18), (0.42, 16), (0.50, 20),
              (0.60, 15), (0.66, 17), (0.75, 13), (0.82, 18), (0.92, 16), (1.00, 19)]
SKY_GAPS = [1, 4]            # 숫자 윗부분 하늘 띠 사이 틈


def profile(pts, w):
    xs = np.arange(w) / max(w - 1, 1)
    px, py = zip(*pts)
    return np.round(np.interp(xs, px, py)).astype(int)


def mountain_layers(row, mode="dither"):
    """시각 줄 마스크에 산그리메를 새긴다. 위: 하늘 띠 / 가운데: 먼 산 / 아래: 가까운 산(꽉 참).
    mode: "dither" = 먼 산을 옅게(대기 원근), "solid" = 먼 산도 꽉 참, "alpine" = 능선 하나(이전 3-A)."""
    h, w = row.shape
    out = row.copy()
    if mode == "alpine":
        near = profile(NEAR_RIDGE, w) - 4
        for x in range(w):
            out[near[x] - 2:near[x], x] = False
            for g in SKY_GAPS + [7, 10]:
                if g < near[x] - 2:
                    out[g, x] = False
        return out
    far, near = profile(FAR_RIDGE, w), profile(NEAR_RIDGE, w)
    for x in range(w):
        for g in SKY_GAPS:
            if g < far[x] - 1:
                out[g, x] = False
        out[far[x] - 1, x] = False                      # 먼 능선 틈
        if mode == "dither":
            for y in range(far[x], near[x] - 1):
                if x % 2 == 0 and y % 2 == 0:
                    out[y, x] = False
        out[near[x] - 1, x] = False                     # 가까운 능선 틈
    return out


def compose(base, font, text="11:22", sun_frac=0.42, mode=None):
    scr = base.copy()
    scr[BY - 5:BY + BH + 3, :] = False
    scr[BY:BY + BH, BX:BX + BW] = make_banner()
    # 패치 테두리: 1px 틈 + 1px 흰 선 (산의 검정이 화면 배경과 섞이지 않게)
    x0, y0, x1, y1 = BX - 2, BY - 2, BX + BW + 1, BY + BH + 1
    scr[y0, x0 + 1:x1] = scr[y1, x0 + 1:x1] = True
    scr[y0 + 1:y1, x0] = scr[y0 + 1:y1, x1] = True
    # 해: 흰 테두리 + 검정 원
    sx = BX + int((BW - 1) * sun_frac)
    sy = BY + int(SUN_Y[0] - (SUN_Y[0] - SUN_Y[1]) * np.sin(np.pi * sun_frac))
    yy, xx = np.ogrid[:176, :176]
    d2 = (xx - sx) ** 2 + (yy - sy) ** 2
    scr[d2 <= 16] = True
    scr[d2 <= 6] = False
    # 고라니: 발이 봉우리에 닿게
    deer = make_deer()
    dx = BX + int((BW - 1) * DEER_PEAK[0]) - deer.shape[1] // 2
    dy = BY + DEER_PEAK[1] - deer.shape[0] + 1
    # 머리가 배너 위 검정 바탕으로 튀어나가므로 1px 흰 테두리를 먼저 깐다
    halo = np.pad(deer, 1)
    halo = halo | np.roll(halo, 1, 0) | np.roll(halo, -1, 0) | np.roll(halo, 1, 1) | np.roll(halo, -1, 1)
    hy, hx = dy - 1, dx - 1
    scr[hy:hy + halo.shape[0], hx:hx + halo.shape[1]] |= halo
    scr[dy:dy + deer.shape[0], dx:dx + deer.shape[1]] &= ~deer
    # 시각
    t = render_text(font, text)
    if mode:
        t = mountain_layers(t, mode)
    x0 = 88 - t.shape[1] // 2
    scr[DIGIT_Y:DIGIT_Y + DIGIT_H, x0:x0 + t.shape[1]] |= t
    return scr


def preview():
    base = np.array(Image.open(HERE / "base_screen.png").convert("L")) > 128
    a = FONTS / "AlfaSlabOne-Regular.ttf"
    opts = [("A. 능선 하나 (이전 3-A)", a, "alpine"), ("B. 산그리메 (먼 산 옅게)", a, "dither"),
            ("C. 산그리메 (먼 산 꽉 참)", a, "solid")]
    scale, pad, top = 3, 16, 34
    sheet = Image.new("RGB", (len(opts) * (176 * scale + pad) + pad, 176 * scale + top + pad), (40, 40, 40))
    kfont = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", 22)
    dr = ImageDraw.Draw(sheet)
    for i, (label, path, mode) in enumerate(opts):
        scr = compose(base, digit_font(path, DIGIT_H), mode=mode)
        img = Image.fromarray((scr * 255).astype(np.uint8)).resize((176 * scale,) * 2, Image.NEAREST)
        x = pad + i * (176 * scale + pad)
        sheet.paste(img.convert("RGB"), (x, top))
        dr.text((x, 6), label, fill=(240, 240, 240), font=kfont)
    out = HERE / "previews" / "banner_options.png"
    sheet.save(out)
    print(out)


DIGIT_FONT = FONTS / "AlfaSlabOne-Regular.ttf"
DIGIT_MODE = "solid"         # 숫자 안 산그리메: "solid" / "dither" / "alpine" (preview로 비교)
TRACK = 2


def deer_with_halo():
    """고라니(검정) + 1px 흰 테두리. 반환: (검정 마스크, 흰 마스크), 둘 다 halo 크기."""
    deer = np.pad(make_deer(), 1)
    halo = deer | np.roll(deer, 1, 0) | np.roll(deer, -1, 0) | np.roll(deer, 1, 1) | np.roll(deer, -1, 1)
    return deer, halo & ~deer


# 고라니가 능선 여기저기에 선다 (시각마다 자리를 바꿈). 능선이 울퉁불퉁해서 다리 길이를 자리마다
# 땅에 맞게 늘이거나(최대 LEG_EXT) 땅속으로 묻는다(최대 LEG_SINK). 자리마다 비트맵을 미리 그려 둔다.
LEG_EXT, LEG_SINK = 4, 2
SPOT_GAP = 12                # 고른 자리끼리 최소 x 간격
TEXT_BOTTOM = (110, 64)      # 이 x보다 왼쪽은 좌상단 지명 줄이 y=64까지 내려온다
BEZEL = (144, 31, 41)        # 서브스크린 베젤 (중심 x, y, 반경)


def deer_spot(x0, flip):
    """배너 안 x0(고라니 왼쪽 끝)에 세운 고라니. 반환 (화면 x, 화면 y, 검정, 흰 테두리, 점수) 또는 None."""
    d = make_deer()[:, ::-1] if flip else make_deer()
    H, W = d.shape
    r = ridge_y()
    feet = [c for c in range(W) if d[-1, c]]
    ground = [r[x0 + c] - 1 for c in feet]          # 발이 닿을 행 (산 바로 위)
    lo, hi = max(ground) - LEG_EXT, min(ground) + LEG_SINK
    if lo > hi:
        return None
    bottom = min(max(int(np.median(ground)), lo), hi)   # 원래 그림의 발 행이 놓일 배너 y
    top = bottom - (H - 1)
    m = np.zeros((H + LEG_EXT, W), bool)
    m[:H] = d
    for c, g in zip(feet, ground):
        m[H:H + max(0, g - bottom), c] = True          # 다리 늘이기
    # 몸통이 산에 파묻히면 안 됨 (다리 끝 LEG_SINK 행만 허용)
    for rr in range(H - 1 - LEG_SINK):
        for c in range(W):
            if m[rr, c] and top + rr >= r[x0 + c]:
                return None
    deer = np.pad(m, 1)
    halo = deer | np.roll(deer, 1, 0) | np.roll(deer, -1, 0) | np.roll(deer, 1, 1) | np.roll(deer, -1, 1)
    halo &= ~deer
    sx, sy = BX + x0 - 1, BY + top - 1                  # 비트맵 왼쪽 위 화면 좌표
    hh, ww = deer.shape
    for yy in range(hh):
        for xx in range(ww):
            bx, by = x0 - 1 + xx, top - 1 + yy
            if 0 <= bx < BW and by >= r[bx]:            # 산 속은 검정끼리 붙게: 테두리·묻힌 다리 지움
                halo[yy, xx] = False
                deer[yy, xx] = False
    # 화면 제약: 배너 좌우 테두리, 서브스크린 베젤, 좌상단 글자 줄
    ys, xs = np.nonzero(deer | halo)
    if sx + xs.min() < BX + 1 or sx + xs.max() > BX + BW - 2:
        return None
    if any((sx + x - BEZEL[0]) ** 2 + (sy + y - BEZEL[1]) ** 2 < BEZEL[2] ** 2 for y, x in zip(ys, xs)):
        return None
    if sx < TEXT_BOTTOM[0] and sy + ys.min() < TEXT_BOTTOM[1]:
        return None
    score = max(abs(g - bottom) for g in ground)
    return sx, sy, deer, halo, score


def deer_spots(flip):
    """서로 SPOT_GAP 이상 떨어진, 다리 보정이 적은 자리들 (x 순)."""
    W = make_deer().shape[1]
    cands = [(x0, deer_spot(x0, flip)) for x0 in range(0, BW - W + 1)]
    cands = [(x0, s) for x0, s in cands if s is not None]
    chosen = []
    for x0, s in sorted(cands, key=lambda t: (t[1][4], t[0])):
        if all(abs(x0 - c[0]) >= SPOT_GAP for c in chosen):
            chosen.append((x0, s))
    return [s for _, s in sorted(chosen, key=lambda t: t[0])]


def spots_preview():
    """자리마다 고라니 하나씩 세운 배너 목록 (윗줄들 = 왼쪽 보기, 아랫줄들 = 오른쪽 보기)."""
    scale, cols = 3, 4
    tiles = []
    for flip in (False, True):
        for sx, sy, deer, halo, _ in deer_spots(flip):
            scr = np.zeros((176, 176), np.uint8)
            bb = banner_with_border()
            scr[BY - 2:BY - 2 + bb.shape[0], BX - 2:BX - 2 + bb.shape[1]] = bb * 255
            h, w = deer.shape
            reg = scr[sy:sy + h, sx:sx + w]
            reg[halo] = 255
            reg[deer] = 0
            tiles.append(Image.fromarray(scr[56:104, :]).resize((176 * scale, 48 * scale), Image.NEAREST))
    tw, th = 176 * scale + 8, 48 * scale + 8
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("L", (cols * tw, rows * th), 90)
    for i, t in enumerate(tiles):
        sheet.paste(t, ((i % cols) * tw, (i // cols) * th))
    out = HERE / "previews" / "deer_spots.png"
    sheet.save(out)
    print(out, [len(deer_spots(f)) for f in (False, True)])


def banner_with_border():
    m = np.zeros((BH + 4, BW + 4), bool)
    m[2:-2, 2:-2] = make_banner()
    m[0, 1:-1] = m[-1, 1:-1] = True
    m[1:-1, 0] = m[1:-1, -1] = True
    return m


def export():
    res = PROJ / "resources"
    (res / "drawables" / "banner").mkdir(parents=True, exist_ok=True)

    def save_1bpp(mask, path):
        Image.fromarray((mask * 255).astype(np.uint8)).convert("1").save(path)

    save_1bpp(banner_with_border(), res / "drawables" / "banner" / "banner.png")
    xml = ["<drawables>",
           '    <bitmap id="Banner" filename="banner/banner.png">'
           '<palette disableTransparency="true"><color>000000</color><color>FFFFFF</color></palette></bitmap>']
    spots = {}
    for side, flip in (("L", False), ("R", True)):
        spots[side] = []
        for i, (sx, sy, deer, halo, _) in enumerate(deer_spots(flip)):
            px = np.zeros(deer.shape + (4,), np.uint8)
            px[deer] = (0, 0, 0, 255)
            px[halo] = (255, 255, 255, 255)
            Image.fromarray(px).save(res / "drawables" / "banner" / f"deer_{side.lower()}{i}.png")
            xml.append(f'    <bitmap id="Deer{side}{i}" filename="banner/deer_{side.lower()}{i}.png">'
                       "<palette><color>000000</color><color>FFFFFF</color></palette></bitmap>")
            spots[side].append((sx, sy, deer.shape[1]))
    xml.append("</drawables>")
    (res / "drawables" / "banner.xml").write_text("\n".join(xml) + "\n")
    for f in (res / "drawables" / "banner").glob("deer.png"):
        f.unlink()                                      # 예전 고정 고라니

    # 시각 숫자: 산그리메가 시각 줄 전체를 가로지르므로 같은 숫자라도 자리마다 모양이 다르다
    # → 자리(0~3) × 숫자(0~9) 비트맵 40장 + 콜론(효과 없이 꽉 찬 점)
    font = digit_font(DIGIT_FONT, DIGIT_H)
    glyph = {ch: render_text(font, ch) for ch in "0123456789:"}
    cell, colon_w = glyph["0"].shape[1], glyph[":"].shape[1]
    slot_x, x = [], 0
    for w in (cell, cell, colon_w, cell, cell):
        slot_x.append(x)
        x += w + TRACK
    total_w = x - TRACK
    digit_x = [slot_x[0], slot_x[1], slot_x[3], slot_x[4]]

    tdir = res / "drawables" / "time"
    tdir.mkdir(exist_ok=True)
    xml = ["<drawables>"]
    pal = '<palette disableTransparency="true"><color>000000</color><color>FFFFFF</color></palette>'
    for pos in range(4):
        for d in "0123456789":
            row = np.zeros((DIGIT_H, total_w), bool)
            for i, sx in enumerate(digit_x):
                row[:, sx:sx + cell] = glyph[d if i == pos else "8"]
            row = mountain_layers(row, DIGIT_MODE)
            save_1bpp(row[:, digit_x[pos]:digit_x[pos] + cell], tdir / f"t{pos}_{d}.png")
            xml.append(f'    <bitmap id="T{pos}_{d}" filename="time/t{pos}_{d}.png">{pal}</bitmap>')
    save_1bpp(glyph[":"], tdir / "colon.png")
    xml.append(f'    <bitmap id="TColon" filename="time/colon.png">{pal}</bitmap>')
    xml.append("</drawables>")
    (res / "drawables" / "time.xml").write_text("\n".join(xml) + "\n")
    ids = ",\n            ".join(
        "[" + ", ".join(f"Rez.Drawables.T{p}_{d}" for d in "0123456789") + "]" for p in range(4))

    # 화면 배치 상수
    def spot_rows(side):
        return ", ".join(f"[{x}, {y}, {w}]" for x, y, w in spots[side])

    def spot_ids(side):
        return ", ".join(f"Rez.Drawables.Deer{side}{i}" for i in range(len(spots[side])))
    (PROJ / "source" / "Banner.mc").write_text(f"""import Toybox.Lang;

// design/gen_banner.py export 로 생성된 파일. 직접 고치지 말고 스크립트를 다시 실행할 것.
module Banner {{
    const X = {BX - 2};           // 테두리 포함 배너 비트맵 위치
    const Y = {BY - 2};
    const SKY_X0 = {BX};          // 해가 지나가는 하늘 폭
    const SKY_X1 = {BX + BW - 1};
    const SUN_Y_LOW = {BY + SUN_Y[0]};    // 일출·일몰 때 해 높이
    const SUN_Y_HIGH = {BY + SUN_Y[1]};   // 정오 때 해 높이
    // 고라니가 설 수 있는 자리 [비트맵 왼쪽 위 x, y, 폭]. L = 왼쪽을 봄, R = 오른쪽을 봄
    const DEER_L = [{spot_rows("L")}];
    const DEER_R = [{spot_rows("R")}];
    const DIGIT_Y = {DIGIT_Y};    // 시각 숫자 윗변
    const DIGIT_W = {total_w};    // 시각 줄 전체 폭
    const DIGIT_XS = [{", ".join(map(str, digit_x))}];   // 숫자 자리 0~3의 x 오프셋
    const COLON_X = {slot_x[2]};

    function deerIds(right as Boolean) as Array<ResourceId> {{
        return right ? [{spot_ids("R")}] : [{spot_ids("L")}];
    }}

    // [자리][숫자] → 리소스 ID
    function digitIds() as Array<Array<ResourceId>> {{
        return [
            {ids}
        ];
    }}
}}
""")
    print(f"exported banner, deer spots L{len(spots['L'])}/R{len(spots['R'])}, 41 digit bitmaps ({DIGIT_MODE}), Banner.mc")


if __name__ == "__main__":
    if sys.argv[1:2] == ["preview"]:
        preview()
    elif sys.argv[1:2] == ["spots"]:
        spots_preview()
    elif sys.argv[1:2] == ["export"]:
        export()
    else:
        print(__doc__)
