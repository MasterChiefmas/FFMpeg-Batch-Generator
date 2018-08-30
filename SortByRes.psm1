# https://github.com/MasterChiefmas/FFMpeg-Batch-Generator


function GetVidRes{
    # Get params
    Param(
        [string]$target = $null
    )

    # Use ffprobe.exe to figure out resolution of a video
    [string]$ffmpegroot = 'C:\ffmpeg'
    [string]$ffprobe = 'C:\ffmpeg\ffprobe.exe'
    [string]$ffprobeSwitches = ' -v error -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 '
    [string]$ffprobeCmd
    $frameHeight

    # Someday, I should check to be sure ffprobe.exe exists

    If ($target -eq $null){
        Write-Host -ForegroundColor Yellow "A file path is required."
        return 0
    }
    else{
        $ffprobeCmd = $ffprobe + $ffprobeSwitches + $target
        $frameHeight = Invoke-Expression $ffprobeCmd
        Write-Debug -Message ("GetVidRes:"+$target+" has a frame height of " + $frameHeight)
        return $frameHeight
    }

}

function IsVidType{
    # Just checks the extension of the passed item against a list of accepted ones and returns true/false if it's in the list or not
    # Get params
    Param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$file
    )

    [string]$fileFullName
    [string]$fileExt
    $vidExtensions = @('mkv','mp4','wmv','avi','mpg','flv','mov','vob','m4v')

    # Assumes a 3 character extension is present. It shouldn't matter if there isn't one.
    $fileFullName = $file.FullName.ToString()
    $fileExt = $fileFullName.Substring((($fileFullName.Length)-3), 3)
    Write-Debug -Message ("IsVidType: Extension is $fileExt")
    if ($vidExtensions -match $fileExt){
        Write-Debug -Message "IsVidType: Match found"
        return $true
    }
    else {
        Write-Debug -Message "IsVidType: Match not found"
        return $false
    }
}

function SortByRes{
# Define Vars
# Get params
    Param(
    [string]$srcPath,
    [string]$destPath
    )

    
$SortResolutions = @(480,720,1080)
$DumpFldr = ''  #Whatever can't be sorted properly
$tld
[bool]$IsVid
$VidRes


# Hardcode acceptable resolutions?

#### Startup Checks ####        
# Verify Sort Target + subfolders exists
Try{
    If (!(Test-Path $srcPath)){
        Write-Host "Path not found"
    }
}
Catch{
    Write-Debug -Message "There was a problem validating the path"
    Exit
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
#### /Startup Checks ####

#### main ####
# Get the top level folder
Write-Debug -Message "Getting top level folder"
try {
    $tld = (Get-ChildItem $srcPath | sort-object)
}
catch {
    "Unable to get Top Level Folder: $srcPath"
    Exit
}

# Use routine from TranscodeModule
Foreach ($thing in $tld){
    Write-Debug  -Message ('Processing thing: ' + $thing + 'of type ' + $thing.GetType())
    # if thing is folder, get all files inside, else process as file
    If ($thing.GetType() -eq [System.IO.DirectoryInfo]){
        # Set base file name from folder name, look in subfolders for videos
        Write-Host -ForegroundColor Green "Processing $thing as a folder..."
    }
    elseif ($thing.GetType() -eq [System.IO.FileInfo]) {
        # Verify it's a video, assume file name is valid. Check resolution.
        Write-Host -ForegroundColor Green "Processing $thing as a file..."
        If((IsVidType($thing)) -eq $true){
            $VidRes = GetVidRes($thing.FullName)
            Write-Debug -Message ($thing.FullName + " is "+$VidRes+" pixels high")
            Switch ($VidRes){
                {$_ -le 480}{
                    Write-Host -ForegroundColor Green "Filing $thing as Standard Def"
                    Break
                }
                {$_ -gt 480 -and $_ -le 720}{
                    Write-Host -ForegroundColor Green "Filing $thing as 720"
                    Break
                }
                {$_ -gt 720 -and $_ -le 1080}{
                    Write-Host -ForegroundColor Green "Filing $thing as 1080"
                    Break
                }
                {$_ -gt 1080}{
                    Write-Host -ForegroundColor Green "Filing $thing as 4K"
                    Break
                }
                default {
                    Write-Host -ForegroundColor Red "Panic! I don't know what to do with $thing"
                }
            }

        }
        else{
            Write-Host 'Not a video, skipping '$thing.FullName
        }
    }
    else {
        Write-Host -ForegroundColor Red "This should never happen. I do not know what $thing is..."
    }
}



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
