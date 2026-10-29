INSERT INTO draws (
  id, operator_id, name, first_position_path, number_min, number_max,
  source_created_at, enabled
) VALUES (
  '6966a6d1ea7015c3b8a3d47c',
  '6966a6d1ea7015c3b8a3d477',
  'Lotería Nacional',
  'score[0][0]',
  0,
  99,
  '2026-01-13T20:10:57.975Z',
  1
)
ON CONFLICT(id) DO UPDATE SET
  name = excluded.name,
  first_position_path = excluded.first_position_path,
  source_created_at = excluded.source_created_at,
  enabled = 1,
  updated_at = CURRENT_TIMESTAMP;
