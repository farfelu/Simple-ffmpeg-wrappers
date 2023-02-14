#!/bin/bash

# from https://stackoverflow.com/a/29754866

# More safety, by turning some bugs into errors.
# Without `errexit` you don't need ! and can replace
# PIPESTATUS with a simple $?, but I don't do that.
set -o errexit -o pipefail -o noclobber -o nounset

# -allow a command to fail with !'s side effect on errexit
# -use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo 'I''m sorry, `getopt --test` failed in this environment.'
    exit 1
fi


show_help() {
    echo "${0##*/} -i INFILE [-s FILESIZE] [-f TIMESTAMP] [-t TIMESTAMP] [--subs] [--amix] [--noaudio] [--crop <\"16:9\"|\"21:9\"|CROPSTRING>] [--downscale] [--hls] [--seekaccurate] [--cuda] [--filter \"filterstring\"] [--params \"parameters\"] [OUTFILE]"
    echo
    echo "required arguments:"
    echo "-i, --input                        input file"
    echo
    echo "optional arguments:"
    echo "-h, --help                         print help"
    echo "-s FILESIZE, --size FILESIZE       targets specific filesize in bytes. example 8M, 500k, etc."
    echo "-f TIMESTAMP, --from TIMESTAMP     timestamp [hh:]mm:ss where the video should start (hours optional)"
    echo "-t TIMESTAMP, --to TIMESTAMP       timestamp [hh:]mm:ss where the video should end (hours optional)"
    echo "--subs                             will burn in subtitles. Encoding time will be longer due to slower seek"
    echo "--amix                             mix all audio tracks together"
    echo "--noaudio                          video only, drop audio tracks"
    echo "--boostaudio                       boosts audio volume"
    echo "--crop                             crops to 16:9, 21:9 or to given ffmpeg cropstring"
    echo "--downscale                        downscale to 720p and max 30 fps"
    echo "--hls                              change output to HLS playlist with chunks"
    echo "--seekaccurate                     accurate seeking (seek after input)"
    echo "--cuda                             encode with nvidia cuda"
    echo "--filter                           additional ffmpeg filter parameters"
    echo "--params                           additional ffmpeg parameters"
    echo "-o, --output                       output file. defaults to inputfile with '-d' added at the end"
}

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi

OPTIONS=s:f:t:o:i:h
LONGOPTS=size:,from:,to:,output:,input:,help,subs,amix,noaudio,boostaudio,crop:,hls,seekaccurate,cuda,filter:,params:,downscale

# -regarding ! and PIPESTATUS see above
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt's output this way to handle the quoting right:
eval set -- "$PARSED"

psize=
pfrom=
pto=
psubs=
pamix=
pnoaudio=
pboostaudio=
pcrop=
pdownscale=
pfilter=
poutput=
pinput=
phls=
pseekaccurate=
pcuda=
pparams=

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -s|--size)
            psize="$2"
            shift 2
            ;;
        -f|--from)
            pfrom="$2"
            shift 2
            ;;
        -t|--to)
            pto="$2"
            shift 2
            ;;
        --subs)
            psubs=y
            shift
            ;;
        --amix)
            pamix=y
            shift
            ;;
        --noaudio)
            pnoaudio=y
            shift
            ;;
        --boostaudio)
            pboostaudio=y
            shift
            ;;
        --crop)
            pcrop="$2"
            shift 2
            ;;
        --downscale)
            pdownscale=y
            shift
            ;;
        --hls)
            phls=y
            shift
            ;;
        --seekaccurate)
            pseekaccurate=y
            shift
            ;;
        --cuda)
            pcuda=y
            shift
            ;;
        --filter)
            pfilter="$2"
            shift 2
            ;;
        --params)
            pparams="$2"
            shift 2
            ;;
        -o|--output)
            poutput="$2"
            shift 2
            ;;
        -i|--input)
            pinput="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

# handle non-option arguments

if [[ -z "$pinput" ]]; then
    echo "No input file specified."
    exit 4
fi

