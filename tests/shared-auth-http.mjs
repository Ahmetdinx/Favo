import assert from 'node:assert/strict'

// Run only while Start-Favo is connected to the disposable Favo.E2eHost on 5118.
const base = 'http://localhost:5175'
const origin = { Origin: base, 'Content-Type': 'application/json' }
const credentials = { email: 'shared-auth@example.test', password: 'Favo-Test-Only-2026!' }
let checks = 0
function check(condition, name) { assert.ok(condition, name); checks++; console.log('PASS', name) }
async function post(path, body, cookie, headers = origin) {
  return fetch(base + path, { method: 'POST', headers: { ...headers, ...(cookie ? { Cookie: cookie } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body), redirect: 'manual' })
}
function cookieOf(response) {
  const value = response.headers.get('set-cookie')
  assert.ok(value, 'Expected refresh cookie')
  return value.split(';')[0]
}
check((await post('/api/identity/login', credentials, null, { ...origin, Origin: 'https://evil.test' })).status === 403, 'Cross-origin login rejected')
check((await post('/api/identity/logout', undefined, null, {})).status === 403, 'Missing Origin rejected')
check((await post('/api/identity/refresh', undefined, null, { ...origin, 'Sec-Fetch-Site':'cross-site' })).status === 403, 'Cross-site refresh rejected')
check((await post('/api/identity/login', { ...credentials, password: 'wrong' })).status === 401, 'Wrong password rejected')
const login = await post('/api/identity/login', credentials)
check(login.status === 200, 'Favo login reaches existing Books identity')
const session = await login.json()
const firstCookie = cookieOf(login)
const attributes = login.headers.get('set-cookie')
check(/httponly/i.test(attributes) && /secure/i.test(attributes) && /samesite=lax/i.test(attributes) && /path=\/api\/identity/i.test(attributes), 'Secure HttpOnly identity cookie preserved')
check(login.headers.get('cache-control')?.includes('no-store'), 'Identity response cannot be cached')
const me = await fetch(base + '/api/identity/me', { headers: { Authorization: 'Bearer ' + session.accessToken } })
check(me.status === 200 && (await me.json()).userId === session.userId, 'Same existing user identity authorized')
for (const path of ['/kitap/profile','/kitap/catalog','/kitap/catalog/books/11111111-1111-1111-1111-111111111111']) {
  const response = await fetch(base + path)
  check(response.status === 200 && (await response.text()).includes('/kitap/assets/'), 'Real Books SPA resolves ' + path)
}
const navigation = await fetch(base + '/go/books', { redirect: 'manual' })
check(navigation.status === 302 && navigation.headers.get('location') === '/kitap/catalog', 'Transition stays on Favo origin without tokens')
check((await fetch(base + '/go/books?path=https://evil.test', { redirect:'manual' })).status === 400, 'Open redirect rejected')
const refresh = await post('/api/identity/refresh', undefined, firstCookie)
check(refresh.status === 200 && (await refresh.json()).userId === session.userId, 'Refresh preserves identity across page reload')
const rotatedCookie = cookieOf(refresh)
check(rotatedCookie !== firstCookie, 'Refresh token rotated')
check((await post('/api/identity/refresh', undefined, firstCookie)).status === 401, 'Replayed old refresh rejected')
check((await post('/api/identity/refresh', undefined, rotatedCookie)).status === 401, 'Compromised refresh family revoked')
const relogin = await post('/api/identity/login', credentials)
check(relogin.status === 200, 'Login recovers after invalid session')
const logoutCookie = cookieOf(relogin)
const logout = await post('/api/identity/logout', undefined, logoutCookie)
check(logout.status === 204, 'Logout succeeds at identity authority')
check((await post('/api/identity/refresh', undefined, logoutCookie)).status === 401, 'Logged out session cannot be restored')
console.log(`PASS: ${checks} shared identity HTTP checks. No tokens or credentials persisted.`)
