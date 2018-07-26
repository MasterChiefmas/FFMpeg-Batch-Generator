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
     There are multiple base commands, to allow for different encoding parameters based on the file type.


     Tokens are:
     srcPathReplace - where the full file path of a source video file will be inserted
     tgtPathReplace - where the destination of output files will be inserted
     These are replaced by the equivalent variables in the script. Yep, you have to change the
     hardcode, because the script is assumed that you'll have a fairly static setup (i.e. almost
     always writing to the same target location, so passing a path constantly for something
     that doesn't change often is annoying to me)

.NOTES
     Author     : Jason Coleman - pobox@chiencorp.com
    GitTest

.LINK

#>
    Param(
    [string]$ckPath=".\"
    )

    # if ($IsDebug -eq $true){
    #   Write-Host "DEBUG"
      Write-Host "Processing files in $ckPath"
    # }

    # change to reading source file info via ffprobe
    # build concat decode and sw/hw decode based on that
    # copy to hw decode seems like it'll be slower then qsv for sw decode, hw transform and encode
    # have not tested sw decode, sw transform, hw encode. not sure if that's possible to upload frame after transorm..
    # frame copies may incur too much penalty to ever be worth it at std def
    #
    # Example software path partial (transform+encode)
    # -vf "scale=640:360" -b:v 700k -c:v libx264 -preset superfast -c:a copy -y outfile
    # not sure if -b:v neede since preset is specified.
    # alternate use CRF instead of bitrate?
    # -vf "scale=640:360" -c:v libx264 -preset superfast -CRF 23 -c:a copy -y outfile


    # base path for where transcode targets will be written
    $tgtPath = "\\fs2\poolroot\croco\!recodes\"
    # srcPath not needed? derivied from file path?
    $srcPath

    # FFPRobe line
    $ffprobeBase = 'C:\ffmpeg\ffprobe.exe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 '

    # $ffmpeg_SW_Base software decoder in case the hardware decoder has issues, which seems to happen every so often
    #$ffmpeg_SW_Base = 'rem start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -i "srcPathReplace" -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'

    # sw only, H.264 Target, superfast, 700k
    $encodeSWOnly = ' -vf "scale=640:360" -c:v libx264-b:v 700k'
    # H.264 Target, 700kbps
	$ffmpegBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i "srcPathReplace" -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'

    # HEVC target, 600kbps
    # $ffmpegBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i "srcPathReplace" -vf "scale_qsv=640:360" -load_plugin hevc_hw -b:v 600k -c:v hevc_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'

    # WMV hw accel processing:version with QSV HEVC target, AAC audio@96kbps
    # dxva2 decode, upload frames for QSV transform and encode.
    # $ffmpegWMVBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel dxva2 -i "srcPathReplace"  -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -load_plugin hevc_hw -c:v hevc_qsv -b:v 600k -c:a aac -b:a 96k -y "' + $tgtPath + 'tgtPathReplace"'

    # WMV hybrid processing:SW decode, version with QSV HEVC target, AAC audio@96kbps
    # dxva2 decode, upload frames for QSV transform and encode.
    $ffmpegWMVBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel dxva2 -c:v _codecReplace_ -i "srcPathReplace" -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -load_plugin hevc_hw -c:v hevc_qsv -b:v 600k -c:a aac -b:a 96k -y "' + $tgtPath + 'tgtPathReplace"'

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
        New-Item -Force .\transcode.bat
        Foreach ($fldr in $tld){
            Write-Host 'Processing item:' $fldr.Name
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
                        # Generate transcode command statement, based on the file extension write it to the batch file
                        # specifically, WMVs have a different command to process with.
                        # Might add support later for HEVC or h.264 based on command line switch, for now, it's going to be hardcoding to the appropriate variable.
                        # _codecReplace_
                        switch ($fileExt)
                        {
                            "wmv"
                            {
                                $transCode = $ffmpegWMVBase -Replace "srcPathReplace", $fileFullName
                                #Write-Host "Transcode:$transcode"
                                $ffprobeCmd = $ffprobeBase + $fileFullName
                                $codec = Invoke-Expression $ffprobeCmd
                                #Write-Host "Codec:$codec"
                                switch ($codec){
                                    "wmv1"{
                                        $transcode = $transcode -Replace "_codecReplace_", "wmv1"
                                    }
                                    "wmv2"{
                                        $transcode = $transcode -Replace "_codecReplace_", "wmv2"
                                    }
                                    "wvm3"{
                                        $transcode = $transcode -Replace "_codecReplace_", "wmv3"
                                    }
                                    default{
                                        # assuming wmv3, probably a terrible idea...but whatever
                                        $transcode = $transcode -Replace "_codecReplace_", "wmv3"
                                    }
                                }
                                #$transCode = $transcode -Replace "srcPathReplace", $fileFullName
                            }
                            default
                            {
                                $transCode = $ffmpegBase -Replace "srcPathReplace", $fileFullName
                            }
                        }
                        # if($fileExt -eq "wmv"){
                        #     # process WMV
                        #     $transCode = $ffmpegWMVBase -Replace "srcPathReplace", $fileFullName
                        # }
                        # $transCode = $ffmpegBase -Replace "srcPathReplace", $fileFullName
                        # $transCodeSW = $ffmpeg_SW_Base -Replace "srcPathReplace", $fileFullName
                        # $transcode = $transcode -Replace "tgtPathReplace", $NewName
                        # $transCodeSW = $transCodeSW -Replace "tgtPathReplace", $NewName
                        #                         if($fileExt -eq "wmv"){
                        #                                 $transcode = $transcode -Replace "-c:a copy", "-c:a aac -b:a 128k"
                        #                                 $transCodeSW = $transcode -Replace "-c:a copy", "-c:a aac -b:a 128k"
                        #                         }
                        $transcode = $transcode -Replace "tgtPathReplace", $NewName
                        'time /t'  | out-file transcode.bat -Encoding ascii -Append
                        $transcode | out-file transcode.bat -Encoding ascii -Append
                        'time /t'  | out-file transcode.bat -Encoding ascii -Append
                        # $transCodeSW | out-file transcodeSW.bat -Encoding ascii -Append
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
