param(
    # Game folder inside the WoW install, without the underscores: forever, anniversary, classic_era, ...
    $flavor = "forever"
)

$addonName = "LettuceTracker"
$repoRoot = Split-Path $PSScriptRoot -Parent
$settingsPath = Join-Path $PSScriptRoot "wow-user-settings.json"

$settings = [PSCustomObject]@{}
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
}

$wowPath = $settings.wowPath

if (-not $wowPath) {

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select World of Warcraft Install Folder"

    if ($dialog.ShowDialog() -eq "OK") {
        $wowPath = $dialog.SelectedPath
    } else {
        Write-Host "Folder selection cancelled"
        exit 1
    }

    if (-not (Get-ChildItem $wowPath -Directory -Filter "_*_")) {
        Write-Host "World of Warcraft directory not recognized for: $wowPath"
        exit 1
    }

    $settings | Add-Member -NotePropertyName wowPath -NotePropertyValue $wowPath -Force
    $settings | ConvertTo-Json | Set-Content $settingsPath

    Write-Host "Saved wowPath to $settingsPath"
}

$gamePath = Join-Path $wowPath "_${flavor}_"
if (-not (Test-Path $gamePath)) {
    Write-Host "Game version not installed: $gamePath"
    exit 1
}

$addonPath = Join-Path $gamePath "Interface\AddOns\$addonName"

# Mirror the repo into the addon folder, leaving out everything that isn't part of the addon
robocopy $repoRoot $addonPath /MIR /NJH /NJS /NDL /NP `
    /XD .git .github .vscode README_IMAGES `
    /XF .gitattributes .gitignore README.md

# robocopy exit codes below 8 mean success
if ($LASTEXITCODE -ge 8) {
    Write-Host "Addon copy failed (robocopy exit code $LASTEXITCODE)"
    exit $LASTEXITCODE
}

Write-Host "Addon install complete ($flavor) -> $addonPath"
exit 0
