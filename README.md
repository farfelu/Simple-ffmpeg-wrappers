# h264.sh
## Simple ffmpeg wrapper with various options to encode h264 videos
Because who can remember all the ffmpeg parameters?

## Dependencies
`ffmpeg`, `ffprobe`, `bc`, `getopt`, `stat`, `numfmt`

```
h264.sh -i INFILE [-s FILESIZE] [-f TIMESTAMP] [-t TIMESTAMP] [--subs] [--amix] [--noaudio] [--crop <"16:9"|"21:9"|CROPSTRING>] [--downscale] [--hls] [--seekaccurate] [--cuda] [--filter "filterstring"] [--params "parameters"] [OUTFILE]

required arguments:
-i, --input                        input file

optional arguments:
-h, --help                         print help
-s FILESIZE, --size FILESIZE       targets specific filesize in bytes. example 8M, 500k, etc.
-f TIMESTAMP, --from TIMESTAMP     timestamp [hh:]mm:ss where the video should start (hours optional)
-t TIMESTAMP, --to TIMESTAMP       timestamp [hh:]mm:ss where the video should end (hours optional)
--subs                             will burn in subtitles. Encoding time will be longer due to slower seek
--amix                             mix all audio tracks together
--noaudio                          video only, drop audio tracks
--boostaudio                       boosts audio volume
--crop                             crops to 16:9, 21:9 or to given ffmpeg cropstring
--downscale                        downscale to 720p and max 30 fps
--hls                              change output to HLS playlist with chunks
--seekaccurate                     accurate seeking (seek after input, only required on very long videos)
--cuda                             encode with nvidia cuda
--filter                           additional ffmpeg filter parameters
--params                           additional ffmpeg parameters
-o, --output                       output file. defaults to inputfile with '-d' added at the end
```

# hevc.sh
## Simple ffmpeg wrapper with various options to encode h265/hevc videos
Because who can remember all the ffmpeg parameters?

## Dependencies
`ffmpeg`, `ffprobe`, `bc`, `getopt`, `stat`, `numfmt`

```
h264.sh -i INFILE [-s FILESIZE] [-f TIMESTAMP] [-t TIMESTAMP] [--subs] [--amix] [--noaudio] [--crop <"16:9"|"21:9"|CROPSTRING>] [--downscale] [--hls] [--seekaccurate] [--cuda] [--filter "filterstring"] [--params "parameters"] [OUTFILE]

required arguments:
-i, --input                        input file

optional arguments:
-h, --help                         print help
-s FILESIZE, --size FILESIZE       targets specific filesize in bytes. example 8M, 500k, etc.
-f TIMESTAMP, --from TIMESTAMP     timestamp [hh:]mm:ss where the video should start (hours optional)
-t TIMESTAMP, --to TIMESTAMP       timestamp [hh:]mm:ss where the video should end (hours optional)
--subs                             will burn in subtitles. Encoding time will be longer due to slower seek
--amix                             mix all audio tracks together
--noaudio                          video only, drop audio tracks
--boostaudio                       boosts audio volume
--crop                             crops to 16:9, 21:9 or to given ffmpeg cropstring
--downscale                        downscale to 720p and max 30 fps
--hls                              change output to HLS playlist with chunks
--seekaccurate                     accurate seeking (seek after input, only required on very long videos)
--cuda                             encode with nvidia cuda
--filter                           additional ffmpeg filter parameters
--params                           additional ffmpeg parameters
-o, --output                       output file. defaults to inputfile with '-d' added at the end
```

# vp9.sh
## Simple ffmpeg wrapper with various options to encode vp9 videos
Because who can remember all the ffmpeg parameters?

## Dependencies
`ffmpeg`, `ffprobe`, `bc`, `getopt`, `stat`, `numfmt`

```
vp9.sh -i INFILE [-s FILESIZE] [-f TIMESTAMP] [-t TIMESTAMP] [--subs] [--amix] [--noaudio] [--crop <"16:9"|"21:9"|CROPSTRING>] [--downscale] [--seekaccurate] [--filter "filterstring"] [--params "parameters"] [OUTFILE]

required arguments:
-i, --input                        input file

optional arguments:
-h, --help                         print help
-s FILESIZE, --size FILESIZE       targets specific filesize in bytes. example 8M, 500k, etc.
-f TIMESTAMP, --from TIMESTAMP     timestamp [hh:]mm:ss where the video should start (hours optional)
-t TIMESTAMP, --to TIMESTAMP       timestamp [hh:]mm:ss where the video should end (hours optional)
--subs                             will burn in subtitles. Encoding time will be longer due to slower seek
--amix                             mix all audio tracks together
--noaudio                          video only, drop audio tracks
--boostaudio                       boosts audio volume
--crop                             crops to 16:9, 21:9 or to given ffmpeg cropstring
--downscale                        downscale to 720p and max 30 fps
--seekaccurate                     accurate seeking (seek after input, only required on very long videos)
--filter                           additional ffmpeg filter parameters
--params                           additional ffmpeg parameters
-o, --output                       output file. defaults to inputfile with '-d' added at the end
```

# av1.sh
## Simple ffmpeg wrapper with various options to encode AV1 videos
Because who can remember all the ffmpeg parameters?

## Dependencies
`ffmpeg`, `ffprobe`, `bc`, `getopt`, `stat`, `numfmt`

```
av1.sh -i INFILE [-s FILESIZE] [-f TIMESTAMP] [-t TIMESTAMP] [--subs] [--amix] [--noaudio] [--crop <"16:9"|"21:9"|CROPSTRING>] [--downscale] [--seekaccurate] [--filter "filterstring"] [--params "parameters"] [OUTFILE]

required arguments:
-i, --input                        input file

optional arguments:
-h, --help                         print help
-s FILESIZE, --size FILESIZE       targets specific filesize in bytes. example 8M, 500k, etc.
-f TIMESTAMP, --from TIMESTAMP     timestamp [hh:]mm:ss where the video should start (hours optional)
-t TIMESTAMP, --to TIMESTAMP       timestamp [hh:]mm:ss where the video should end (hours optional)
--subs                             will burn in subtitles. Encoding time will be longer due to slower seek
--amix                             mix all audio tracks together
--noaudio                          video only, drop audio tracks
--boostaudio                       boosts audio volume
--crop                             crops to 16:9, 21:9 or to given ffmpeg cropstring
--downscale                        downscale to 720p and max 30 fps
--seekaccurate                     accurate seeking (seek after input, only required on very long videos)
--filter                           additional ffmpeg filter parameters
--params                           additional ffmpeg parameters
-o, --output                       output file. defaults to inputfile with '-d' added at the end
```
