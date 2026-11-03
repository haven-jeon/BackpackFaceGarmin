"""흑백 이모지(Noto Emoji, SIL OFL)를 1bpp 12px·16px로 렌더링해 비교하는 시안.

  python preview_emoji.py   → previews/emoji_options.png
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
EMOJI_FONT = HERE / "fonts" / "NotoEmoji.ttf"
KOR_FONT = HERE / "fonts" / "Galmuri11-Bold.ttf"
SS = 4

EMOJIS = [("⛺", "텐트"), ("🔥", "불"), ("🌙", "달"), ("❄", "눈"), ("💧", "물"), ("☀", "해"),
          ("☁", "구름"), ("⚡", "번개"), ("🌧", "비"), ("❤", "심박"), ("🌡", "기온"), ("🔋", "배터리"),
          ("⛰", "산"), ("🥾", "등산화"), ("👣", "발자국"), ("🦌", "사슴"), ("🔔", "알림"), ("🧭", "나침반")]

# 지금 칸에 쓰는 문구에 이모지를 붙여 본 모습
CONTEXT = [("⛰", "1,371m"), ("🥾", "+620m"), ("🌡", "12~17°"), ("🔋", "5일"), ("❤", "72"), ("👣", "8,432"),
           ("🔔", "3"), ("⛺", "6:51-17:40")]


def emoji_mask(ch, px, weight=700):
    """px 크기 1bpp 마스크 (True = 흰 픽셀)."""
    f = ImageFont.truetype(str(EMOJI_FONT), px * SS)
    f.set_variation_by_axes([weight])
    im = Image.new("L", (px * SS * 2, px * SS * 2), 0)
    ImageDraw.Draw(im).text((px * SS // 2, px * SS // 2), ch, fill=255, font=f)
    bb = im.getbbox()
    if bb is None:
        return np.zeros((px, px), bool)
    im = im.crop(bb)
    scale = px * SS / max(im.size)
    im = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.LANCZOS)
    canvas = Image.new("L", (px * SS, px * SS), 0)
    canvas.paste(im, ((px * SS - im.width) // 2, (px * SS - im.height) // 2))
    return np.array(canvas.resize((px, px), Image.BOX)) > 100


def to_img(mask, scale):
    return Image.fromarray((mask * 255).astype(np.uint8)).resize(
        (mask.shape[1] * scale, mask.shape[0] * scale), Image.NEAREST)


def main():
    scale = 4
    label_font = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", 18)
    kor = ImageFont.truetype(str(KOR_FONT), 12)

    col_w, pad = 16 * scale + 28, 14
    W = pad + len(EMOJIS) * col_w
    ctx_h = 3 * 18 * 3 + 40
    sheet = Image.new("RGB", (W, 36 + 12 * scale + 16 * scale + 60 + ctx_h), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 8), "12px", fill=(200, 200, 200), font=label_font)
    for i, (ch, name) in enumerate(EMOJIS):
        x = pad + i * col_w
        d.text((x, 8 + 22), name, fill=(240, 240, 240), font=label_font)
        sheet.paste(to_img(emoji_mask(ch, 12), scale).convert("RGB"), (x, 58))
        sheet.paste(to_img(emoji_mask(ch, 16), scale).convert("RGB"), (x, 58 + 12 * scale + 12))
    y_ctx = 58 + 12 * scale + 16 * scale + 30
    d.text((pad, y_ctx - 4), "칸에 넣은 모습 (12px 이모지 + 갈무리 12px, 3배 확대)", fill=(200, 200, 200), font=label_font)

    # 실제 칸처럼 검정 바탕에 1:1로 그린 뒤 3배 확대
    strip = np.zeros((18 * 2, 176 * 2), bool)
    for i, (ch, text) in enumerate(CONTEXT):
        cx, cy = (i % 4) * 88, (i // 4) * 18
        strip[cy + 2:cy + 14, cx + 2:cx + 14] = emoji_mask(ch, 12)
        t = Image.new("L", (80, 14), 0)
        ImageDraw.Draw(t).text((0, 0), text, fill=255, font=kor)
        tm = np.array(t) > 127
        strip[cy + 2:cy + 16, cx + 17:cx + 17 + 70] |= tm[:, :70]
    sheet.paste(to_img(strip, 3).convert("RGB"), (pad, y_ctx + 24))

    out = HERE / "previews" / "emoji_options.png"
    sheet.save(out)
    print(out)


if __name__ == "__main__":
    main()
