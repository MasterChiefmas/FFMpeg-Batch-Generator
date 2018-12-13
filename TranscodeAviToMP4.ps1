function Get-AviRemuxScript{
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
    $CleanupBuf = New-Object System.Text.StringBuilder

    $FileList = Get-ChildItem -Recurse -Filter '*.avi' -File -ErrorAction 'SilentlyContinue' 
    Foreach ($file IN $FileList){
        # Version of path with mp4 extension:
        $mp4Name = ($file.FullName).TrimEnd(".avi") + ".mp4"
        $bakName = ($file.FullName).TrimEnd(".avi") + ".bak"
        $BatBuf.Append($mp4Name + "`r`n")
        # Insert the command string
        $BatBuf.Append("ffmpeg -i """ + $file.FullName + """ -acodec copy -vcodec copy """ + $mp4name + """`r`n") 
        $BatBuf.Append("Rename-Item  ""$file.FullName""  """ + $bakName + """`r`n") 
        $CleanupBuf.Append("Delete-Item ""$bakName""`r`n")
    }

    Write-Debug -Message "Writing AviRemux.ps1"
    Try {
        # Note: Out-File inside the VS.Code powershell env sticks a BOM mark in that doesn't happen in normal powershell
        $BatBuf.ToString()  | out-file AviRemux.ps1 -Encoding ascii
    }
    Catch{
        Throw "Failed to write AviRemux.ps1. Batbuf Size:" + $BatBuf.Length
    }

    Write-Debug -Message "Writing AviCleanup.ps1"
    Try {
        # Note: Out-File inside the VS.Code powershell env sticks a BOM mark in that doesn't happen in normal powershell
        $CleanupBuf.ToString()  | out-file CleanupBuf.ps1 -Encoding ascii
    }
    Catch{
        Throw "Failed to write CleanupBuf.ps1. CleanupBuf Size:" + $CleanupBuf.Length
    }
}
