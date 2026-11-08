param([Parameter(Mandatory)][string]$MovieRoot)
$ErrorActionPreference = 'Stop'
$portalRoot = Split-Path $PSScriptRoot -Parent
$frontend = Join-Path $MovieRoot 'src/frontend'
$transport = Join-Path $frontend 'src/auth/sessionTransport.ts'
if (!(Test-Path $transport)) { throw 'Movie shared session helper is missing.' }
if ([IO.File]::ReadAllText($transport).Trim() -ne [IO.File]::ReadAllText((Join-Path $portalRoot 'src/frontend/src/auth/sessionTransport.ts')).Trim()) { throw 'Movie/Favo shared session helpers differ.' }
Push-Location $frontend
try {
    if (!(Test-Path 'node_modules')) { npm ci; if ($LASTEXITCODE -ne 0) { throw 'Movie npm ci failed.' } }
    npm run build -- --base=/film/ --outDir (Join-Path $portalRoot 'artifacts/movie') --emptyOutDir
    if ($LASTEXITCODE -ne 0) { throw 'Movie build failed.' }
} finally { Pop-Location }
