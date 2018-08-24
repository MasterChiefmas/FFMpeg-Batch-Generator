$DebugPreference = "Continue"
Import-Module -Force .\TranscodeModule.psm1
Set-Location .\test
Get-FFMpeg-Cmd
