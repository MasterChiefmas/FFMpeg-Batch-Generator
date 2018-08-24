$DebugPreference = "Continue"
Import-Module -Force .\TranscodeModule.psm1
cd .\test
Get-FFMpeg-Cmd
