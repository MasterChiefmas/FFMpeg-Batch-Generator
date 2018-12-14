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
    [string]$Path=".\",
    [string]$Action="remux"
    )


    # Set working path
    $Path = Read-Host "Path to search(default to current)"
    # Set default if no response
    # If (!$Path){$Path = ".\"}

    # Set action path
    #$Action = Read-Host "Action(Remux or Transcode)"
    # Set default if no response
    # If (!$Action){$Action = "remux"}


    #### Startup Checks ####        
    # Validate path
    If (!(Test-Path $Path)){
        Throw "Specified path not found"
    }
    
    # Trying something a little different, caching the output to memory instead of writing line by line.

    $BatBuf = New-Object System.Text.StringBuilder
    $CleanupBuf = New-Object System.Text.StringBuilder

    $FileList = Get-ChildItem -Recurse -Filter '*.avi' -File -ErrorAction 'SilentlyContinue' | Sort-Object
    Foreach ($file IN $FileList){
        # Version of path with mp4 extension:
        $mp4Name = ($file.FullName).TrimEnd(".avi") + ".mp4"
        $bakName = ($file.FullName).TrimEnd(".avi") + ".bak"

        # Wrap this in some logic
        # Remux
        $BatBuf.Append("ffmpeg -i """ + $file.FullName + """ -acodec copy -vcodec copy """ + $mp4name + """`r`n") 
        # Transcode
        #$BatBuf.Append("ffmpeg -i """ + $file.FullName + """ -acodec copy -vcodec copy """ + $mp4name + """`r`n") 

        $BatBuf.Append("Rename-Item  """ + $file.FullName + """  """ + $bakName + """`r`n") 
        $CleanupBuf.Append("Remove-Item ""$bakName""`r`n")
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
        $CleanupBuf.ToString()  | out-file AviCleanup.ps1 -Encoding ascii
    }
    Catch{
        Throw "Failed to write AviCleanup.ps1. CleanupBuf Size:" + $CleanupBuf.Length
    }
}
