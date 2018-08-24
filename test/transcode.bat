time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\mkv1\file\mkvtest1.mkv -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy "\\fs2\poolroot\croco\!recodes\mkv1.mp4"
time /t
time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\mp4file\file\mp4test.mp4 -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy "\\fs2\poolroot\croco\!recodes\mp4file.mp4"
time /t
time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\wmv1\file\test.mp4 -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy "\\fs2\poolroot\croco\!recodes\wmv1.mp4"
time /t
time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c v:wmv1 -i C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\wmv1\file\wmv1_test.wmv -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a aac -b:a 96k "\\fs2\poolroot\croco\!recodes\wmv1.mp4"
time /t
time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c v:wmv2 -i C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\wmv2\file\wmv2_test.wmv -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a aac -b:a 96k "\\fs2\poolroot\croco\!recodes\wmv2.mp4"
time /t
time /t
start /belownormal /WAIT C:\ffmpeg\ffmpeg.exe -hwaccel qsv -c:v h264_qsv -i C:\Users\j.coleman\OneDrive\GitHub\FFMpeg-Batch-Generator\test\wmv3\wmv3_test.wmv -vf "scale_qsv=640:360" -b:v 700k -c:v h264_qsv -c:a copy "\\fs2\poolroot\croco\!recodes\wmv3.mp4"
time /t
