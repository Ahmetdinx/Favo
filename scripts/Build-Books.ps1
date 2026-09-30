param([Parameter(Mandatory)][string]$BooksRoot, [string]$OutputPath)
$ErrorActionPreference = 'Stop'
$portalRoot = Split-Path $PSScriptRoot -Parent
if (!$OutputPath) { $OutputPath = Join-Path $portalRoot 'artifacts/books' }
$resolvedOutput = [IO.Path]::GetFullPath($OutputPath)
$allowedRoot = [IO.Path]::GetFullPath((Join-Path $portalRoot 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (!$resolvedOutput.StartsWith($allowedRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Books build output must stay under Favo/artifacts.' }
$frontend = Join-Path $BooksRoot 'src/frontend'
$transport = Join-Path $frontend 'src/auth/sessionTransport.ts'
if (!(Test-Path $transport)) { throw 'Kitap ortak oturum entegrasyonu eksik.' }
if ([IO.File]::ReadAllText($transport).Trim() -ne [IO.File]::ReadAllText((Join-Path $portalRoot 'src/frontend/src/auth/sessionTransport.ts')).Trim()) { throw 'Ortak oturum yardımcıları farklı; önce iki projeyi eşitleyin.' }
Push-Location $frontend
try {
    if (!(Test-Path 'node_modules')) { npm ci; if ($LASTEXITCODE -ne 0) { throw 'Kitap npm ci başarısız.' } }
    npm run build -- --base=/kitap/ --outDir $resolvedOutput --emptyOutDir
    if ($LASTEXITCODE -ne 0) { throw 'Kitap derlemesi başarısız.' }
} finally { Pop-Location }
