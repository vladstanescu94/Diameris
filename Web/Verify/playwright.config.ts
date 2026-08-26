import { defineConfig, devices } from '@playwright/test';

const BASE_URL = process.env.DIAMERIS_URL ?? 'http://localhost:8080';
// R17 — pin the server clock so the Dashboard month title cannot flake at month boundaries.
const FIXED_NOW = process.env.PARITY_NOW ?? '2026-08-06T12:00:00.000Z';

export default defineConfig({
  testDir: './parity',
  outputDir: './output/.playwright',
  globalSetup: './parity/global-setup.ts',
  globalTeardown: './parity/report.ts',
  // Parity is a serial, stateful check against ONE local JSON store
  // (Web/Docs/DECISIONS.md D2) — every test resets it via POST /api/reset,
  // so tests must not run concurrently against the same server.
  workers: 1,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: 0,
  timeout: 60_000,
  // PARITY_EXPECT_TIMEOUT lets a triage run fail fast instead of waiting 7s per missing element.
  expect: { timeout: Number(process.env.PARITY_EXPECT_TIMEOUT ?? 7_000) },
  reporter: [
    ['list'],
    ['html', { outputFolder: './output/html-report', open: 'never' }],
    ['json', { outputFile: './output/results.json' }],
  ],
  use: {
    baseURL: BASE_URL,
    extraHTTPHeaders: { 'X-Diameris-Now': FIXED_NOW },
    locale: 'en-US',
    timezoneId: 'Europe/Bucharest',
    viewport: { width: 1280, height: 900 },
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'off',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], viewport: { width: 1280, height: 900 } },
    },
  ],
});
