#!/bin/zsh
# 사용법: ./build.sh <프로젝트> [device]   예) ./build.sh InstinctFace instinct3solar45mm
#        ./build.sh <프로젝트> [device] run      → 빌드 후 시뮬레이터에서 실행
#        ./build.sh <프로젝트> [device] release  → 시계 설치용 릴리스 빌드 (-r, 디버그 코드 제외)
#        ./build.sh <프로젝트> [device] install  → 릴리스 빌드 후 USB로 연결된 시계의 Garmin/Apps에 복사
#          (brew install libmtp 필요. OpenMTP 등 MTP 앱이 시계를 잡고 있으면 먼저 종료할 것)
set -e
ROOT="${0:A:h}"
PROJ="${1:?project dir required}"
DEVICE="${2:-instinct3solar45mm}"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
SDK="$(cat "$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg")"
mkdir -p "$ROOT/bin"
MODE="$3"; [[ "$MODE" == "install" ]] && MODE=release
OUT="$ROOT/bin/$PROJ-$DEVICE${MODE:+-$MODE}.prg"; [[ "$MODE" == "run" ]] && OUT="$ROOT/bin/$PROJ-$DEVICE.prg"
EXTRA=()
[[ "$MODE" == "release" ]] && EXTRA=(-r)
"$SDK/bin/monkeyc" -f "$ROOT/$PROJ/monkey.jungle" -d "$DEVICE" -o "$OUT" \
    -y "$ROOT/.devkey/developer_key.der" -w "${EXTRA[@]}"
echo "built: $OUT"
if [[ "$3" == "run" ]]; then
    open -g "$SDK/bin/ConnectIQ.app"
    sleep 3
    "$SDK/bin/monkeydo" "$OUT" "$DEVICE"
fi
if [[ "$3" == "install" ]]; then
    # 시계의 파일 이름은 프로젝트 이름 대문자 (예: INSTINCTFACE.PRG). 같은 이름이 있으면 지우고 새로 보낸다
    NAME="${PROJ:u}.PRG"
    APPS=$(mtp-folders 2>/dev/null | awk '$2 == "Apps" {print $1; exit}')
    [[ -z "$APPS" ]] && { echo "시계를 찾지 못했습니다. USB 연결과 연결 허용, MTP 앱 종료를 확인하세요."; exit 1; }
    OLD=$(mtp-files 2>/dev/null | awk -v n="$NAME" '/File ID:/ {id=$3} $1 == "Filename:" && $2 == n {print id}')
    for id in ${(f)OLD}; do mtp-delfile -n "$id" >/dev/null 2>&1; done
    TMP="$(mktemp -d)/$NAME"; cp "$OUT" "$TMP"
    mtp-sendfile "$TMP" "$APPS" 2>/dev/null | grep -E "New file ID" && echo "installed: Garmin/Apps/$NAME (케이블을 뽑으면 시계가 읽습니다)"
fi
