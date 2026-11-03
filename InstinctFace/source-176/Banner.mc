import Toybox.Lang;

// design/gen_banner.py export 로 생성된 파일. 직접 고치지 말고 스크립트를 다시 실행할 것.
module Banner {
    const X = 6;           // 테두리 포함 배너 비트맵 위치
    const Y = 70;
    const SKY_X0 = 8;          // 해가 지나가는 하늘 폭
    const SKY_X1 = 167;
    const SUN_Y_LOW = 83;    // 일출·일몰 때 해 높이
    const SUN_Y_HIGH = 77;   // 정오 때 해 높이
    // 고라니가 설 수 있는 자리 [비트맵 왼쪽 위 x, y, 폭]. L = 왼쪽을 봄, R = 오른쪽을 봄
    const DEER_L = [[9, 70, 22], [21, 68, 22], [40, 70, 22], [52, 69, 22], [64, 71, 22], [76, 67, 22], [90, 64, 22], [108, 68, 22], [120, 69, 22], [145, 72, 22]];
    const DEER_R = [[9, 72, 22], [21, 69, 22], [33, 68, 22], [45, 70, 22], [66, 71, 22], [78, 68, 22], [90, 65, 22], [109, 68, 22], [145, 70, 22]];
    const DIGIT_Y = 98;    // 시각 숫자 윗변
    const DIGIT_W = 134;    // 시각 줄 전체 폭
    const DIGIT_XS = [0, 31, 74, 105];   // 숫자 자리 0~3의 x 오프셋
    const COLON_X = 62;

    function deerIds(right as Boolean) as Array<ResourceId> {
        return right ? [Rez.Drawables.DeerR0, Rez.Drawables.DeerR1, Rez.Drawables.DeerR2, Rez.Drawables.DeerR3, Rez.Drawables.DeerR4, Rez.Drawables.DeerR5, Rez.Drawables.DeerR6, Rez.Drawables.DeerR7, Rez.Drawables.DeerR8] : [Rez.Drawables.DeerL0, Rez.Drawables.DeerL1, Rez.Drawables.DeerL2, Rez.Drawables.DeerL3, Rez.Drawables.DeerL4, Rez.Drawables.DeerL5, Rez.Drawables.DeerL6, Rez.Drawables.DeerL7, Rez.Drawables.DeerL8, Rez.Drawables.DeerL9];
    }

    // [자리][숫자] → 리소스 ID
    function digitIds() as Array<Array<ResourceId>> {
        return [
            [Rez.Drawables.T0_0, Rez.Drawables.T0_1, Rez.Drawables.T0_2, Rez.Drawables.T0_3, Rez.Drawables.T0_4, Rez.Drawables.T0_5, Rez.Drawables.T0_6, Rez.Drawables.T0_7, Rez.Drawables.T0_8, Rez.Drawables.T0_9],
            [Rez.Drawables.T1_0, Rez.Drawables.T1_1, Rez.Drawables.T1_2, Rez.Drawables.T1_3, Rez.Drawables.T1_4, Rez.Drawables.T1_5, Rez.Drawables.T1_6, Rez.Drawables.T1_7, Rez.Drawables.T1_8, Rez.Drawables.T1_9],
            [Rez.Drawables.T2_0, Rez.Drawables.T2_1, Rez.Drawables.T2_2, Rez.Drawables.T2_3, Rez.Drawables.T2_4, Rez.Drawables.T2_5, Rez.Drawables.T2_6, Rez.Drawables.T2_7, Rez.Drawables.T2_8, Rez.Drawables.T2_9],
            [Rez.Drawables.T3_0, Rez.Drawables.T3_1, Rez.Drawables.T3_2, Rez.Drawables.T3_3, Rez.Drawables.T3_4, Rez.Drawables.T3_5, Rez.Drawables.T3_6, Rez.Drawables.T3_7, Rez.Drawables.T3_8, Rez.Drawables.T3_9]
        ];
    }
}
