# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = 'SilentlyContinue'

$SpotifyDirectory = "$env:APPDATA\Spotify"
$SpotifyExecutable = "$SpotifyDirectory\Spotify.exe"

Write-Host 'Stopping Spotify...'
Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
  Write-Host @'
The Microsoft Store version of Spotify has been detected which is not supported.
Please uninstall it first, and Run this file again.

To uninstall, search for Spotify in the start menu and right-click on the result and click Uninstall.
'@
  Pause
  exit
}


Push-Location -LiteralPath $env:TEMP
try {
  # Unique directory name based on time
  New-Item -Type Directory -Name "BlockTheSpot-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" `
  | Convert-Path `
  | Set-Location
} catch {
  Write-Output $_
  Pause
  exit
}

Write-Host 'Downloading latest patch (chrome_elf.zip)...'
$webClient = New-Object -TypeName System.Net.WebClient
try {
  $webClient.DownloadFile(
    # Remote file URL
    'https://github.com/mrpond/BlockTheSpot/releases/latest/download/chrome_elf.zip',
    # Local file path
    "$PWD\chrome_elf.zip"
  )
} catch {
  Write-Output $_
  Pause
  exit
}
Expand-Archive -Force -LiteralPath "$PWD\chrome_elf.zip" -DestinationPath $PWD
Remove-Item -LiteralPath "$PWD\chrome_elf.zip"

$spotifyInstalled = (Test-Path -LiteralPath $SpotifyExecutable)
if (-not $spotifyInstalled) {
  Write-Host @'
Spotify installation was not detected.
Downloading Latest Spotify full setup, please wait...
'@
  try {
    $webClient.DownloadFile(
      # Remote file URL
      'https://download.scdn.co/SpotifyFullSetup.exe',
      # Local file path
      "$PWD\SpotifyFullSetup.exe"
    )
  } catch {
    Write-Output $_
    Pause
    exit
  }

  Write-Host 'Running installation...'
  Start-Process -Wait -FilePath "$PWD\SpotifyFullSetup.exe"
  Remove-Item -LiteralPath "$PWD\SpotifyFullSetup.exe"
}

$backupExists = (Test-Path -LiteralPath "$SpotifyDirectory\chrome_elf.dll.bak")
if (-not $backupExists) {
  Write-Host 'Backing up stock chrome_elf.dll...'
  Copy-Item -LiteralPath "$SpotifyDirectory\chrome_elf.dll" `
            -Destination "$SpotifyDirectory\chrome_elf.dll.bak"
}

Write-Host 'Patching Spotify...'
$patchFiles = "$PWD\chrome_elf.dll", "$PWD\config.ini"
# TODO: figure out if this needs admin privileges
# TODO: maybe back up the previous config, overwriting an existing backup?
Copy-Item -Force -LiteralPath $patchFiles -Destination "$SpotifyDirectory"
Remove-Item -LiteralPath $patchFiles

$tempDirectory = $PWD
Pop-Location

if ((Get-ChildItem $tempDirectory | Measure-Object).Count -eq 0) {
  Remove-Item -LiteralPath $tempDirectory
} else {
  # Keep directory if removal of any file failed and alert the user, just in case:
  Write-Host "Patch directory $tempDirectory wasn't empty, you can remove it manually."
}

Write-Host 'Patching Complete, starting Spotify...'
Start-Process -WorkingDirectory $SpotifyDirectory -FilePath $SpotifyExecutable
Write-Host 'Done.'
