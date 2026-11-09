import { defineConfig } from '@playwright/test'

// Runs against a live Start-Favo.ps1 system. One worker keeps the suite under the login rate limit.
export default defineConfig({
  testDir: './tests',
  workers: 1,
  retries: 0,
  timeout: 30_000,
  reporter: 'list',
  use: {
    baseURL: 'http://localhost:5175',
    channel: 'msedge',
    trace: 'retain-on-failure',
  },
})
