export const HISTORY_SOURCE = 'https://api.loteriasdominicanas.com/dominicana';
export const OPERATOR_ID = '6966a6d1ea7015c3b8a3d477';
export const OPERATOR_NAME = 'Nacional';
export const DRAW_ID = '6966a6d1ea7015c3b8a3d482';
export const DRAW_NAME = 'Gana Más';
export const SOURCE_SITE_ID = '6966a6d1ea7015c3b8a3d446';
export const FIRST_POSITION_PATH = 'score[0][0]';
export const SANTO_DOMINGO_TIMEZONE = 'America/Santo_Domingo';

export const COVERAGE_STATUSES = new Set([
  'RESULT_FOUND',
  'NO_DRAW_SCHEDULED',
  'NO_RESULTS_RETURNED',
  'UNVERIFIED',
  'FETCH_FAILED',
  'PENDING',
]);

// These dates were reported as holidays, but no draw-specific official source
// was found. They remain unverified until evidence can be attached.
export const UNVERIFIED_DATES = new Map([
  ['2026-08-16', 'Reported holiday; Gana Mas draw status not officially verified.'],
  ['2026-09-24', 'Reported holiday; Gana Mas draw status not officially verified.'],
]);
