# Finds a sibling Favo project: explicit path, next to this repo, then ~/source/repos.
param(
    [string]$Explicit,
    [Parameter(Mandatory)][string]$Solution,
    [Parameter(Mandatory)][string[]]$Names
)
$ErrorActionPreference = 'Stop'
if ($Explicit) {
    if (Test-Path -LiteralPath (Join-Path $Explicit $Solution)) { return (Resolve-Path -LiteralPath $Explicit).Path }
    throw "$Solution not found in: $Explicit"
}
$portalRoot = Split-Path $PSScriptRoot -Parent
$parents = @((Split-Path $portalRoot -Parent), (Join-Path $env:USERPROFILE 'source/repos'))
foreach ($parent in $parents) {
    foreach ($name in $Names) {
        $candidate = Join-Path $parent $name
        if (Test-Path -LiteralPath (Join-Path $candidate $Solution)) { return (Resolve-Path -LiteralPath $candidate).Path }
    }
}
throw "$Solution not found next to Favo or under ~/source/repos. Pass its folder explicitly."
