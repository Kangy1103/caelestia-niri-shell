#!/usr/bin/env fish
# Convert all .mp3 files in assets/sounds/ and subdirs to .wav, then delete originals

set dir (dirname (status filename))
for mp3 in (find "$dir" -name "*.mp3")
    set wav (string replace ".mp3" ".wav" "$mp3")
    echo "Converting: $mp3 -> $wav"
    ffmpeg -i "$mp3" -y "$wav" 2>&1 | tail -1
    if test $pipestatus[1] -eq 0
        rm "$mp3"
        echo "  Deleted: $mp3"
    end
end
echo "Done."
