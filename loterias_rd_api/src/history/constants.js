export const HISTORY_SOURCE = 'https://api.loteriasdominicanas.com/dominicana';
export const OPERATOR_ID = '6966a6d1ea7015c3b8a3d477';
export const OPERATOR_NAME = 'Nacional';
export const SOURCE_SITE_ID = '6966a6d1ea7015c3b8a3d446';
export const FIRST_POSITION_PATH = 'score[0][0]';
export const SANTO_DOMINGO_TIMEZONE = 'America/Santo_Domingo';

export const NATIONAL_DRAW_ID = '6966a6d1ea7015c3b8a3d47c';
export const GANA_MAS_DRAW_ID = '6966a6d1ea7015c3b8a3d482';

export const SERIES = Object.freeze({
  national: Object.freeze({
    operatorId: OPERATOR_ID,
    operatorName: OPERATOR_NAME,
    drawId: NATIONAL_DRAW_ID,
    drawName: 'Lotería Nacional',
    firstPositionPath: FIRST_POSITION_PATH,
  }),
  ganaMas: Object.freeze({
    operatorId: OPERATOR_ID,
    operatorName: OPERATOR_NAME,
    drawId: GANA_MAS_DRAW_ID,
    drawName: 'Gana Más',
    firstPositionPath: FIRST_POSITION_PATH,
  }),
});

export const AUTHORIZED_SERIES = Object.freeze(Object.values(SERIES));
export const DRAW_ID = GANA_MAS_DRAW_ID;
export const DRAW_NAME = SERIES.ganaMas.drawName;

export function seriesByIds(operatorId, drawId) {
  return AUTHORIZED_SERIES.find(
    (series) => series.operatorId === operatorId && series.drawId === drawId,
  ) || null;
}

export const COVERAGE_STATUSES = new Set([
  'RESULT_FOUND', 'NO_DRAW_SCHEDULED', 'NO_RESULTS_RETURNED',
  'UNVERIFIED', 'FETCH_FAILED', 'PENDING',
]);

// Provider metadata reports these exceptional dates, but no draw-specific
// official evidence was found. They remain unverified independently per draw.
export const UNVERIFIED_DATES_BY_DRAW = new Map([
  [NATIONAL_DRAW_ID, new Map([
    ['2026-08-16', 'Reported provider exception; Lotería Nacional draw status not officially verified.'],
    ['2026-09-24', 'Reported provider exception; Lotería Nacional draw status not officially verified.'],
  ])],
  [GANA_MAS_DRAW_ID, new Map([
    ['2026-08-16', 'Reported holiday; Gana Más draw status not officially verified.'],
    ['2026-09-24', 'Reported holiday; Gana Más draw status not officially verified.'],
  ])],
]);

export const UNVERIFIED_DATES = UNVERIFIED_DATES_BY_DRAW.get(GANA_MAS_DRAW_ID);
