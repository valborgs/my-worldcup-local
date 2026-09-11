/// Reserved for disposable debug paging data; never assign to bundled samples.
const firstDebugWorldCupIdx = -1019;
const lastDebugWorldCupIdx = -1000;

bool isDebugWorldCupId(int idx) =>
    idx >= firstDebugWorldCupIdx && idx <= lastDebugWorldCupIdx;
