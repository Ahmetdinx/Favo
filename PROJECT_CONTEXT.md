# Favo — checkpoint 2026-10-13, Movie community verified

Resumed interrupted work: applied pending 15-second discovery budget to the actual
Movie API, reran 29 community integration checks + 21 catalog checks (all pass),
Movie frontend build and lint pass. Test PostgreSQL removed by fixture disposal.
Previous browser verification covered login, avatar save/reload, nickname search,
follow/unfollow, seven-score save and profile rating, desktop/mobile rendering.
No live TMDB credentials supplied; provider tests use explicit fake fixtures.

Movie now has SQLite-owned avatars, preferences, watchlist/watching/watched,
seven-criterion ratings and feedback. Same Books weighting (pace10%, others15%).
Recommendation parity: genre4, liked genre2/director3, interest1, prior5votes at5,
min3 votes for criteria, strictly >9 for strong shelves; plus bounded follower bonus.
Movie authenticates bearer against configured Identity:ApiOrigin (Books), no copied secret.
Books added /api/readers/me/network-members and /api/readers/{nickname}/identity.
Movie uses shared follow graph and live public visibility; film avatar independent.
Movie frontend Community.tsx and community.css: avatar navigation, picker6, people
search, public profiles/follow/unfollow, profile collections, preferences, ratings,
personal recommendations + two social columns. Start script passes Identity origin.
Restart Books and Movie APIs for these changes. Existing running Debug apps were
left untouched; Release builds and disposable test APIs used for verification.
Integration tests: tests/Favo.Movie.CommunityChecks (explicit BooksRoot property).
29 passed using real isolated Books/Postgres + Movie/SQLite + fake TMDB. Browser
test portal5177 connects Books5118 and Movie5131; not production data.

## Previous initial slice

Favo.Movie created at C:/Users/ahmet/source/repos/Favo.Movie, solution Favo.Movie.slnx.
Independent .NET10 API5130 with TMDB catalog/search/details and React cinema UI.
Portal mounts built Movie UI at /film/ and proxies /api/movies before Books /api.
Film card /go/movie is active. Start/Publish scripts now include Movie.
Movie reuses exact Favo sessionTransport and existing Books identity; no new users DB.
TMDB ReadAccessToken is not configured. Live provider and signed-in Movie browser
flow remain unverified; fake-provider checks passed (21), Favo checks passed (27),
frontend builds/lints passed. Browser portal-to-film and empty state verified.
Movie watchlists, ratings, recommendations and social features are future work.
Existing Start-Favo.cmd and BOM edits preserved. No commit/push in this turn.

## Previous shared identity checkpoint

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

Movie UX alignment (2026-10-14): Movie header now follows Books with a left-side
nickname combobox (debounced results, avatars, Arrow/Enter/Escape), replacing the
people navigation tab. Movie detail exposes collection state and a separate
seven-criterion rating panel, contextual save labels and a profile shortcut.
Source: C:\Users\ahmet\source\repos\Favo.Movie\src\frontend\src.
Shared conventions documented in UX_CONVENTIONS.md; Series is not implemented.
Validation: frontend build/lint pass; 29 disposable community integration checks
pass. Browser verified search keyboard navigation, save to profile, seven scores,
and saved 8.0 rating in Puanlarim. Mobile search has no page horizontal overflow.
UI proof: artifacts/movie-ux/film-review.jpg (fake fixture data only).
