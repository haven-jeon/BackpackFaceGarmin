"""위치 → 지명 표 생성기. 원본: places/sigungu.csv, places/mountains.csv (출처는 places/README.md)

시계 메모리(워치 페이스 64KB)를 아끼려고 좌표와 이름을 따로 된 jsonData 리소스로 두고, 찾을 때만 불러온다.
이름은 한꺼번에 불러오면 12KB가 넘어 CHUNK개씩 나눠 두고 필요한 묶음만 불러온다.
좌표 하나는 숫자 하나: (lat*1000 - 30000) * 65536 + (lon*1000 - 120000)  (0.001° ≈ 100m)
앞의 m개가 산, 나머지가 시·군·구.

  python gen_places.py   → ../InstinctFace/resources/jsonData/, ../InstinctFace/source/PlaceChunks.mc
"""
import csv
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / "InstinctFace" / "resources" / "jsonData"
SRC = HERE.parent / "InstinctFace" / "source" / "PlaceChunks.mc"
CHUNK = 32


def rows(name):
    return list(csv.DictReader(open(HERE / "places" / name, encoding="utf-8")))


def labels():
    return [r["label"] for r in rows("mountains.csv") + rows("sigungu.csv")]


def main():
    mountains, sigungu = rows("mountains.csv"), rows("sigungu.csv")
    pts = []
    for r in mountains + sigungu:
        la, lo = round(float(r["lat"]) * 1000) - 30000, round(float(r["lon"]) * 1000) - 120000
        assert 0 <= la < 32768 and 0 <= lo < 65536, r
        pts.append(la * 65536 + lo)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "places_pts.json").write_text(json.dumps({"m": len(mountains), "p": pts}, separators=(",", ":")))
    for f in OUT.glob("places_names*.json"):
        f.unlink()
    names = labels()
    n = (len(names) + CHUNK - 1) // CHUNK
    xml = ['<resources>', '    <jsonData id="PlacePoints" filename="places_pts.json" />']
    for c in range(n):
        (OUT / f"places_names{c}.json").write_text(
            json.dumps(names[c * CHUNK:(c + 1) * CHUNK], ensure_ascii=False, separators=(",", ":")))
        xml.append(f'    <jsonData id="PlaceNames{c}" filename="places_names{c}.json" />')
    xml.append('</resources>')
    (OUT / "places.xml").write_text("\n".join(xml) + "\n")
    ids = ", ".join(f"Rez.JsonData.PlaceNames{c}" for c in range(n))
    SRC.write_text(
        "// design/gen_places.py 가 만든 파일. 직접 고치지 말 것\n"
        "import Toybox.Lang;\n\n"
        "module PlaceChunks {\n"
        f"    const SIZE = {CHUNK};\n\n"
        "    function names(i as Number) as ResourceId {\n"
        f"        return [{ids}][i];\n"
        "    }\n"
        "}\n")
    print(f"{len(mountains)} mountains + {len(sigungu)} districts → {OUT}")


if __name__ == "__main__":
    main()
