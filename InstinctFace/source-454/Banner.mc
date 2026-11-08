import Toybox.Lang;

// design/gen_banner.py export 로 생성된 파일. 직접 고치지 말고 스크립트를 다시 실행할 것.
module Banner {
    const X = 33;           // 테두리 포함 배너 비트맵 위치
    const Y = 170;
    const SKY_X0 = 35;          // 해가 지나가는 하늘 폭
    const SKY_X1 = 418;
    const SUN_Y_LOW = 198;    // 일출·일몰 때 해 높이
    const SUN_Y_HIGH = 184;   // 정오 때 해 높이
    // 고라니가 설 수 있는 자리 [비트맵 왼쪽 위 x, y, 폭]. L = 왼쪽을 봄, R = 오른쪽을 봄
    const DEER_L = [[64, 165, 50], [116, 169, 50], [172, 171, 50], [229, 156, 50], [268, 163, 50], [365, 172, 50]];
    const DEER_R = [[36, 177, 50], [73, 165, 50], [127, 168, 50], [180, 171, 50], [230, 158, 50], [312, 167, 50], [342, 165, 50]];
    const DIGIT_Y = 234;    // 시각 숫자 윗변
    const DIGIT_W = 323;    // 시각 줄 전체 폭
    const DIGIT_XS = [0, 75, 178, 253];   // 숫자 자리 0~3의 x 오프셋
    const COLON_X = 150;
    const HAS_AOD = true;     // 저전력 화면(AMOLED): 속 빈 숫자 + 능선 윤곽선
    const AOD_RIDGE_X = 35;
    const AOD_RIDGE_Y = 201;

    function deerIds(right as Boolean) as Array<ResourceId> {
        return right ? [Rez.Drawables.DeerR0, Rez.Drawables.DeerR1, Rez.Drawables.DeerR2, Rez.Drawables.DeerR3, Rez.Drawables.DeerR4, Rez.Drawables.DeerR5, Rez.Drawables.DeerR6] : [Rez.Drawables.DeerL0, Rez.Drawables.DeerL1, Rez.Drawables.DeerL2, Rez.Drawables.DeerL3, Rez.Drawables.DeerL4, Rez.Drawables.DeerL5];
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

    // 저전력 화면: 숫자 0~9 윤곽선, 콜론, 능선
    function aodDigitIds() as Array<ResourceId> {
        return [Rez.Drawables.AodD0, Rez.Drawables.AodD1, Rez.Drawables.AodD2, Rez.Drawables.AodD3, Rez.Drawables.AodD4, Rez.Drawables.AodD5, Rez.Drawables.AodD6, Rez.Drawables.AodD7, Rez.Drawables.AodD8, Rez.Drawables.AodD9];
    }

    function aodColonId() as ResourceId or Null {
        return Rez.Drawables.AodColon;
    }

    function aodRidgeId() as ResourceId or Null {
        return Rez.Drawables.AodRidge;
    }
}
