import { randomUUID } from 'node:crypto'
import { expect, test, type Page } from '@playwright/test'

const id = randomUUID().replaceAll('-', '').slice(0, 16)
const account = { email: `e2e-${id}@example.test`, nickname: `e2e_${id}`, password: `E2e-${randomUUID()}!` }

test.beforeAll(async ({ request, baseURL }) => {
  const response = await request.post('/api/identity/register', { data: account, headers: { Origin: baseURL! } })
  expect(response.status()).toBe(201)
})

async function openDialog(page: Page) {
  await page.goto('/')
  await page.locator('button.account-link', { hasText: 'Giriş yap' }).click()
}

async function signIn(page: Page) {
  await openDialog(page)
  await page.getByLabel('E-posta').fill(account.email)
  await page.getByLabel('Parola').fill(account.password)
  await page.getByRole('dialog').getByRole('button', { name: 'Giriş yap' }).click()
  await expect(page.locator('button.account-link', { hasText: 'Hesabım' })).toBeVisible()
}

test('wrong password shows an error and keeps the user signed out', async ({ page }) => {
  await openDialog(page)
  await page.getByLabel('E-posta').fill(account.email)
  await page.getByLabel('Parola').fill('Definitely-Wrong-1')
  await page.getByRole('dialog').getByRole('button', { name: 'Giriş yap' }).click()
  await expect(page.getByRole('alert')).toContainText('E-posta veya parola hatalı')
})

test('anonymous visitors are sent from the profile to Books login', async ({ page }) => {
  await page.goto('/go/books?path=/profile')
  await expect(page).toHaveURL(/\/kitap\/login/)
})

test('portal sign-in carries into Books and survives reload', async ({ page }) => {
  await signIn(page)
  await page.goto('/go/books?path=/profile')
  await expect(page).toHaveURL(/\/kitap\/profile/)
  await expect(page.getByRole('button', { name: 'Çıkış Yap' })).toBeVisible()
  await page.reload()
  await expect(page.getByRole('button', { name: 'Çıkış Yap' })).toBeVisible()
})

test('portal sign-in carries into Film', async ({ page }) => {
  await signIn(page)
  const restored = page.waitForResponse(response =>
    response.url().endsWith('/api/identity/refresh') && response.ok())
  await page.goto('/go/movie')
  await restored
  await expect(page).toHaveURL(/\/film\//)
  await expect(page.getByRole('button', { name: 'Giriş yap' })).toHaveCount(0)
})

test('a catalog book can be added to the library', async ({ page }) => {
  await signIn(page)
  await page.goto('/go/books')
  const saved = page.waitForResponse(response =>
    response.url().endsWith('/api/reading/library') && response.request().method() === 'POST')
  await page.getByRole('button', { name: 'Okumak istiyorum' }).first().click()
  expect((await saved).status()).toBe(201)
})

test('signing out of the portal signs out other tabs', async ({ page, context }) => {
  await signIn(page)
  const books = await context.newPage()
  await books.goto('/go/books')
  await expect(books.getByRole('button', { name: 'Çıkış Yap' })).toBeVisible()

  await page.locator('button.account-link', { hasText: 'Hesabım' }).click()
  await page.getByRole('button', { name: 'Favo’dan çıkış yap' }).click()

  await expect(books.getByRole('button', { name: 'Çıkış Yap' })).toHaveCount(0)
  await expect(page.locator('button.account-link', { hasText: 'Giriş yap' })).toBeVisible()
})
