"""워치 페이스용 흑백 이모지 비트맵 생성기 (Noto Emoji, SIL OFL).

12px에서 알아보기 쉬운 것만 쓴다 (비교: preview_emoji.py → previews/emoji_options.png).
화면별 크기: 176 = 12px (갈무리11 12px 글자 옆), 280 = 15px (갈무리14 15px 글자 옆).

  python gen_emoji.py   → ../InstinctFace/resources-<화면>/drawables/emoji/*.png, emoji.xml
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from preview_emoji import emoji_mask  # noqa: E402
PROJ = HERE.parent / "InstinctFace"

# 리소스 ID → 이모지
EMOJI = {
    "EmojiSteps": "👣",   # 걸음
    "EmojiBell": "🔔",    # 알림
    "EmojiDrop": "💧",    # 날씨 흐려짐 (비)
    "EmojiSnow": "❄",     # 날씨 흐려짐 (기온 0°C 이하면 눈)
}
SIZES = {"176": 12, "280": 15}


def export(target, size):
    OUT = PROJ / f"resources-{target}" / "drawables"
    (OUT / "emoji").mkdir(parents=True, exist_ok=True)
    xml = ["<drawables>"]
    for rid, ch in EMOJI.items():
        m = emoji_mask(ch, size)
        rgba = np.zeros(m.shape + (4,), np.uint8)
        rgba[m] = (255, 255, 255, 255)          # 흰 글리프, 나머지는 투명
        name = rid[len("Emoji"):].lower()
        Image.fromarray(rgba).save(OUT / "emoji" / f"{name}.png")
        xml.append(f'    <bitmap id="{rid}" filename="emoji/{name}.png">'
                   '<palette><color>FFFFFF</color></palette></bitmap>')
    xml.append("</drawables>")
    (OUT / "emoji.xml").write_text("\n".join(xml) + "\n")
    print(f"[{target}] {len(EMOJI)} emoji {size}px → {OUT / 'emoji'}")


def main():
    for target, size in SIZES.items():
        export(target, size)


if __name__ == "__main__":
    main()
