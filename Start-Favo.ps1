param(
    [switch]$NoBrowser,
    [string]$BooksRoot,
    [string]$BooksApiOrigin = 'http://localhost:5117',
    [switch]$SkipBooksApiStart,
    [string]$MovieRoot = (Join-Path $env:USERPROFILE 'source/repos/Favo.Movie'),
    [string]$MovieApiOrigin = 'http://localhost:5130',
    [switch]$SkipMovieApiStart
)
$ErrorActionPreference = 'Stop'
$favoRoot = $PSScriptRoot
if (!$BooksRoot) {
    foreach ($candidate in @((Join-Path $env:USERPROFILE 'source/repos/Favo Kitap'), (Join-Path $env:USERPROFILE 'source/repos/KitapKivo'))) {
        if (Test-Path (Join-Path $candidate 'Favo.Books.slnx')) { $BooksRoot = $candidate; break }
    }
}
if (!$BooksRoot -or !(Test-Path (Join-Path $BooksRoot 'Favo.Books.slnx'))) { throw 'Kitap bulunamadı. -BooksRoot ile Favo.Books klasörünü belirtin.' }
if (!(Test-Path (Join-Path $MovieRoot 'Favo.Movie.slnx'))) { throw 'Favo.Movie bulunamadi. -MovieRoot ile proje klasorunu belirtin.' }
$logRoot = Join-Path $favoRoot 'artifacts/run'
New-Item -ItemType Directory -Force $logRoot | Out-Null
$started = [Collections.Generic.List[System.Diagnostics.Process]]::new()
function Start-Tracked([string]$Executable, [string[]]$Arguments, [string]$Directory, [string]$Name) {
    $process = Start-Process $Executable -ArgumentList $Arguments -WorkingDirectory $Directory -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logRoot "$Name.log") -RedirectStandardError (Join-Path $logRoot "$Name-error.log")
    $started.Add($process)
    return $process
}
function Wait-Service([string]$Url, [string]$Property, [string]$Expected) {
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        try {
            $health = Invoke-RestMethod $Url -TimeoutSec 5
            if ($health.$Property -eq $Expected) { return }
        } catch { }
        Start-Sleep -Milliseconds 500
    }
    throw "Servis hazır olmadı: $Url — artifacts/run günlüklerini kontrol edin."
}
try {
    foreach ($port in @(5120, 5175)) {
        if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) { throw "Port $port kullanımda. Mevcut Favo'yu kapatın." }
    }
    & (Join-Path $favoRoot 'scripts/Build-Books.ps1') -BooksRoot $BooksRoot
    & (Join-Path $favoRoot 'scripts/Build-Movie.ps1') -MovieRoot $MovieRoot
    $booksRunning = $false
    try { $booksRunning = (Invoke-RestMethod "$BooksApiOrigin/" -TimeoutSec 5).service -eq 'Favo.Books.Api' } catch { }
    if (!$booksRunning) {
        if ($SkipBooksApiStart) { throw 'Belirtilen Kitap API çalışmıyor.' }
        if ($BooksApiOrigin -ne 'http://localhost:5117') { throw 'Özel API adresini önce ayrıca başlatın; -SkipBooksApiStart kullanın.' }
        $booksProject = Join-Path $BooksRoot 'src/backend/Api/Favo.Books.Api'
        $null = Start-Tracked 'dotnet' @('run', '--project', "`"$booksProject`"", '--launch-profile', 'http') $BooksRoot 'books-api'
    }
    Wait-Service "$BooksApiOrigin/" 'service' 'Favo.Books.Api'
    $movieRunning = $false
    try { $movieRunning = (Invoke-RestMethod "$MovieApiOrigin/" -TimeoutSec 5).service -eq 'Favo.Movie.Api' } catch { }
    if (!$movieRunning) {
        if ($SkipMovieApiStart -or $MovieApiOrigin -ne 'http://localhost:5130') { throw 'Belirtilen Movie API calismiyor.' }
        $movieProject = Join-Path $MovieRoot 'src/backend/Favo.Movie.Api'
        $oldIdentityOrigin = $env:Identity__ApiOrigin
        try {
            $env:Identity__ApiOrigin = $BooksApiOrigin
            $null = Start-Tracked 'dotnet' @('run', '--project', "`"$movieProject`"") $MovieRoot 'movie-api'
        } finally { $env:Identity__ApiOrigin = $oldIdentityOrigin }
    }
    Wait-Service "$MovieApiOrigin/" 'service' 'Favo.Movie.Api'
    $oldWebRoot = $env:Books__WebRoot
    $oldApiOrigin = $env:Books__ApiOrigin
    $oldMovieRoot = $env:Movie__WebRoot
    $oldMovieOrigin = $env:Movie__ApiOrigin
    try {
        $env:Books__WebRoot = Join-Path $favoRoot 'artifacts/books'
        $env:Books__ApiOrigin = $BooksApiOrigin
        $env:Movie__WebRoot = Join-Path $favoRoot 'artifacts/movie'
        $env:Movie__ApiOrigin = $MovieApiOrigin
        $apiProject = Join-Path $favoRoot 'src/backend/Favo.Api'
        $null = Start-Tracked 'dotnet' @('run', '--project', "`"$apiProject`"") $favoRoot 'api'
    } finally {
        $env:Books__WebRoot = $oldWebRoot; $env:Books__ApiOrigin = $oldApiOrigin
        $env:Movie__WebRoot = $oldMovieRoot; $env:Movie__ApiOrigin = $oldMovieOrigin
    }
    Wait-Service 'http://localhost:5120/api/health' 'application' 'Favo'
    $frontend = Join-Path $favoRoot 'src/frontend'
    if (!(Test-Path (Join-Path $frontend 'node_modules'))) {
        Push-Location $frontend
        try { npm ci; if ($LASTEXITCODE -ne 0) { throw 'Favo npm ci başarısız.' } } finally { Pop-Location }
    }
    $vite = Join-Path $frontend 'node_modules/vite/bin/vite.js'
    $null = Start-Tracked 'node' @("`"$vite`"") $frontend 'frontend'
    Wait-Service 'http://localhost:5175/api/health' 'application' 'Favo'
    Write-Host 'Favo: http://localhost:5175 — Giriş yap, ardından Kitap kartını seç.'
    Write-Host 'Kitap: http://localhost:5175/kitap/ — Aynı hesap, aynı oturum.'
    Write-Host 'Film: http://localhost:5175/film/ - Ayni Favo hesabi. TMDB katalog baglantisi Movie API uzerinden.'
    Write-Host 'Durdurmak için Ctrl+C. Önceden çalışan Kitap API kapatılmaz.'
    if (!$NoBrowser) { Start-Process 'http://localhost:5175' }
    while (@($started | Where-Object HasExited).Count -eq 0) { Start-Sleep -Seconds 1 }
    throw 'Bir Favo süreci kapandı. artifacts/run günlüklerini kontrol edin.'
} finally {
    foreach ($process in $started) {
        if (!$process.HasExited) { taskkill /PID $process.Id /T /F | Out-Null }
    }
}

