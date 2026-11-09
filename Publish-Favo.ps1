param([string]$BooksRoot, [string]$MovieRoot)
$ErrorActionPreference = 'Stop'
$resolver = Join-Path $PSScriptRoot 'scripts/Resolve-ProjectRoot.ps1'
$BooksRoot = & $resolver -Explicit $BooksRoot -Solution 'Favo.Books.slnx' -Names 'Favo.Books', 'Favo Kitap', 'KitapKivo'
$MovieRoot = & $resolver -Explicit $MovieRoot -Solution 'Favo.Movie.slnx' -Names 'Favo.Movie'
& (Join-Path $PSScriptRoot 'scripts/Build-Books.ps1') -BooksRoot $BooksRoot
& (Join-Path $PSScriptRoot 'scripts/Build-Movie.ps1') -MovieRoot $MovieRoot
dotnet publish (Join-Path $PSScriptRoot 'src/backend/Favo.Api') -c Release -o (Join-Path $PSScriptRoot 'artifacts/publish')
if ($LASTEXITCODE -ne 0) { throw 'Favo publish başarısız.' }
$source = Join-Path $PSScriptRoot 'artifacts/books'
$destination = Join-Path $PSScriptRoot 'artifacts/publish/wwwroot/kitap'
New-Item -ItemType Directory -Force $destination | Out-Null
Get-ChildItem -LiteralPath $source | Copy-Item -Destination $destination -Recurse -Force
dotnet publish (Join-Path $MovieRoot 'src/backend/Favo.Movie.Api') -c Release -o (Join-Path $PSScriptRoot 'artifacts/publish-movie-api')
if ($LASTEXITCODE -ne 0) { throw 'Movie API publish failed.' }
$movieDestination = Join-Path $PSScriptRoot 'artifacts/publish/wwwroot/film'
New-Item -ItemType Directory -Force $movieDestination | Out-Null
Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'artifacts/movie') | Copy-Item -Destination $movieDestination -Recurse -Force
Write-Host 'Movie API: artifacts/publish-movie-api. Set Movie__ApiOrigin on Favo; Identity__ApiOrigin (Books HTTPS), Tmdb__ReadAccessToken and persistent Movie__DatabasePath on Movie API.'
Write-Host 'Yayın paketi: artifacts/publish. Portal__Origin ve Books__ApiOrigin HTTPS adreslerini yapılandırın.'
