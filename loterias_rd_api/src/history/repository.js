import { HISTORY_SOURCE, SERIES } from './constants.js';

export function classifyResultChange(existingByProvider, existingByDate, incoming) {
  const existing = existingByProvider || existingByDate;
  if (!existing) return { kind: 'INSERT' };
  if (existing.checksum === incoming.checksum) return { kind: 'UNCHANGED', existing };
  return { kind: 'REVISION', existing };
}

export class HistoryRepository {
  constructor(db, series = SERIES.ganaMas, now = () => new Date().toISOString()) {
    if (!db) throw new Error('HISTORY_DB binding is required.');
    this.db = db;
    this.series = series;
    this.now = now;
  }

  async ensureMetadata(metadata) {
    const timestamp = this.now();
    await this.db.batch([
      this.db.prepare(`
        INSERT INTO operators (id, name, source, source_site_id, updated_at)
        VALUES (?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          name = excluded.name,
          source = excluded.source,
          source_site_id = excluded.source_site_id,
          updated_at = excluded.updated_at
      `).bind(this.series.operatorId, metadata.operatorName, HISTORY_SOURCE, metadata.sourceSiteId, timestamp),
      this.db.prepare(`
        INSERT INTO draws (
          id, operator_id, name, first_position_path, number_min, number_max,
          source_created_at, enabled, updated_at
        ) VALUES (?, ?, ?, 'score[0][0]', 0, 99, ?, 1, ?)
        ON CONFLICT(id) DO UPDATE SET
          operator_id = excluded.operator_id,
          name = excluded.name,
          source_created_at = excluded.source_created_at,
          enabled = 1,
          updated_at = excluded.updated_at
      `).bind(this.series.drawId, this.series.operatorId, metadata.drawName, metadata.sourceCreatedAt, timestamp),
    ]);
  }

  async getResultByProviderId(providerResultId) {
    return this.db.prepare(
      'SELECT * FROM first_prize_results WHERE provider_result_id = ? LIMIT 1',
    ).bind(providerResultId).first();
  }

  async getResultByDate(drawDate) {
    return this.db.prepare(
      'SELECT * FROM first_prize_results WHERE draw_id = ? AND draw_date = ? LIMIT 1',
    ).bind(this.series.drawId, drawDate).first();
  }

  async saveResult(incoming) {
    const [existingByProvider, existingByDate] = await Promise.all([
      this.getResultByProviderId(incoming.providerResultId),
      this.getResultByDate(incoming.drawDate),
    ]);
    if (
      existingByProvider && existingByDate &&
      existingByProvider.id !== existingByDate.id
    ) {
      throw new Error('Provider ID and draw date resolve to conflicting stored rows.');
    }

    const decision = classifyResultChange(existingByProvider, existingByDate, incoming);
    const timestamp = this.now();
    const rawPayload = JSON.stringify(incoming.rawPayload);

    if (decision.kind === 'INSERT') {
      await this.db.prepare(`
        INSERT INTO first_prize_results (
          provider_result_id, operator_id, draw_id, draw_date, first_number,
          source, checksum, raw_payload, provider_created_at,
          provider_updated_at, collected_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        incoming.providerResultId,
        incoming.operatorId,
        incoming.drawId,
        incoming.drawDate,
        incoming.firstNumber,
        incoming.source,
        incoming.checksum,
        rawPayload,
        incoming.providerCreatedAt,
        incoming.providerUpdatedAt,
        timestamp,
        timestamp,
      ).run();
      return { kind: 'INSERT' };
    }

    if (decision.kind === 'UNCHANGED') {
      await this.db.prepare(`
        UPDATE first_prize_results
        SET collected_at = ?, provider_updated_at = COALESCE(?, provider_updated_at)
        WHERE id = ?
      `).bind(timestamp, incoming.providerUpdatedAt, decision.existing.id).run();
      return { kind: 'UNCHANGED' };
    }

    await this.db.batch([
      this.db.prepare(`
        INSERT INTO result_revisions (
          result_id, provider_result_id, old_first_number, new_first_number,
          old_checksum, new_checksum, old_raw_payload, new_raw_payload, detected_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        decision.existing.id,
        incoming.providerResultId,
        decision.existing.first_number,
        incoming.firstNumber,
        decision.existing.checksum,
        incoming.checksum,
        decision.existing.raw_payload,
        rawPayload,
        timestamp,
      ),
      this.db.prepare(`
        UPDATE first_prize_results SET
          provider_result_id = ?, first_number = ?, checksum = ?, raw_payload = ?,
          provider_created_at = ?, provider_updated_at = ?, collected_at = ?, updated_at = ?
        WHERE id = ?
      `).bind(
        incoming.providerResultId,
        incoming.firstNumber,
        incoming.checksum,
        rawPayload,
        incoming.providerCreatedAt,
        incoming.providerUpdatedAt,
        timestamp,
        timestamp,
        decision.existing.id,
      ),
    ]);
    return { kind: 'REVISION' };
  }

  async recordCoverage({ date, status, attempts = 0, detail = null, error = null, verificationSource = null }) {
    const timestamp = this.now();
    await this.db.prepare(`
      INSERT INTO coverage (
        operator_id, draw_id, coverage_date, status, source,
        verification_source, detail, attempt_count, last_error, checked_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(draw_id, coverage_date) DO UPDATE SET
        status = excluded.status,
        verification_source = excluded.verification_source,
        detail = excluded.detail,
        attempt_count = coverage.attempt_count + excluded.attempt_count,
        last_error = excluded.last_error,
        checked_at = excluded.checked_at
    `).bind(
      this.series.operatorId,
      this.series.drawId,
      date,
      status,
      HISTORY_SOURCE,
      verificationSource,
      detail,
      attempts,
      error,
      timestamp,
    ).run();
  }

  async getBackfillState() {
    return this.db.prepare('SELECT * FROM backfill_state WHERE draw_id = ?').bind(this.series.drawId).first();
  }

  async initializeBackfill({ nextDate, lowerBoundDate }) {
    const timestamp = this.now();
    await this.db.prepare(`
      INSERT INTO backfill_state (
        draw_id, next_date, lower_bound_date, status, started_at, updated_at
      ) VALUES (?, ?, ?, 'READY', ?, ?)
      ON CONFLICT(draw_id) DO NOTHING
    `).bind(this.series.drawId, nextDate, lowerBoundDate, timestamp, timestamp).run();
    return this.getBackfillState();
  }

  async updateBackfillState({ nextDate, status, requestDelta = 0, resultDelta = 0, error = null }) {
    const timestamp = this.now();
    await this.db.prepare(`
      UPDATE backfill_state SET
        next_date = ?, status = ?,
        requests_completed = requests_completed + ?,
        results_stored = results_stored + ?,
        last_error = ?, updated_at = ?,
        completed_at = CASE WHEN ? = 'COMPLETE' THEN ? ELSE completed_at END
      WHERE draw_id = ?
    `).bind(
      nextDate,
      status,
      requestDelta,
      resultDelta,
      error,
      timestamp,
      status,
      timestamp,
      this.series.drawId,
    ).run();
  }
}
