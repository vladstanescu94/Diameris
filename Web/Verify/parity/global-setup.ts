/**
 * Fails the whole run with ONE readable message when the app is not being served,
 * instead of 40 identical ERR_CONNECTION_REFUSED stacks.
 */
import { request } from '@playwright/test';
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const BASE_URL = process.env.DIAMERIS_URL ?? 'http://localhost:8080';

export default async function globalSetup(): Promise<void> {
  // The golden-vector fixture checks are pure arithmetic and need no server.
  // `npm run parity:fixture` sets this so they stay runnable before the app exists.
  if (process.env.PARITY_OFFLINE === '1') return;

  const ctx = await request.newContext();
  try {
    const res = await ctx.get(`${BASE_URL}/`, { timeout: 5000 });
    if (!res.ok()) {
      throw new Error(`GET ${BASE_URL}/ returned ${res.status()} ${res.statusText()}`);
    }
  } catch (e) {
    throw new Error(
      [
        '',
        '──────────────────────────────────────────────────────────────',
        ` The Diameris web client is not being served at ${BASE_URL}.`,
        '',
        ` reason: ${(e as Error).message}`,
        '',
        ' Start it first:   ./Web/run.sh',
        ' Or point the harness elsewhere:  DIAMERIS_URL=http://localhost:5173 npm run parity',
        '',
        ' (Until Backend + Frontend land, this failure is EXPECTED —',
        '  the parity harness is written ahead of the implementation.)',
        '──────────────────────────────────────────────────────────────',
        '',
      ].join('\n'),
    );
  } finally {
    await ctx.dispose();
  }

  await apiPropagationGate();
}

/**
 * Run main's API-propagation gate before any suite.
 *
 * Rationale: 16 of 25 API-affecting rulings had landed in DECISIONS.md but not in code.
 * Several parity suites fail against that server for reasons that LOOK like UI bugs but are
 * missing API fields — the same class of confusion globalSetup already prevents for
 * "server not running". Surfacing the count up front stops anyone debugging the wrong layer.
 *
 * Non-fatal by default so Frontend can still get signal on the UI while the API catches up.
 * Set `PARITY_STRICT_API=1` to make a non-zero gate abort the run — that is the CI setting,
 * because per main "exit 0 is the definition of done for the API".
 */
async function apiPropagationGate(): Promise<void> {
  const script = fileURLToPath(new URL('../../Docs/api-propagation-check.py', import.meta.url));
  if (!existsSync(script)) return;

  const res = spawnSync('python3', [script], { encoding: 'utf8', timeout: 60_000 });
  const outstanding = res.status ?? -1;
  if (outstanding === 0) {
    console.log('[parity] API propagation gate: 0 outstanding ✅');
    return;
  }

  const banner = [
    '',
    '──────────────────────────────────────────────────────────────',
    ` API PROPAGATION GATE: ${outstanding} ruling(s) NOT implemented by the live server.`,
    '',
    ' Parity failures below may be MISSING API FIELDS, not UI bugs.',
    ' Check the gate output before debugging the client:',
    '   python3 Web/Docs/api-propagation-check.py',
    '',
    (res.stdout || res.stderr || '').trim(),
    '──────────────────────────────────────────────────────────────',
    '',
  ].join('\n');

  if (process.env.PARITY_STRICT_API === '1') {
    throw new Error(banner);
  }
  console.warn(banner);
}
