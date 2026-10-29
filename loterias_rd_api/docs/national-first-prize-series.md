# Loteria Nacional first-prize series

Identification verified against the provider's structured `/sites/env` payload
on 2026-10-28.

| Field | Value |
| --- | --- |
| Operator | Nacional |
| Operator ID | `6966a6d1ea7015c3b8a3d477` |
| Draw | Loteria Nacional |
| Draw ID | `6966a6d1ea7015c3b8a3d47c` |
| First position | `score[0][0]` (`Bola 1`) |
| Positions | 3 |
| Provider metadata created at | `2026-01-13T20:10:57.975Z` |

This is a separate series from Gana Mas
(`6966a6d1ea7015c3b8a3d482`) under the same operator. A provider session was
verified for 2026-04-29 (`09`) and 2026-10-28 (`87`); no session was returned
for 2026-01-13.

The local D1 database does not contain this draw. Its first available result,
record count, continuity, missing dates and complete coverage are therefore not
established. Before enabling the Flutter option, a separately authorized phase
must:

1. Insert the structured draw metadata in `draws` with `enabled = 0`.
2. Backfill only draw `6966a6d1ea7015c3b8a3d47c` into the existing
   draw-scoped `first_prize_results`, `coverage` and `backfill_state` tables.
3. Audit skips, delays and dates without results conservatively.
4. Enable the draw and update backend authorization only after coverage and
   statistical output are validated.

No backfill or production change was performed during Phase 4.1.
