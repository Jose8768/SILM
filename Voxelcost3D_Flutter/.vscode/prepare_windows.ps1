$ErrorActionPreference = 'Stop'

$source = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path.TrimEnd('\')
$sourceParent = Split-Path -Parent $source
$projectFolder = Split-Path -Leaf $source
$driveLetter = 'V'
$drive = "${driveLetter}:"
$mappingPrefix = "${driveLetter}:\: => "
$mappings = @(& subst.exe)
$existingMapping = $mappings | Where-Object { $_.StartsWith($mappingPrefix, [StringComparison]::OrdinalIgnoreCase) }
$existingDrive = Get-PSDrive -Name $driveLetter -ErrorAction SilentlyContinue

if ($existingMapping) {
    $mappedPath = $existingMapping.Substring($mappingPrefix.Length).TrimEnd('\')
    if (-not [string]::Equals($mappedPath, $sourceParent, [StringComparison]::OrdinalIgnoreCase)) {
        $isPreviousProjectMapping =
            [string]::Equals($mappedPath, $source, [StringComparison]::OrdinalIgnoreCase)
        $isStaleMapping = -not (Test-Path -LiteralPath $mappedPath -PathType Container)
        if (-not $isPreviousProjectMapping -and -not $isStaleMapping) {
            throw "$drive is already mapped to '$mappedPath'; it must be free or map to '$sourceParent'."
        }

        & subst.exe $drive /D
        if ($LASTEXITCODE -ne 0) {
            throw "Could not remove the stale $drive mapping to '$mappedPath'."
        }

        & subst.exe $drive $sourceParent
        if ($LASTEXITCODE -ne 0) {
            throw "Could not map $drive to '$sourceParent'."
        }
    }
} elseif ($existingDrive) {
    throw "$drive is already assigned. Free it or choose another drive letter in the Windows launch configuration."
} else {
    & subst.exe $drive $sourceParent
    if ($LASTEXITCODE -ne 0) {
        throw "Could not map $drive to '$sourceParent'."
    }
}

Write-Output "Windows project path ready at $(Join-Path "$drive\" $projectFolder)."
