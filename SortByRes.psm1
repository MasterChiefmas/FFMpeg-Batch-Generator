# https://github.com/MasterChiefmas/FFMpeg-Batch-Generator
function SortByRes{

# Define Vars

# Get params
    Param(
    [string]$srcPath,
    [string]$destPath
    )

    
$ffmpegroot = 'C:\ffmpeg'
$ffprobe = 'C:\ffmpeg\ffprobe.exe'
$SortResolutions = @(480,720,1080)
$DumpFldr = ''  #Whatever can't be sorted properly
# Hardcode acceptable resolutions?

        
# Verify Sort Target + subfolders exists
Try{
    If (!(Test-Path $srcPath)){
        Write-Host "Path not found"
    }
}
Catch{
    Write-Debug -Message "There was a problem validating the path"
}


# Get the top level folder to sort
Write-Debug -Message "Getting top level folder"
try {
    $tld = (Get-ChildItem $srcPath | sort-object)
}
catch {
    "Unable to get Top Level Folder: $srcPath"
    Exit
}

# Establish the batch file to store the processing commands...
try {
    New-Item -Force .\process.bat
    "" | Out-File .\process.bat -Encoding ascii -Append
}
catch {
    Write-Debug -Message "Unable to setup process.bat"
    Exit
}


# Get Top Level Folder Being Processed
# Use routine from TranscodeModule
# Get ONLY folders

# ForEach Folder
#        Store the name of the folder
#        Look for video files (how to handle if multiple large?)
#        Get all files? Loop through to find vid files and check for multiple large? Skip then?
#        For Each video file of matching type
#            FFProbe to read vertical res
#            If fileRes <= 480
#            If fileRes 480 - 720
#            If fileRes 720 - 1080
#            If fileRes 1080+
#            Else put in DumpFldr
#              Files that can't be read I guess?

}
