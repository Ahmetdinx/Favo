# Favo — checkpoint 2026-09-30, shared identity implemented

Latest user request: finish shared login so user signs in on Favo then selects
Books and tests existing Favo.Books. User also requested terminal launch commands
for frontend/backend. No commit/push requested or performed.

Implemented SAME-ORIGIN shared login: Favo /, real Books frontend /kitap/,
YARP /api proxy to existing Books API. This is not cross-origin OIDC SSO.
Favo real email/password form uses existing Books Identity; same Secure HttpOnly
refresh cookie, JWT memory only. No user DB duplication or secret copying.

Books root remains C:/Users/ahmet/source/repos/KitapKivo. Existing logo/Docker
uncommitted changes preserved. Targeted frontend edits: BASE_URL router basename,
shared sessionTransport and AuthContext, serialized login/Google requests,
ProtectedRoute query/hash preservation, Favo return link, explicit logout errors,
BASE_URL reader share links. Pre-edit backups in artifacts/books-backup-*.
No backend schema, JWT settings or UserSecretsId edits. No production DB writes.

Start-Favo.ps1 now builds Books /kitap bundle, starts Books API if absent,
Favo API 5120 + frontend 5175. Existing Books API preserved on shutdown.
Docker must already run. No separate Books 5173 frontend needed for shared login.
Standalone Books 5173 remains supported for independent development, but shared
session tests must stay on origin 5175. Build-Books.ps1 rebuilds mounted frontend.
Publish-Favo.ps1 packages both frontends; configure HTTPS origins in production.

Verified: .NET zero warnings/errors; both frontend builds/lints; 27 configuration,
redirect, CSRF checks; 20 HTTP tests against real isolated Books API; browser
login, wrong password, transition, profile, reload, return to Favo, concurrent
reloads, logout in both directions across tabs, query/hash return after login.
Browser test revealed self-received BroadcastChannel login briefly cleared own
session and broke protected return; fixed by per-document source ID and retested
successfully. Tests and limitations in docs/shared-auth-testing.md.

Test DB used separate Testcontainers PostgreSQL; stopped and removed. Existing
favo-kitap-postgres container remains healthy. Real application started afterward.
Google E2E requires Client ID; no Google sign-in claim. Existing JWT validity
window remains after logout; refresh chain and browser state are revoked.

Read README for exact launch/verification commands. Read docs/shared-identity.md
for trust boundaries and production settings. Keep both repositories' matching
sessionTransport.ts helpers in sync (Build-Books checks parity).

Design update (2026-09-30): Favo shell and account dialog now use a warm charcoal
night theme. Books portal card explicitly reuses Books' cream/coffee palette
(#f1e8dc, #3e2d24, #79563d) and paper grain; no green book identity. Film uses
burgundy/clapperboard, Series midnight blue/episode frames, Anime purple/pink
sunset/torii, Manga ink/ochre print panels. Increased card height and illustration
detail; 390px responsive layout has no horizontal overflow. Desktop cards,
mobile layout and dark login dialog visually checked; frontend build/lint pass.
Only Favo CSS and theme-color changed; shared identity logic untouched.
