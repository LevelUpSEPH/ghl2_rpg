# Builds hlrpg-server.zip: the addon, the Lambda gamemode, server.cfg, mount.cfg and setup.sh (for a VDS).
# Run from anywhere:   powershell -ExecutionPolicy Bypass -File server\pack.ps1
# Optional:            -Lambda <path to gamemodes\lambda>   -Out <zip path>
param(
    [string]$Lambda = "D:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\gamemodes\lambda",
    [string]$Out = (Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "hlrpg-server.zip")
)
$ErrorActionPreference = "Stop"

$repo = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path (Join-Path $Lambda "gamemode"))) { throw "Lambda not found at $Lambda (use -Lambda <path>)" }

$stage = Join-Path $env:TEMP ("hlrpg-server-" + [guid]::NewGuid().ToString("N"))
$root = Join-Path $stage "hlrpg-server"
New-Item -ItemType Directory -Force (Join-Path $root "addon") | Out-Null

# Addon: what GMod loads, without git or the server kit
foreach ($item in @("addon.txt", "lua", "materials", "gamemodes")) {
    Copy-Item (Join-Path $repo $item) (Join-Path $root "addon") -Recurse
}

# Lambda, without its git folder
Copy-Item $Lambda (Join-Path $root "lambda") -Recurse
$lambdaGit = Join-Path $root "lambda\.git"
if (Test-Path $lambdaGit) { Remove-Item $lambdaGit -Recurse -Force }

Copy-Item (Join-Path $PSScriptRoot "server.cfg") $root
Copy-Item (Join-Path $PSScriptRoot "mount.cfg") $root

# setup.sh must have Unix line endings or bash refuses it
$setup = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "setup.sh")) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText((Join-Path $root "setup.sh"), $setup, (New-Object System.Text.UTF8Encoding $false))

if (Test-Path $Out) { Remove-Item $Out -Force }
Compress-Archive -Path $root -DestinationPath $Out
Remove-Item $stage -Recurse -Force

$size = [math]::Round((Get-Item $Out).Length / 1MB, 1)
Write-Host "Built $Out ($size MB)"
