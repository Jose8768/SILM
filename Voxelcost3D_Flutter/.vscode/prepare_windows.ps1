$ErrorActionPreference = 'Stop'

$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$destination = 'C:\VX3D'
$generatedPlatformDirectories = @(
    'linux\flutter\ephemeral',
    'macos\Flutter\ephemeral'
)

if (Test-Path -LiteralPath $destination) {
    $item = Get-Item -LiteralPath $destination -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        if ($item.Target -notcontains $source) {
            throw "Refusing to replace unexpected reparse point at $destination."
        }
        & cmd.exe /c "rmdir `"$destination`""
        if ($LASTEXITCODE -ne 0) {
            throw "Could not remove the old project junction at $destination."
        }
    }
}

New-Item -ItemType Directory -Path $destination -Force | Out-Null

$generatedPlatformDirectories | ForEach-Object {
    $generatedPath = Join-Path $destination $_
    if (Test-Path -LiteralPath $generatedPath) {
        Remove-Item -LiteralPath $generatedPath -Recurse -Force
    }
}

$excludedDirectories = @(
    (Join-Path $source 'build'),
    (Join-Path $source '.dart_tool'),
    (Join-Path $source '.git'),
    (Join-Path $source 'windows\flutter\ephemeral')
) + ($generatedPlatformDirectories | ForEach-Object {
    Join-Path $source $_
})
$robocopyArguments = @(
    $source,
    $destination,
    '/MIR',
    '/XD'
) + $excludedDirectories + @(
    '/R:2',
    '/W:1',
    '/NFL',
    '/NDL',
    '/NJH',
    '/NJS',
    '/NP'
)

& robocopy.exe @robocopyArguments
if ($LASTEXITCODE -ge 8) {
    throw "Failed to synchronize project files to $destination (robocopy exit code $LASTEXITCODE)."
}

Write-Output "Prepared Windows project at $destination."
