"""워치 페이스용 12px 흑백 이모지 비트맵 생성기 (Noto Emoji, SIL OFL).

12px에서 알아보기 쉬운 것만 쓴다 (비교: preview_emoji.py → previews/emoji_options.png).

  python gen_emoji.py   → ../InstinctFace/resources/drawables/emoji/*.png, emoji.xml
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from preview_emoji import emoji_mask  # noqa: E402
OUT = HERE.parent / "InstinctFace" / "resources" / "drawables"

# 리소스 ID → 이모지
EMOJI = {
    "EmojiSteps": "👣",   # 걸음
    "EmojiBell": "🔔",    # 알림
    "EmojiDrop": "💧",    # 날씨 흐려짐 (비)
    "EmojiSnow": "❄",     # 날씨 흐려짐 (기온 0°C 이하면 눈)
}
SIZE = 12


def main():
    (OUT / "emoji").mkdir(parents=True, exist_ok=True)
    xml = ["<drawables>"]
    for rid, ch in EMOJI.items():
        m = emoji_mask(ch, SIZE)
        rgba = np.zeros(m.shape + (4,), np.uint8)
        rgba[m] = (255, 255, 255, 255)          # 흰 글리프, 나머지는 투명
        name = rid[len("Emoji"):].lower()
        Image.fromarray(rgba).save(OUT / "emoji" / f"{name}.png")
        xml.append(f'    <bitmap id="{rid}" filename="emoji/{name}.png">'
                   '<palette><color>FFFFFF</color></palette></bitmap>')
    xml.append("</drawables>")
    (OUT / "emoji.xml").write_text("\n".join(xml) + "\n")
    print(f"{len(EMOJI)} emoji → {OUT / 'emoji'}")


if __name__ == "__main__":
    main()
