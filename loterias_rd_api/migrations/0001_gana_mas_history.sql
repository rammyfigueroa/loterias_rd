PRAGMA foreign_keys = ON;

CREATE TABLE operators (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  source TEXT NOT NULL,
  source_site_id TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE draws (
  id TEXT PRIMARY KEY,
  operator_id TEXT NOT NULL REFERENCES operators(id),
  name TEXT NOT NULL,
  first_position_path TEXT NOT NULL,
  number_min INTEGER NOT NULL,
  number_max INTEGER NOT NULL,
  source_created_at TEXT,
  enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0, 1)),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_draws_operator ON draws(operator_id);

CREATE TABLE first_prize_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider_result_id TEXT NOT NULL UNIQUE,
  operator_id TEXT NOT NULL REFERENCES operators(id),
  draw_id TEXT NOT NULL REFERENCES draws(id),
  draw_date TEXT NOT NULL,
  first_number TEXT NOT NULL CHECK (
    length(first_number) = 2 AND
    first_number GLOB '[0-9][0-9]'
  ),
  source TEXT NOT NULL,
  checksum TEXT NOT NULL,
  raw_payload TEXT NOT NULL,
  provider_created_at TEXT,
  provider_updated_at TEXT,
  collected_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  UNIQUE(draw_id, draw_date)
);

CREATE INDEX idx_first_prize_draw_date
  ON first_prize_results(draw_id, draw_date);
CREATE INDEX idx_first_prize_number_date
  ON first_prize_results(draw_id, first_number, draw_date);

CREATE TABLE coverage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operator_id TEXT NOT NULL REFERENCES operators(id),
  draw_id TEXT NOT NULL REFERENCES draws(id),
  coverage_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN (
    'RESULT_FOUND',
    'NO_DRAW_SCHEDULED',
    'NO_RESULTS_RETURNED',
    'UNVERIFIED',
    'FETCH_FAILED',
    'PENDING'
  )),
  source TEXT NOT NULL,
  verification_source TEXT,
  detail TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  checked_at TEXT NOT NULL,
  next_retry_at TEXT,
  UNIQUE(draw_id, coverage_date)
);

CREATE INDEX idx_coverage_draw_date ON coverage(draw_id, coverage_date);
CREATE INDEX idx_coverage_status ON coverage(draw_id, status, coverage_date);

CREATE TABLE result_revisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  result_id INTEGER NOT NULL REFERENCES first_prize_results(id),
  provider_result_id TEXT NOT NULL,
  old_first_number TEXT NOT NULL,
  new_first_number TEXT NOT NULL,
  old_checksum TEXT NOT NULL,
  new_checksum TEXT NOT NULL,
  old_raw_payload TEXT NOT NULL,
  new_raw_payload TEXT NOT NULL,
  detected_at TEXT NOT NULL
);

CREATE INDEX idx_revisions_result ON result_revisions(result_id, detected_at);

CREATE TABLE backfill_state (
  draw_id TEXT PRIMARY KEY REFERENCES draws(id),
  next_date TEXT NOT NULL,
  lower_bound_date TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('READY', 'RUNNING', 'COMPLETE', 'FAILED')),
  requests_completed INTEGER NOT NULL DEFAULT 0,
  results_stored INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  started_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT
);

INSERT INTO operators (id, name, source, source_site_id)
VALUES (
  '6966a6d1ea7015c3b8a3d477',
  'Nacional',
  'https://api.loteriasdominicanas.com/dominicana',
  '6966a6d1ea7015c3b8a3d446'
);

INSERT INTO draws (
  id,
  operator_id,
  name,
  first_position_path,
  number_min,
  number_max,
  source_created_at,
  enabled
) VALUES (
  '6966a6d1ea7015c3b8a3d482',
  '6966a6d1ea7015c3b8a3d477',
  'Gana Más',
  'score[0][0]',
  0,
  99,
  '2026-01-13T20:10:57.992Z',
  1
);
