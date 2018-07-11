# https://github.com/MasterChiefmas/FFMpeg-Batch-Generator
function Get-FFMpeg-Cmd{
<# .SYNOPSIS
     Generates a batch file of FFmpeg commands
.DESCRIPTION
     A function to generate a batch file with FFMpeg transcoding commands from a folder using a 
     pre-defined, tokenized command as the base. The default command is also setup to run at belownormal
     priority.

     Be sure to adjust variables in script as needed:
     $tgtPath - where output files are written
     $srcPath 
     $ffmpegBase - the base command written. See below:
     
     Replace $ffmpegBase with your command.
     Tokens are:
     srcPathReplace - where the full file path of a source video file will be inserted
     tgtPathReplace - where the destination of output files will be inserted
     These are replaced by the equivalent variables in the script. Yep, you have to change the
     hardcode, because the script is assumed that you'll have a fairly static setup (i.e. almost
     always writing to the same target location, so passing a path constantly for something
     that doesn't change often is annoying to me)



.NOTES
     Author     : Jason Coleman - pobox@chiencorp.com
.LINK

#>
    Param(
    [string]$ckPath=".\"
    )

    # if ($IsDebug -eq $true){
    #   Write-Host "DEBUG"
      Write-Host "Processing files in $ckPath"
    # }

    # base path for where transcode targets will be written
    $tgtPath = "\\fs2\poolroot\croco\!recodes\"
    # srcPath not needed? derivied from file path?
    $srcPath

    # $ffmpeg_SW_Base software decoder in case the hardware decoder has issues, which seems to happen every so often
    $ffmpeg_SW_Base = 'rem start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -i "srcPathReplace" -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -b:v 800k -c:v h264_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'
    
    $ffmpegBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i "srcPathReplace" -vf "scale_qsv=640:360" -b:v 800k -c:v h264_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'

    # The list of extensions that will be considered video files to write a statement for
    $vidExtensions = @('mkv','mp4','wmv','avi','mpg','flv','mov','vob','m4v')
    [System.IO.FileInfo]$file

    try {
        $tld = Get-ChildItem $ckPath | sort-object
    }
    catch {
        Throw "Unable to get Top Level Directory"
    }

    #Get-ChildItem -include ($vidExtensions) -recurse
    # process the TLDs
    # Write-Host "Folder Count:" $fldr
    try {
        Foreach ($fldr in $tld){
            Write-Host 'Processing folder:' $fldr.Name
            try {
                $files = Get-ChildItem -File -Recurse -LiteralPath $fldr.FullName
                Foreach ($file in $files){
                    $fileFullName = $file.FullName.ToString()
                    # Assumes a 3 character extension is present. It shouldn't matter if there isn't one.
                    $fileExt = $fileFullName.Substring((($fileFullName.Length)-3), 3)
                    if ($vidExtensions -match $fileExt){
                        $IsVid = $true
                    }
                    else {
                        $IsVid = $false
                    }
                    if (($IsVid) -and -not ($fileFullName -match 'sample')){
                        # Exclude files with the word 'sample' in them
                        try {
                            $NewName = ${fldr}.BaseName.ToString().Trim() + ".mp4"
                        }
                        catch {
                            Throw "It Broke"
                        }


                        # Generate transcode command statement, write it to the batch file
                        $transCode = $ffmpegBase -Replace "srcPathReplace", $fileFullName
                        $transCodeSW = $ffmpeg_SW_Base -Replace "srcPathReplace", $fileFullName
                        $transcode = $transcode -Replace "tgtPathReplace", $NewName
                        $transCodeSW = $transCodeSW -Replace "tgtPathReplace", $NewName
                                                if($fileExt -eq "wmv"){
                                                        $transcode = $transcode -Replace "-c:a copy", "-c:a aac -b:a 128k"
                                                        $transCodeSW = $transcode -Replace "-c:a copy", "-c:a aac -b:a 128k"
                                                }
												'time /t'  | out-file transcode.bat -Encoding ascii -Append
                                                $transcode | out-file transcode.bat -Encoding ascii -Append
												'time /t'  | out-file transcode.bat -Encoding ascii -Append
                                                $transCodeSW | out-file transcodeSW.bat -Encoding ascii -Append
                    }
                    else {
                        Write-Host "Skipping $fileFullName"
                        continue
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
