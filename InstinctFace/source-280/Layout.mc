import Toybox.Graphics;
import Toybox.Lang;

// 화면 배치 상수: Fenix 7X (280x280 원형, 서브스크린 없음 → 우상단에 원을 직접 그린다)
// 한글 폰트 갈무리14 15px (줄 높이 18), 이모지 15px. 배너·시각 숫자 자리는 Banner.mc
// 둥근 화면이라 좌상단 글자가 화면 테두리와 서브스크린 원 사이에 들도록 176 배치를 옮겨 잡았다
module Layout {
    // 좌상단: 날짜(가운데 정렬 x, 윗변 y) + 정보 칸 3줄
    const DATE_X = 110;
    const DATE_Y = 22;
    const TOP_X = 100;
    const TOP_Y = 40;
    const TOP_DY = 18;
    const PLACE_MAX_W = 100;     // 왼쪽 화면 테두리와 서브스크린 원 사이 폭

    // 서브스크린 자리 원 (onPartialUpdate도 이 둘레만 다시 그린다)
    const SUB_CX = 196;
    const SUB_CY = 62;
    const SUB_R = 40;
    const SUB_FONT = Graphics.FONT_MEDIUM;
    const SUB_TIME_DY = -12;     // 남은 시간 글자 세로 중심 (원 중심 기준)
    const SUB_LABEL_DY = 4;      // "일출"/"일몰" 윗변
    const SUB_PEN = 1;           // 원 테두리 두께
    const RING_W = 4;            // 둘레 링(태양광 세기 또는 남은 낮/밤) 두께

    // 배너 안 해 반지름 (바깥 흰 원, 안쪽 검정 원), 고라니가 해에서 떨어져 설 최소 x 거리
    const SUN_R = 6;
    const SUN_R_IN = 3;
    const DEER_SUN_GAP = 21;

    // 배너 아래 정보 칸 두 줄: 윗변 y, 칸 간격, 줄 최대 폭 / 날씨 전망 줄 윗변
    const ROW1_Y = 201;
    const ROW1_GAP = 6;
    const ROW1_W = 226;
    const ROW2_Y = 220;
    const ROW2_GAP = 5;
    const ROW2_W = 198;
    const BARO_Y = 240;

    // 칸 앞머리: 아이콘 배율(5 = 1.25배, 글자 크기 12→15px에 맞춤), 아이콘 칸 폭, 아이콘 중심
    const ICON_K = 5;
    const ICON_W = 19;
    const ICON_DX = 8;
    const ICON_DY = 8;
    const EMOJI_W = 17;          // 이모지 + 2px
    const EMOJI_DY = 1;
    const SOLAR_DX = 10;         // 배터리 글자 뒤 태양광 해 중심까지
    const SOLAR_W = 17;
    const BARO_TEXT_DX = 22;     // 날씨 전망 아이콘 왼쪽에서 글자까지

    const AOD_DATE_Y = 0;        // 저전력 화면 없음 (MIP 화면, Banner.HAS_AOD = false)
}
