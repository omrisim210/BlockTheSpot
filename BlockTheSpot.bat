;;;===,,,@echo off
;;;===,,,findstr /v "^;;;===,,," "%~f0" > "%~dp0ps.ps1"
;;;===,,,PowerShell.exe -ExecutionPolicy Bypass -Command "& '%~dp0ps.ps1'"
;;;===,,,del /s /q "%~dp0ps.ps1" >NUL 2>&1
;;;===,,,pause
write-host(" ***************** ")
write-host(" Author: @rednek46")
write-host(" ***************** ")
taskkill /f /im Spotify.exe >$null 2>&1
taskkill /f /im spotifywebhelper.exe >$null 2>&1

Get-AppxPackage -Name "SpotifyAB.SpotifyMusic" | findstr "PackageFullName" >$null 2>&1
if ($not -eq $?) {
	Write-Host("")
	Write-Host("The Microsoft Store version of Spotify has been detected which is not supported.")
	Write-Host("Please uninstall it first, and Run this file again.")
	Write-Host("")
	Write-Host("To uninstall, search for Spotify in the start menu and right-click on the result and click Uninstall.")
	Write-Host("")
    pause
    exit
}

Write-Host("Downloading latest patch (chrome_elf.zip)")
Write-Host("")

(new-object System.Net.WebClient).DownloadFile('https://github.com/mrpond/BlockTheSpot/releases/latest/download/chrome_elf.zip','chrome_elf.zip')
Write-Host("Patching Spotify..")
Expand-Archive -Force 'chrome_elf.zip' $PWD

if (test-path $env:appdata/Spotify/Spotify.exe){
	
    if (!(test-path $env:appdata/Spotify/chrome_elf.dll.bak)){
		move $env:appdata\Spotify\chrome_elf.dll $env:appdata\Spotify\chrome_elf.dll.bak >$null 2>&1
	}

	cp chrome_elf.dll $env:appdata\Spotify\ >$null 2>&1
	cp config.ini $env:appdata\Spotify\ >$null 2>&1
	rm $pwd/chrome_elf.dll >$null 2>&1
	rm $pwd/config.ini >$null 2>&1
	Write-Host("Patching Completed.")

} else {
	write-host("Spotify installation was not detected. Downloading Latest Spotify full setup. ")
	write-host("Please wait..")
	(new-object System.Net.WebClient).DownloadFile('https://download.scdn.co/SpotifyFullSetup.exe','SpotifyFullSetup.exe')
	write-host("Running installation...")

	.\SpotifyFullSetup.exe

	rm $pwd/SpotifyFullSetup.exe >$null 2>&1

	write-host("Patching Spotify..")
	move $env:appdata\Spotify\chrome_elf.dll $env:appdata\Spotify\chrome_elf.dll.bak >$null 2>&1
	cp chrome_elf.dll $env:appdata\Spotify\ >$null 2>&1
	cp config.ini $env:appdata\Spotify\ >$null 2>&1
	rm $pwd/chrome_elf.dll >$null 2>&1
	rm $pwd/config.ini >$null 2>&1
	Write-Host("Patching Completed.")
}
exit