if [[ ! -f "$pinput" ]]; then
    echo "File $pinput does not exist or cannot be read"
    exit 1
fi

ffmpeg_ss=""
ffmpeg_ssaccurate=""
ffmpeg_to=""
ffmpeg_filter="setsar=1:1"
ffmpeg_input="$pinput"
ffmpeg_output="${ffmpeg_input%.*}-d"
ffmpeg_filter_complex=""
ffmpeg_skip_audio=""
ffmpeg_boost_audio=""
ffmpeg_extra_params="$pparams"

todiff=0
ssseconds=0

if [[ -n "$poutput" ]]; then
    ffmpeg_output="${poutput%.*}"
elif [[ $# -eq 1 ]]; then
    ffmpeg_output="$1"
    ffmpeg_output="${ffmpeg_output%.*}"
fi

if [[ -n "$pfrom" ]]; then
    OLDIFS=$IFS
    IFS=: read -r h m s <<< "$pfrom"
    IFS=$OLDIFS
    if [ -z "$s" ]; then
        s=$m
        m=$h
        h=0
    fi
    ssseconds=$(echo "$h * 60 * 60 + $m * 60 + $s" | bc)
    ffmpeg_ss="-ss $ssseconds"
fi

if [[ -n "$pto" ]]; then
    OLDIFS=$IFS
    IFS=: read -r h m s <<< "$pto"
    IFS=$OLDIFS
    if [ -z "$s" ]; then
        s=$m
        m=$h
        h=0
    fi
    toseconds=$(echo "$h * 60 * 60 + $m * 60 + $s" | bc)
    todiff=$(echo "$toseconds - $ssseconds" | bc)
    ffmpeg_to="-t $todiff"
fi

if [[ -n "$pseekaccurate" || -n "$psubs" ]]; then
    ffmpeg_ssaccurate="$ffmpeg_ss"
    ffmpeg_ss=""
fi

if [[ -n "$psubs" ]]; then
    ffmpeg_filter="$ffmpeg_filter,subtitles=\'$ffmpeg_input\'"
fi

source_framerate=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$ffmpeg_input")
source_framerate=$(bc <<< "scale=3;$source_framerate")
if [[ -n "$pdownscale" ]]; then
    max_framerate=30
    ffmpeg_filter="scale='bitand(oh*dar,65534):trunc(min(720,ih)/2)*2',$ffmpeg_filter"
    if  [[ $(bc -l <<< "$source_framerate > $max_framerate") -eq 1 ]]; then
        source_framerate=$max_framerate
        ffmpeg_filter="fps=fps=$max_framerate,$ffmpeg_filter"
    fi
fi

if [[ $pcrop == "16:9" ]]; then
    ffmpeg_filter="crop=ih*16/9:ih,$ffmpeg_filter"
elif [[ $pcrop == "21:9" ]]; then
    ffmpeg_filter="crop=ih*21/9:ih,$ffmpeg_filter"
elif [[ -n "$pcrop" ]]; then
    ffmpeg_filter="crop=$pcrop,$ffmpeg_filter"
fi

if [[ -n "$pamix" ]]; then
    audiostream_num=$(ffprobe -loglevel error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$ffmpeg_input" | wc -l)
    ffmpeg_filter_complex="-filter_complex \"amixinputs=$audiostream_num:longest\""
    # merge two tracks: [0:a:0][0:a:1]amix=2:longest[aout]
    # to boost second one: add after longest -> :weights=1 2
fi

if [[ -n "$pnoaudio" ]]; then
    ffmpeg_skip_audio="-an"
fi

if [[ -n "$pboostaudio" ]]; then
    ffmpeg_boost_audio="-filter:a volume=4.0"
fi

if [[ -n "$pfilter" ]]; then
    ffmpeg_filter="$pfilter,$ffmpeg_filter"
fi

globalopts=()
x264opts=("-c:v" "libx264" "-preset" "veryslow" "-pix_fmt" "yuv420p")
cudaopts=("-c:v" "h264_nvenc" "-profile:v" "high" "-pixel_format" "yuv420p" "-preset:v" "p7" "-tune:v" "hq")

if [[ -n "$phls" ]] || [[ -n "$psize" ]]; then

    if [[ -n "$psize" ]]; then
        # ffmpeg bitrate constrained
        # calculate best bitrate given the filesize

        cudaopts=("-2pass" "true")

        target_video_size_bytes=`numfmt --from=iec ${psize^^}`

        if [[ -n "$pto" ]]; then
            origin_duration_s=$todiff
        else
            origin_duration_s=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 "$ffmpeg_input")
            origin_duration_s=$(bc <<< "$origin_duration_s - $ssseconds")
        fi

        #origin_audio_bitrate_kbit_s=$(ffprobe -v error -pretty -show_streams -select_streams a "$ffmpeg_input" | grep -Po "(?<=^bit_rate\=)\d*\.\d*")
        target_audio_bitrate_kbit_s=128 #$origin_audio_bitrate_kbit_s # TODO for now, make audio bitrate the same

        if [[ -n "$pnoaudio" ]]; then
            target_audio_bitrate_kbit_s=0
        fi

        target_video_bitrate_kbit_s=$(\
            awk \
            -v size="$target_video_size_bytes" \
            -v duration="$origin_duration_s" \
            -v audio_rate="$target_audio_bitrate_kbit_s" \
            'BEGIN { print  ( ( (size / 1024.0 / 1024.0) * 8192.0 ) / ( 1.048576 * duration ) - audio_rate ) }')



        if [[ -n "$pdownscale" ]] && [[ -z "$phls" ]]; then
            if (( $(bc <<< "$target_video_bitrate_kbit_s > 2000") )); then
                echo "target bitrate $target_video_bitrate_kbit_s too high, will clamp to 2000"
                target_video_bitrate_kbit_s=2000
            fi
        fi

        if (( $(bc <<< "$target_video_bitrate_kbit_s < 1") )); then
            echo "target size of $psize bytes impossible for a $origin_duration_s second video"
            exit 1
        fi
    else # default bitrate for HLS
        target_audio_bitrate_kbit_s=128
        target_video_bitrate_kbit_s=3000
    fi

    pass1_flags=()
    pass2_flags=()
    output_filename=("${ffmpeg_output}.mp4")

    if [[ -n "$phls" ]]; then
        hls_dir=${ffmpeg_output//[[:blank:]]/}
        chunk_time=6
        min_iframe=$(bc <<< "scale=3;$source_framerate * 2")
        globalopts+=("-maxrate:v" "${target_video_bitrate_kbit_s}k")
        globalopts+=("-minrate:v" "2M")
        globalopts+=("-bufsize:v" "6M")
        globalopts+=("-g" "$min_iframe")
        globalopts+=("-sc_threshold" "0")
        globalopts+=("-keyint_min" "$min_iframe")
        pass1_flags+=("-f" "mpegts")
        pass2_flags+=("-f" "hls")
        pass2_flags+=("-hls_time" "$chunk_time")
        pass2_flags+=("-hls_playlist_type" "vod")
        pass2_flags+=("-hls_flags" "independent_segments")
        pass2_flags+=("-hls_segment_type" "mpegts")
        pass2_flags+=("-hls_segment_filename" "%v/segment-%04d.ts")
        pass2_flags+=("-var_stream_map" "v:0,a:0,name:$hls_dir")
        pass2_flags+=("-master_pl_name" "${ffmpeg_output}.m3u8")
        output_filename=("%v/playlist.m3u8")
    else
        globalopts+=("-f" "mp4")
        globalopts+=("-movflags")
        globalopts+=("+faststart")
    fi


    if [[ -n "$pcuda" ]]; then
        ffmpeg \
            -y \
            $ffmpeg_ss \
            -i "$ffmpeg_input" \
            $ffmpeg_extra_params \
            $ffmpeg_ssaccurate \
            $ffmpeg_to \
            -vf "$ffmpeg_filter" \
            $ffmpeg_filter_complex \
            "${globalopts[@]}" \
            "${cudaopts[@]}" \
            -b:v "$target_video_bitrate_kbit_s"k \
            $ffmpeg_skip_audio \
            $ffmpeg_boost_audio \
            -c:a aac \
            -b:a "$target_audio_bitrate_kbit_s"k \
            -ar 44100 \
            -ac 2 \
            "${output_flags[@]}" \
            "${pass2_flags[@]}" \
            "${output_filename[@]}"
    else
        ffmpeg \
            -y \
            $ffmpeg_ss \
            -i "$ffmpeg_input" \
            $ffmpeg_extra_params \
            $ffmpeg_ssaccurate \
            $ffmpeg_to \
            -vf "$ffmpeg_filter" \
            $ffmpeg_filter_complex \
            "${globalopts[@]}" \
            "${x264opts[@]}" \
            -b:v "$target_video_bitrate_kbit_s"k \
            -pass 1 \
            -an \
            "${output_flags[@]}" \
            "${pass1_flags[@]}" \
            /dev/null \
        && ffmpeg \
            -y \
            $ffmpeg_ss \
            -i "$ffmpeg_input" \
            $ffmpeg_extra_params \
            $ffmpeg_ssaccurate \
            $ffmpeg_to \
            -vf "$ffmpeg_filter" \
            $ffmpeg_filter_complex \
            "${globalopts[@]}" \
            "${x264opts[@]}" \
            -b:v "$target_video_bitrate_kbit_s"k \
            -pass 2 \
            $ffmpeg_skip_audio \
            $ffmpeg_boost_audio \
            -c:a aac \
            -b:a "$target_audio_bitrate_kbit_s"k \
            -ar 44100 \
            -ac 2 \
            "${output_flags[@]}" \
            "${pass2_flags[@]}" \
            "${output_filename[@]}"

            rm ffmpeg2pass-0.log > /dev/null
            rm ffmpeg2pass-0.log.mbtree > /dev/null
    fi

    echo Target Bitrate: $target_video_bitrate_kbit_s

    if [[ -z "$phls" ]]; then
        echo Before: `stat --printf="%s" "$ffmpeg_input" | numfmt --to=iec` After: `stat --printf="%s" "${ffmpeg_output}.mp4" | numfmt --to=iec`
    fi
else
    #ffmpeg crf 21

    cudaopts+=("-rc:v" "vbr")
    cudaopts+=("-cq:v" "24")
    cudaopts+=("-b:v" "0")

    x264opts+=("-crf" "21")

    globalopts+=("-f" "mp4")
    globalopts+=("-movflags")
    globalopts+=("+faststart")
    globalopts+=("-c:a" "aac")
    globalopts+=("-b:a" "128k")
    globalopts+=("-ar" "44100")
    globalopts+=("-ac" "2")

    if [[ -n "$pcuda" ]]; then
        ffmpeg \
            -y \
            $ffmpeg_ss \
            -i "$ffmpeg_input" \
            $ffmpeg_extra_params \
            $ffmpeg_ssaccurate \
            $ffmpeg_to \
            -vf "$ffmpeg_filter" \
            $ffmpeg_filter_complex \
            "${globalopts[@]}" \
            "${cudaopts[@]}" \
            $ffmpeg_skip_audio \
            $ffmpeg_boost_audio \
            "${ffmpeg_output}.mp4"
    else
        ffmpeg \
            -y \
            $ffmpeg_ss \
            -i "$ffmpeg_input" \
            $ffmpeg_extra_params \
            $ffmpeg_ssaccurate \
            $ffmpeg_to \
            -vf "$ffmpeg_filter" \
            $ffmpeg_filter_complex \
            "${globalopts[@]}" \
            "${x264opts[@]}" \
            $ffmpeg_skip_audio \
            $ffmpeg_boost_audio \
            "${ffmpeg_output}.mp4"
    fi

    echo Target Quality: CRF 21
    echo Before: `stat --printf="%s" "$ffmpeg_input" | numfmt --to=iec` After: `stat --printf="%s" "${ffmpeg_output}.mp4" | numfmt --to=iec`
fi
