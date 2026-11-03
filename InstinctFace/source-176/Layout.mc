import Toybox.Lang;

// 화면 배치 상수: Instinct 3 Solar (176x176 반팔각형, 우상단 서브스크린 113,0,62x62)
// 한글 폰트 갈무리11 Bold 12px (줄 높이 14), 이모지 12px. 배너·시각 숫자 자리는 Banner.mc
module Layout {
    // 좌상단: 날짜(가운데 정렬 x, 윗변 y) + 정보 칸 3줄
    const DATE_X = 58;
    const DATE_Y = 12;
    const TOP_X = 58;
    const TOP_Y = 25;
    const TOP_DY = 13;
    const PLACE_MAX_W = 96;      // 좌상단 줄에서 서브스크린 테두리에 걸리지 않는 폭

    // 서브스크린 원. 기기가 서브스크린 영역을 주면 그 값을 쓰고, 아래는 없을 때 쓰는 값
    const SUB_CX = 144;
    const SUB_CY = 32;
    const SUB_R = 29;
    const SUB_TIME_DY = -9;      // 남은 시간 글자 세로 중심 (원 중심 기준)
    const SUB_LABEL_DY = 3;      // "일출"/"일몰" 윗변

    // 배너 안 해 반지름 (바깥 흰 원, 안쪽 검정 원), 고라니가 해에서 떨어져 설 최소 x 거리
    const SUN_R = 4;
    const SUN_R_IN = 2;
    const DEER_SUN_GAP = 14;

    // 배너 아래 정보 칸 두 줄: 윗변 y, 칸 간격, 줄 최대 폭 / 날씨 전망 줄 윗변
    const ROW1_Y = 136;
    const ROW1_GAP = 5;
    const ROW1_W = 155;
    const ROW2_Y = 148;
    const ROW2_GAP = 4;
    const ROW2_W = 138;
    const BARO_Y = 161;

    // 칸 앞머리: 아이콘 배율(4 = 1배), 아이콘 칸 폭, 아이콘 중심 (칸 왼쪽·글자 윗변 기준)
    const ICON_K = 4;
    const ICON_W = 15;
    const ICON_DX = 6;
    const ICON_DY = 6;
    const EMOJI_W = 14;          // 이모지 + 2px
    const EMOJI_DY = 1;
    const SOLAR_DX = 8;          // 배터리 글자 뒤 태양광 해 중심까지
    const SOLAR_W = 14;
    const BARO_TEXT_DX = 18;     // 날씨 전망 아이콘 왼쪽에서 글자까지
}
