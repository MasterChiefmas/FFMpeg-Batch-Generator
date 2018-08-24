time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel dxva2 -c:v _codecReplace_ -i "C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\fldr2\file\randomfile2.wmv" -init_hw_device qsv=qsv:MFX_IMPL_hw_any -filter_hw_device qsv -vf "format=nv12,hwupload=extra_hw_frames=75,scale_qsv=640:360" -load_plugin hevc_hw -c:v hevc_qsv -b:v 600k -c:a aac -b:a 96k -y "\\fs2\poolroot\croco\!recodes\fldr2.mp4"
time /t
