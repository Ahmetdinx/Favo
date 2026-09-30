param([Parameter(Mandatory)][string]$BooksRoot)
$ErrorActionPreference = 'Stop'
$portalRoot = Split-Path $PSScriptRoot -Parent
$changes = Get-Content (Join-Path $PSScriptRoot 'books-changes.json') -Raw | ConvertFrom-Json
$backupRoot = Join-Path $portalRoot ('artifacts/books-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$pending = @()
foreach ($change in $changes) {
    $path = Join-Path $BooksRoot $change.path
    $text = if (Test-Path $path) { [IO.File]::ReadAllText($path).Replace("`r`n", "`n") } else { '' }
    $original = $text
    if ($null -ne $change.content) { $text = $change.content }
    foreach ($replacement in $change.replacements) {
        if (!$text.Contains($replacement.before)) { throw "Expected text missing: $($change.path). No files written." }
        $text = $text.Replace($replacement.before, $replacement.after)
    }
    $pending += @{ Path=$path; Relative=$change.path; Original=$original; Content=$text }
}
foreach ($file in $pending) {
    if (Test-Path $file.Path) {
        $backup = Join-Path $backupRoot $file.Relative
        New-Item -ItemType Directory -Force (Split-Path $backup) | Out-Null
        Copy-Item -LiteralPath $file.Path -Destination $backup
    }
    [IO.File]::WriteAllText($file.Path, $file.Content, [Text.UTF8Encoding]::new($false))
    Write-Output "Updated $($file.Relative)"
}
