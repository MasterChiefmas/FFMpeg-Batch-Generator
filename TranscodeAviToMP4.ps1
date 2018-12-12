function Get-AviRemuxBat{
    <# .SYNOPSIS
         Generates a batch file of FFmpeg commands to remux AVI files into MP4 containers
    .DESCRIPTION
         A function to generate a batch file with FFMpeg commands that will remux AVIs into an mp4 container, to try and get better streaming support.
         A batch file is generated because it turns out spawning a command line task out in Powershell is really kludgey and unreliable.
    
    
    .NOTES
         Author     : Jason Coleman - pobox@chiencorp.com
        GitTest
    
        TODO:
    .LINK
    
    #>

    Param(
    [string]$Path=".\"
    )


    #### Startup Checks ####        
    Try{
        $Path = Read-Host "Path to search(default to current):"
        # Set default if no response
        If (!$Path){$Path = ".\"}
        # Validate path
        If (!(Test-Path $Path)){
            Write-Host "Path not found"
        }
    }
    Catch{
        Write-Debug -Message "There was a problem validating the source path"
        Exit
    }
    # Trying something a little different, caching the output to memory.

    [string]$BatBuf
    

    # Note: Out-File inside the VS.Code powershell env sticks a BOM mark in that doesn't happen in normal powershell
    $BatBuf  | out-file AviRemux.bat -Encoding ascii

    # Get the top level folder
    Write-Debug -Message "Getting top level folder"
    try {
        #$tld = (Get-Item $Path | sort-object)
        $tld = Get-Item $Path
    }
    catch {
        "Unable to get Top Level Folder: $Path"
    }

    try {
        try {
            New-Item -Force .\transcode.bat | Out-Null
            "" | Out-File .\transcode.bat -Encoding ascii -Append
        }
        catch{"Failed to create new transcode.bat"}
    }
}