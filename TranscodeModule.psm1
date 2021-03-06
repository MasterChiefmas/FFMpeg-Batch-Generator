# https://github.com/MasterChiefmas/FFMpeg-Batch-Generator

Function RemoveBrackets(){
<# .SYNOPSIS
     Replace square brackets in file system names with parenthesis
.DESCRIPTION
    Square brackets can cause problems if they are in the name of a file system object, in particular, for PowerSheel. This will seek things out and replace them with the equal parenthesis
.NOTES
     Author     : Jason Coleman - pobox@chiencorp.com
    GitTest

    TODO:
.LINK

#>
[string]$newName
    get-childitem | ForEach-Object {
        Write-Host "Checking $_"
        If (($_.Name -Match "\[") -or ($_.Name -Match "\]")){
            Write-Host -ForegroundColor Yellow "Brackets found in $_.name, replacing..."
            $newName = $_.name.Replace("[","(")
            $newName = $newName.Replace("]",")")
            Move-Item -LiteralPath $_.name $newName
        }
    }
}
function Get-FFMpeg-Batch{
<# .SYNOPSIS
     Generates a batch file of FFmpeg commands
.DESCRIPTION
     A function to generate a batch file with FFMpeg transcoding commands from a folder using a
     pre-defined, tokenized command as the base. The default command is also setup to run at belownormal
     priority. Depends on Get-FFMpeg-Cmd

     A batch file is generated because it turns out spawning a command line task out in Powershell is really kludgey and unreliable.

    Parameters:
    encodeTo: target codec to encode video to. h264, hevc
    bitrate: target bitrate for video stream encode.

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

    TODO:
     Add "-movflags +faststart" as default encode option?  (Re-organizes resulting file into a fast streaming format by moving metadata packets to the front of the video instead of having them scattered or at the end)
     This option will add some time, probably however long it takes to recopy the file (pass to extract all the meta data, and write at the beginning, followed by copying all the data). But do I care?
.LINK

#>
    Param(
    [string]$Path=".\",
    [string]$encodeTo="h264",
    [string]$bitrate="700k",
    [string]$decMode="hw",
    [string]$encMode="hw"
    )


    #### Startup Checks ####        
    Try{
        $Path = Read-Host "Path to encode(default to current)"
        # Set default if no response
        If (!$Path){$Path = ".\"}
        # Validate path
        If (!(Test-Path $Path)){
            Write-Host "Path not found"
        }
    }
    Catch{
        Write-Debug -Message "There was a problem validating the soruce path"
        Exit
    }

    Write-Debug -Message "Processing files in $Path"
    Write-Debug -Message "EncodeMode:$mode"


    # Configuration of the encode and decode modes separated out into their own things to allow mix and match configuration.
    [string]$mode
    
    # base path for where transcode targets will be written
    $tgtPath = "\\fs2\poolroot\croco\!recodes\"
    # srcPath not needed? derivied from file path?
    $srcPath

    # FFPRobe line
    $ffprobeBase = 'C:\ffmpeg\ffprobe.exe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 '

    # $ffmpeg_SW_Base software decoder in case the hardware decoder has issues, which seems to happen every so often
    #$ffmpeg_SW_Base = 'rem start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -i "srcPathReplace" -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'

    [string]$swDecode = '-c:v h264 '
    [string]$hwDecode = '-hwaccel qsv -c:v h264_qsv '
    # 1 per type, it's a bit wasteful in a way, but it's less annoying then search/replace all the time just for the codec.
    [string]$WMVDecode1 = '-c:v wmv1 '
    [string]$WMVDecode2 = '-c:v wmv2 '
    [string]$WMVDecode3 = '-c:v wmv3 '

    [string]$swTransform = '-vf "scale=640:360" '
    [string]$hwTransform = '-vf "scale_qsv=640:360" '
    [string]$hybridTransform = '-init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" '
    # Confiig values for all WMV, cause WMV is annoying to work with
    [string]$WMVTransform = '-init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" '

    [string]$WMVEncodeVid = '-b:v 700k -c:v h264_qsv '
    [string]$WMVEncodeAud = '-c:a aac -b:a 96k '
    [string]$swEncode = '-c:v libx264 -preset superfast -b:v 700k '
    [string]$AudioEncode = ' -c:a aac -b:a 96k '
    [string]$AudioCopy = ' -c:a copy '
    # hardware encoding is currently locked to h264. Passed param handling needed, or values passed changed to ffmpeg values to allow changing it.
    [string]$hwEncode = '-c:v h264_qsv -b:v 700k '

    [string]$ffmpegcmd = ''
    [string]$inputFile = '-i "srcPathReplace" '
    # add code to adjust audio codec as needed (i.e. WMV source)
    [string]$audioCodec = '-c:a copy '
    [string]$outputFile = $audioCodec + '-y "' + $tgtPath + 'tgtPathReplace"'
    $arrStrCmd = New-Object string[] 7
    $arrStrCmd[0] = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe '
    $arrStrCmd[1] = 'Input Codec '
    $arrStrCmd[2] = 'Input File '
    $arrStrCmd[3] = 'Scaler '
    $arrStrCmd[4] = 'Encode Video Codec '
    $arrStrCmd[5] = 'Encode Audio Codec '
    $arrStrCmd[6] = 'Output File '

    # $arrStrCmd
    # 0 - Base cmd
    # 1 - decode config
    # 2 - input file
    # 3 - scaler
    # 4 - encode video config
    # 5 - encode audio config
    # 6 - output file

    # sw only, H.264 Target, superfast, 700k
    $encodeSWOnly = ' -vf "scale=640:360" -c:v libx264-b:v 700k'
    # H.264 Target, 700kbps
	#$ffmpegBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i "srcPathReplace" -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'
    $ffmpegBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe '

    # HEVC target, 600kbps
    # $ffmpegBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i "srcPathReplace" -vf "scale_qsv=640:360" -load_plugin hevc_hw -b:v 600k -c:v hevc_qsv -c:a copy -y "' + $tgtPath + 'tgtPathReplace"'

    # WMV hw accel processing:version with QSV HEVC target, AAC audio@96kbps
    # dxva2 decode, upload frames for QSV transform and encode.
    # $ffmpegWMVBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel dxva2 -i "srcPathReplace"  -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -load_plugin hevc_hw -c:v hevc_qsv -b:v 600k -c:a aac -b:a 96k -y "' + $tgtPath + 'tgtPathReplace"'

    # WMV hybrid processing:SW decode, version with QSV HEVC target, AAC audio@96kbps
    # dxva2 decode, upload frames for QSV transform and encode.
    $ffmpegWMVBase = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel dxva2 -c:v _codecReplace_ -i "srcPathReplace" -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -load_plugin hevc_hw -c:v hevc_qsv -b:v 600k -c:a aac -b:a 96k -y "' + $tgtPath + 'tgtPathReplace"'

    # WMV base (used for everything)
    # c:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v wmv3 -i input.wmv -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a aac -b:a 96k -y "output.mp4"
    #encode command is comprised of 3 pieces: decode, transform(resize), and encode.


    # The list of extensions that will be considered video files to write a statement for
    $vidExtensions = @('mkv','mp4','wmv','avi','mpg','flv','mov','vob','m4v')
    [System.IO.FileInfo]$file

    # Construct the base, filename tokenized ffmpeg command, according to whatever $mode says to use.
    # FOR LATER: figure out where to designate the output format codec. Maybe here, maybe earlier?

    #debug
    Write-Debug -Message "Cmd: $ffmpegcmd"


    # Get the top level folder
    Write-Debug -Message "Getting top level folder"
    try {
        #$tld = (Get-Item $Path | sort-object)
        $tld = Get-Item $Path
    }
    catch {
        "Unable to get Top Level Folder: $Path"
    }

    # Foreach ($item in $tld){
    #     Write-Debug $item.FullName
    # }

    # #Get-ChildItem -include ($vidExtensions) -recurse
    # # process the TLDs
    # # Write-Host "Folder Count:" $fldr
    try {
        try {
            New-Item -Force .\transcode.bat | Out-Null
            "" | Out-File .\transcode.bat -Encoding ascii -Append
        }
        catch{"Failed to create new transcode.bat"}

        If ($tld.GetType().Name -ne "DirectoryInfo"){
            Write-Host -ForegroundColor Red "$tld is not a folder. Exiting."
            Exit
        }
        # I suppose I can reasonably assume a folder at this point?
        Foreach ($thing in $tld){
            Write-Debug  -Message "Processing item: $thing"
            # if thing is folder, get files in it
            # else, process as file
            If ($thing.GetType().Name -eq "FileInfo"){
                Write-Host -ForeGroundColor Green "DEBUG:Process $thing as a file"
                $files = $thing
            }
            Else{
                Write-Host -ForeGroundColor Green ("DEBUG:Process $thing as a folder (assumed):" + $thing.GetType().Name)
                try {$files = Get-ChildItem -File -Recurse -LiteralPath $thing.FullName}
                catch {
                    Write-Host "Unable to get files from " + $thing.FullName
                    Continue
                }
            }
            Write-Host "Processing " $thing.FullName
            Foreach ($file in $files){
                Write-Host "Processing file $file"
                $fileFullName = $file.FullName.ToString()  
                Write-Debug -Message "fileFullName: $fileFullName"
                Write-Debug -Message ("fileBaseName: " + $file.BaseName)

                # Assumes a 3 character extension is present. It shouldn't matter if there isn't one.
                #$fileExt = $fileFullName.Substring((($fileFullName.Length)-3), 3)
                # save the extension.   
                #$extension = ($file.Name.ToString()).Substring(($file.Name.ToString()).lastindexofany(".")+1)
                $fileExt = ($fileFullName.Substring(($fileFullName).lastindexofany(".")+1))
                Write-Debug -Message "fileExt set to: $fileExt"
                if ($vidExtensions -match $fileExt){
                    $IsVid = $true
                }
                else {
                    $IsVid = $false
                }
                Write-Debug "Isvid? $IsVid"

                # Dynamic mode based on file extension
                switch ($fileExt){
                    "wmv"{$mode='sw'}
                    "mp4"{$mode='hw'}
                    default{$mode='sw'}
                }
                # Reset the base values based on the mode. This isn't optimal doing it here, but I kinda pooched op the process and I don't want to fix it now.
                switch ($mode){
                    "sw"{
                        # swDecode + swTransform + swEncode
                        # $ffmpegcmd = $ffmpegBase + $swDecode + $inputFile + $swTransform + $swEncode + $outputFile
                        # input codec
                        $arrStrCmd[1] = $swDecode
                        # scaling
                        $arrStrCmd[3] = $swTransform
                        # output codec
                        $arrStrCmd[4] = $swEncode
            
                    }
                    "hw"{
                        # hwDecode + hwTransform + hwEncode
                        # $ffmpegcmd = $ffmpegBase + $hwDecode + $inputFile + $hwTransform + $hwEncode + $outputFile
                        # input codec
                        $arrStrCmd[1] = $hwDecode
                        # scaling
                        $arrStrCmd[3] = $hwTransform
                        # output codec
                        $arrStrCmd[4] = $hwEncode
                    }
                    "hybrid"{
                        # swDecode + hybridTransform + hwEncode
                        # $ffmpegcmd = $ffmpegBase + $swDecode + $inputFile + $hybridTransform + $hwEncode + $outputFile
                        # input codec
                        $arrStrCmd[1] = $swDecode
                        # scaling
                        $arrStrCmd[3] = '-load_plugin hevc_hw ' + $hybridTransform
                        # output codec
                        
                        $arrStrCmd[4] = '-b:v 700k -c:v h264_qsv '
                    }
                    default{
                        # default to trying some dxva magic to enable qsv
                        # hwDecode + hwTransform + hwEncode
                        # $ffmpegcmd = $ffmpegBase + $hwDecode + $inputFile + $hwTransform + $hwEncode + $outputFile
                        # input codec   
                        $arrStrCmd[1] = '-hwaccel dxva2 -threads 1 -hwaccel_output_format dxva2_vld '
                        # scaling
                        $arrStrCmd[3] = '-vf "hwmap=derive_device=qsv,format=qsv,scale_qsv=640:360" '
                        # output codec
                        $arrStrCmd[4] = '-c:v h264_qsv -b:v 700k '
                    }
                }
                # Set the input file
                $arrStrCmd[2] = "-i ""$fileFullName"" "

                if (($IsVid) -and -not ($fileFullName -match 'sample')){
                    # Exclude files with the word 'sample' in them
                    try {
                        # Set the output file
                        #$arrStrCmd[6] = '"' + $tgtPath + $fileFullName.BaseName.ToString().Trim() + '.mp4"'
                        $arrStrCmd[6] = '"' + $tgtPath + $file.BaseName + '.mp4"'
                        $NewName = $arrStrCmd[6]
                        Write-Debug -Message "NewName: $NewName"
                    }
                    catch {
                        "Unable to set the output file name"
                    }
                    #
                    # Get the information about the file via ffprobe
                    #
                    # Generate transcode command statement, based on the file extension write it to the batch file
                    # specifically, WMVs have a different command to process with.
                    # Might add support later for HEVC or h.264 based on command line switch, for now, it's going to be hardcoding to the appropriate variable.
                    # _codecReplace_
                    # Still need handling for things that are more likely to have formats other then h.264 and wmv
                    # i.e. mpg, flv, avi, and vob

                    # look at the file, configure decode based on what ffprobe says about it.
                    $ffprobeCmd = $ffprobeBase + '"' + $fileFullName + '"'
                    Write-Debug -Message "ffprobecmd: $ffprobeCmd"
                    $srcCodec = Invoke-Expression $ffprobeCmd
                    Write-Debug -Message "srcCodec: $srcCodec"

                    switch ($srcCodec)
                    {
                        "wmv1"{
                            Write-Debug -Message "Set WMV type to 1"
                            #$transcode = $transcode -Replace "_codecReplace_", "wmv1"

                            #video in
                            $arrStrCmd[1] = $WMVDecode1
                            # audio out
                            $arrStrCmd[5] = $AudioEncode

                        }
                        "wmv2"{
                            Write-Debug -Message "Set WMV type to 2"
                            #$transcode = $transcode -Replace "_codecReplace_", "wmv2"
                            #video in
                            $arrStrCmd[1] = $WMVDecode2
                            # audio out
                            $arrStrCmd[5] = $AudioEncode
                        }
                        "wmv3"{
                            Write-Debug -Message "Set WMV type to 3"
                            #$transcode = $transcode -Replace "_codecReplace_", "wmv3"
                            #video in
                            $arrStrCmd[1] = $WMVDecode3
                            # audio out
                            $arrStrCmd[5] = $AudioEncode

                        }
                        "h264"
                        {
                            Write-Debug -Message "Processing h264"
                            # video in
                            switch ($mode){
                                "hw"{
                                    $arrStrCmd[1] = $hwDecode
                                    $arrStrCmd[5] = $AudioCopy
                                }
                                "sw"{
                                    $arrStrCmd[1] = $swDecode
                                    $arrStrCmd[5] = $AudioCopy
                                }
                                default{
                                    $arrStrCmd[1] = $hwDecode
                                    $arrStrCmd[5] = $AudioCopy
                                }
                            }
                        }
                        default
                        {
                            # cop-out case, set everything to dxva2+h264 and hope for the best?
                            Write-Debug -Message "Processing as default($srcCodec)"
                            # $transCode = $ffmpegBase -Replace "srcPathReplace", $fileFullName
                            # video in
                            $arrStrCmd[1] = $hwDecode
                            # audio out
                            $arrStrCmd[5] = $AudioCopy
                        }
                    }


                    # codec is set; write out the processing command
                    
                    # I think I can ditch this chunk if the wmv processing above works.
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
                    # $transcode = $transcode -Replace "tgtPathReplace", $NewName
                    Write-Debug -Message "Ffmpeg command:"; Write-Debug -Message "$arrStrCmd"
                    "echo Start time %TIME% for $fileFullName >> log.txt"  | out-file transcode.bat -Encoding ascii -Append
                    [system.String]::Join("", $arrStrCmd) | out-file transcode.bat -Encoding ascii -Append
                    "echo End time %TIME% for $fileFullName >> log.txt"  | out-file transcode.bat -Encoding ascii -Append
                    #$arrStrCmd | Out-File .\transcode.bat -Encoding ascii -Append
                    # /--- Old WMV Processing Code
                    # $transCodeSW | out-file transcodeSW.bat -Encoding ascii -Append
                }
                else {
                    # Vid had sample in the name, or doesn't have an allowed extension
                    Write-Host "Sample file, or extension not allowed. Skipping $fileFullName"
                    continue
                }
            }
        }
    }
    catch {
        "Folder Loop broke on $thing at line " + $_.InvocationInfo.ScriptLineNumber
        "Error is: " + $Error[0]
    }

}
function Get-FFMpeg-Cmd{
    <# .SYNOPSIS
         Generates a DOS FFmpeg command for a file passed to the script
    .DESCRIPTION
        Generates a string that is for calling ffmpeg to encode the file passed to the script. 
    
        Parameters:
        FilePath: Path to look for source videos. Not really doing anything with this right now, might not work/no support written yet.
        mode: Force* writing ffmpeg commands to use specific approaches. Modes are hw/sw/hybrid:
            hw: hardware decode, transform, and encode
            sw: sofware decode, transform, and encode
            hybrid: software decode, hardware transform and encode
            auto: dynamically determine per file, based on ffprobe result what to do. generally, hw for h264 sources, sw for anything else.
            * mode will not override behavior for specic formats, i.e. wmv will always be handled based on ffprobe results.
        encodeTo: target codec to encode video to. h264, hevc
        bitrate: target bitrate for video stream encode.
    
         Be sure to adjust variables in script as needed:
         $tgtPath - where output files are written
         $srcPath
         There are multiple base commands, to allow for different encoding parameters based on the file type.
    
    .NOTES
         Author     : Jason Coleman - pobox@chiencorp.com
        GitTest
    
    .LINK
    #>
    Param(
    [string]$file="",
    [string]$mode="",
    [string]$encodeTo="h264",
    [string]$bitrate="700k",
    [string]$SaveToPath = "\\fs2\poolroot\croco\!recodes\"
    )


    # Array that the command string is constructed in
    $arrStrCmd = New-Object string[] 7
    $arrStrCmd[0] = 'start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe '
    $arrStrCmd[1] = 'Input Codec '
    $arrStrCmd[2] = 'Input File '
    $arrStrCmd[3] = 'Scaler '
    $arrStrCmd[4] = 'Encode Video Codec '
    $arrStrCmd[5] = 'Encode Audio Codec '
    $arrStrCmd[6] = 'Output File '

    # Possible values to build commands with
    
    # Decoders
    [string]$swDecode = '-c:v h264 '
    [string]$hwDecode = '-hwaccel qsv -c:v h264_qsv '
    # 1 per type, it's a bit wasteful in a way, but it's less annoying then search/replace all the time just for the codec.
    [string]$WMVDecode1 = '-c:v wmv1 '
    [string]$WMVDecode2 = '-c:v wmv2 '
    [string]$WMVDecode3 = '-c:v wmv3 '

    # Transforms (Scaling)
    [string]$swTransform = '-vf "scale=640:360" '
    [string]$hwTransform = '-vf "scale_qsv=640:360" '
    # Hybrid is for software decode, loading decoded frames into hardware frame buffer to allow QSV transform
    [string]$hybridTransform = '-init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" '
    # Confiig values for all WMV, cause WMV is annoying to work with
    [string]$WMVTransform = '-init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" '

    # Video Encoder
    [string]$WMVEncodeVid = "-b:v $bitrate -c:v h264_qsv "
    [string]$hwEncode = '-c:v ' + $encodeTo + '_qsv -b:v $bitrate '
    [string]$swEncode = '-c:v libx264 -preset superfast -b:v $bitrate '

    # Audio Encoder
    [string]$WMVEncodeAud = '-c:a aac -b:a 96k '
    [string]$AudioEncode = ' -c:a aac -b:a 96k '
    [string]$AudioCopy = ' -c:a copy '


    # FFPRobe line used to get the video codec that the source file is encoded with.
    $ffprobeBase = 'C:\ffmpeg\ffprobe.exe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 '


    # Set default operations (decode/transform/encode) based on file name

    # Update operations if mode override has been set (i.e. force software, and/or enable h.265?)

    Write-Host "The encode command is:"
    Write-Host [system.String]::Join("", $arrStrCmd)
}
    