import Toybox.Graphics;
import Toybox.Lang;

// 화면 배치 상수: Forerunner 970 (454x454 원형 AMOLED, 서브스크린 없음 → 우상단에 원을 직접 그린다)
// 한글 폰트 갈무리11 Bold 12px을 2배로 키운 24px (줄 높이 28), 이모지 24px. 배너·시각 숫자 자리는 Banner.mc
// 280(Fenix 7X) 배치를 화면 크기 비율(약 1.62배)로 옮겼다
module Layout {
    // 좌상단: 날짜(가운데 정렬 x, 윗변 y) + 정보 칸 3줄
    const DATE_X = 178;
    const DATE_Y = 36;
    const TOP_X = 162;
    const TOP_Y = 65;
    const TOP_DY = 29;
    const PLACE_MAX_W = 162;     // 왼쪽 화면 테두리와 서브스크린 원 사이 폭

    // 서브스크린 자리 원
    const SUB_CX = 318;
    const SUB_CY = 100;
    const SUB_R = 65;
    const SUB_FONT = Graphics.FONT_TINY;     // 높이 47px, "17:20" 폭 98px (링 안쪽 지름 약 114px)
    const SUB_TIME_DY = -19;     // 남은 시간 글자 세로 중심 (원 중심 기준)
    const SUB_LABEL_DY = 6;      // "일출"/"일몰" 윗변
    const SUB_PEN = 2;           // 원 테두리 두께
    const RING_W = 7;            // 둘레 링(태양광 세기 또는 남은 낮/밤) 두께

    // 배너 안 해 반지름 (바깥 흰 원, 안쪽 검정 원), 고라니가 해에서 떨어져 설 최소 x 거리
    const SUN_R = 10;
    const SUN_R_IN = 5;
    const DEER_SUN_GAP = 34;

    // 배너 아래 정보 칸 두 줄: 윗변 y, 칸 간격, 줄 최대 폭 / 날씨 전망 줄 윗변
    const ROW1_Y = 323;
    const ROW1_GAP = 10;
    const ROW1_W = 366;
    const ROW2_Y = 354;
    const ROW2_GAP = 8;
    const ROW2_W = 320;
    const BARO_Y = 386;

    // 칸 앞머리: 아이콘 배율(8 = 2배), 아이콘 칸 폭, 아이콘 중심 (칸 왼쪽·글자 윗변 기준)
    const ICON_K = 8;
    const ICON_W = 30;
    const ICON_DX = 12;
    const ICON_DY = 12;
    const EMOJI_W = 28;          // 이모지 + 4px
    const EMOJI_DY = 2;
    const SOLAR_DX = 16;         // 배터리 글자 뒤 태양광 해 중심까지
    const SOLAR_W = 28;
    const BARO_TEXT_DX = 36;     // 날씨 전망 아이콘 왼쪽에서 글자까지

    // 저전력 화면(AOD): 날짜 윗변. 숫자·능선 자리는 Banner.mc
    const AOD_DATE_Y = 120;
}
