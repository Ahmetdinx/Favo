param([Parameter(Mandatory)][string]$BooksRoot)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts/Build-Books.ps1') -BooksRoot $BooksRoot
dotnet publish (Join-Path $PSScriptRoot 'src/backend/Favo.Api') -c Release -o (Join-Path $PSScriptRoot 'artifacts/publish')
if ($LASTEXITCODE -ne 0) { throw 'Favo publish başarısız.' }
$source = Join-Path $PSScriptRoot 'artifacts/books'
$destination = Join-Path $PSScriptRoot 'artifacts/publish/wwwroot/kitap'
New-Item -ItemType Directory -Force $destination | Out-Null
Get-ChildItem -LiteralPath $source | Copy-Item -Destination $destination -Recurse -Force
Write-Host 'Yayın paketi: artifacts/publish. Portal__Origin ve Books__ApiOrigin HTTPS adreslerini yapılandırın.'
