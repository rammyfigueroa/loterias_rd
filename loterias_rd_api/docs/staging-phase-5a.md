# Historical staging runbook

This runbook is only for the isolated historical staging environment. It must
never target the public `api` Worker or any existing D1 database.

## Resources

- Worker: `sorteosdominicanos-history-staging`
- D1: `sorteosdominicanos-history-staging-db`
- Worker URL: the independent `workers.dev` URL assigned by Cloudflare
- Secret: `HISTORY_BACKFILL_TOKEN` (entered interactively and never committed)
- Routes: none
- Cron triggers: none

The committed staging config contains the zero UUID. Deployment and remote D1
commands must fail until the dedicated database is created and its returned ID
is inserted into `wrangler.staging.toml`.

## Authorization gate

Do not run any command in the remote section until the user explicitly approves
creation of the Worker and D1 database.

## Local preflight

```sh
npm test
npm run staging:dry-run
```

## Remote resource creation

Run from `loterias_rd_api` after explicit approval:

```sh
npx wrangler d1 create sorteosdominicanos-history-staging-db
```

Copy only the returned staging database ID into `wrangler.staging.toml`, then:

```sh
npx wrangler d1 migrations apply sorteosdominicanos-history-staging-db --remote --config wrangler.staging.toml
npx wrangler deploy --config wrangler.staging.toml
npx wrangler secret put HISTORY_BACKFILL_TOKEN --config wrangler.staging.toml
```

Enter the token only in Wrangler's interactive prompt. Do not put it in shell
history, source files, logs, or Git.

## Controlled backfill

Use batches of 10 dates. This stays comfortably below the Workers Free
subrequest and CPU limits and keeps each operation resumable. Send the token from a protected local variable;
never paste it into this document.

```sh
curl -X POST \
  -H "X-Backfill-Token: $HISTORY_BACKFILL_TOKEN" \
  "https://STAGING_WORKER_URL/internal/history/backfill?operatorId=6966a6d1ea7015c3b8a3d477&drawId=6966a6d1ea7015c3b8a3d482&maxRequests=10"

curl -X POST \
  -H "X-Backfill-Token: $HISTORY_BACKFILL_TOKEN" \
  "https://STAGING_WORKER_URL/internal/history/backfill?operatorId=6966a6d1ea7015c3b8a3d477&drawId=6966a6d1ea7015c3b8a3d47c&maxRequests=10"
```

Repeat one series at a time, inspect each response, and stop on any failure.
Do not activate a Cron Trigger during Phase 5A.

## Validation

After both backfills complete, query D1 by `draw_id` to verify counts, date
ranges, coverage states, uniqueness, raw payload identity, and backfill state.
Then exercise `/history`, `/history/coverage`, and all three first-prize
statistics endpoints with mandatory `operatorId` and `drawId` filters.

Compare remote and local data over the same end date before comparing rankings.
Do not require the remote totals to remain at 181 when newer verified results
exist.

## Rollback

If staging validation fails, stop requests and preserve D1 for diagnosis. Since
there are no production routes, production bindings, DNS records, or triggers,
the public Android API remains unaffected. Delete staging resources only after
capturing the required diagnostics and obtaining user confirmation.
