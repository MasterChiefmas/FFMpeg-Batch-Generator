# RFAF = Rename-FileAsFolder
Function RFAF
{
    Param(
    [string]$ckPath=".\"
    )

    # if ($IsDebug -eq $true){
    #   Write-Host "DEBUG"
      Write-Host "Path:$ckPath"
    # }

    $vidExtensions = @('*.mkv','*.mp4','*.wmv','*.avi')
    [System.IO.FileInfo]$file

    try {
        $tld = Get-ChildItem $ckPath
    }
    catch {
        Throw "Unable to get Top Level Directory"
    }

    try{
        "" > '.\rename-files.ps1'
    }
    catch{
        Throw "Unable to open logfile"
    }
    #Get-ChildItem -include ($vidExtensions) -recurse
    # process the TLDs
    # Write-Host "Folder Count:" $fldr
    try {
        Foreach ($fldr in $tld){
            try {
                $files = Get-ChildItem -File -include ('*.mkv','*.mp4','*.wmv','*.avi') -Recurse -LiteralPath $fldr.FullName
                Foreach ($file in $files){
                    # Write-Host
                    # Write-Host "Folder name:" $fldr.BaseName
                    # Write-Host "File to Change:" $file.FullName
                    $fileFullName = $file.FullName.ToString()
                    # Write-Host "File Full Name:" $fileFullName
                    $fileExt = $fileFullName.Substring((($fileFullName.Length)-3), 3)
                    # Write-Host "BlahExt" $fileFullName.Substring((($fileFullName.Length)-3), 3)
                    # Write-Host "File Ext:" $fileExt
                    switch($fileExt)
                    {
                        "mkv" {$IsVid = $true; break}
                        "mp4" {$IsVid = $true; break}
                        "wmv" {$IsVid = $true; break}
                        "avi" {$IsVid = $true; break}
                        "flv" {$IsVid = $true; break}
                        "mov" {$IsVid = $true; break}
                        default {$IsVid = $false; break}
                    }
                    if ($IsVid){
                        try {
                            $NewName = ${fldr}.BaseName.ToString().Trim() + ${file}.Extension.ToString().Trim()
                        }
                        catch {
                            Throw "It Broke"
                        }
                        
                        # Write-Host "Rename-Item -LiteralPath '$fileFullName' -NewName '$NewName' -WhatIf" 
                        $renCmd =  "Rename-Item -LiteralPath '$fileFullName' -NewName '$NewName' -WhatIf" 
                        Write-Host $renCmd
                        $renCmd >> '.\rename-files.ps1'
                    }
                }

            }
            catch {
                Throw "No files? $fldr.BaseName:$files.Length"
            }
        }
    }
    catch {
        Throw "Folder Loop broke on $fldr"
        Continue
    }

}

