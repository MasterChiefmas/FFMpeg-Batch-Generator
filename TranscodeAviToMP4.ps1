function Get-AviRemuxBat{
    <# .SYNOPSIS
         Generates a batch file of FFmpeg commands to remux AVI files into MP4 containers
    .DESCRIPTION
         A function to generate a batch file with FFMpeg commands that will remux AVIs into an mp4 container, to try and get better streaming support.
         A batch file is generated because it turns out spawning a command line task out in Powershell is really kludgey and unreliable.
         Assumes ffmpeg.exe is on the path
    
    
    .NOTES
         Author     : Jason Coleman - pobox@chiencorp.com
        GitTest
    
        TODO:
    .LINK
    
    #>

    Param(
    [string]$Path=".\"
    )


    # Set working path
    $Path = Read-Host "Path to search(default to current):"
    # Set default if no response
    If (!$Path){$Path = ".\"}

    #### Startup Checks ####        
    # Validate path
    If (!(Test-Path $Path)){
        Throw "Specified path not found"
    }
    
    # Trying something a little different, caching the output to memory instead of writing line by line.

    $BatBuf = New-Object System.Text.StringBuilder

    $FileList = Get-ChildItem -Recurse -Filter '*.avi' -File -ErrorAction 'SilentlyContinue' 
    Foreach ($file IN $FileList){
        # Version of path with mp4 extension:
        $mp4Name = ($file.FullName).TrimEnd(".avi") + ".mp4"
        $BatBuf.Append($mp4Name + "`r`n")
        # Insert the command string
        $BatBuf.Append("ffmpeg -i '" + $file.FullName + "' -acodec copy -vcodec copy '" + $mp4name + "'`r`n") | Out-Null
    }

    Write-Debug -Message "Writing AviRemux.bat"
    Try {
        # Note: Out-File inside the VS.Code powershell env sticks a BOM mark in that doesn't happen in normal powershell
        $BatBuf.ToString()  | out-file AviRemux.bat -Encoding ascii
    }
    Catch{
        Throw "Failed to write AviRemux.bat. Batbuf Size:" + $BatBuf.Length
    }

}
