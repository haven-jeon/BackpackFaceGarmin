// design/gen_places.py 가 만든 파일. 직접 고치지 말 것
import Toybox.Lang;

module PlaceChunks {
    const SIZE = 32;

    function names(i as Number) as ResourceId {
        return [Rez.JsonData.PlaceNames0, Rez.JsonData.PlaceNames1, Rez.JsonData.PlaceNames2, Rez.JsonData.PlaceNames3, Rez.JsonData.PlaceNames4, Rez.JsonData.PlaceNames5, Rez.JsonData.PlaceNames6, Rez.JsonData.PlaceNames7, Rez.JsonData.PlaceNames8, Rez.JsonData.PlaceNames9, Rez.JsonData.PlaceNames10, Rez.JsonData.PlaceNames11][i];
    }
}
