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

Write-Host 'Downloading latest patch (chrome_elf.zip)...'`n
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
  Sleep
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
  mkdir $SpotifyDirectory >$null 2>&1
  #fixes the spotify installation error
  Write-Host 'Running installation...'
  Start-Process -FilePath "$PWD\SpotifyFullSetup.exe"
  Write-Host 'Stopping Spotify...Again'
  #to patch
  while ((Get-Process -name Spotify -ErrorAction SilentlyContinue) -eq $null){
     #waiting until installation complete
    #empty loop, because i cant use the "-wait" on start process as the installer opens the spotify after installation which pauses the script.
  }
  Stop-Process -Name Spotify >$null 2>&1
  Stop-Process -Name SpotifyWebHelper >$null 2>&1
  Stop-Process -Name SpotifyFullSetup >$null 2>&1 
  #the installer pops a new error at the end of installation, so it is forced to stop. No Harm in that.
}

if (!(test-path $SpotifyDirectory/chrome_elf.dll.bak)){
    #backupexist and checking seems not to be working. so its change
	move $SpotifyDirectory\chrome_elf.dll $SpotifyDirectory\chrome_elf.dll.bak >$null 2>&1
}

Write-Host 'Patching Spotify...'
$patchFiles = "$PWD\chrome_elf.dll", "$PWD\config.ini"
Copy-Item -LiteralPath $patchFiles -Destination "$SpotifyDirectory"

$tempDirectory = $PWD
Pop-Location

Remove-Item -Recurse -LiteralPath $tempDirectory 
#clears the bts-temp folder even if installation unsuccessfull/folder not empty. 

Write-Host 'Patching Complete, starting Spotify...'
Start-Process -WorkingDirectory $SpotifyDirectory -FilePath $SpotifyExecutable
Write-Host 'Done.'
pause
exit