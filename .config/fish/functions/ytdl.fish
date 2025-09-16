function ytdl --description 'Download best quality youtube video'
    yt-dlp -i -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]" --merge-output-format mp4 -o "~/Downloads" $argv
end

function ytdl-audio --description 'Download best quality youtube video (audio-only)'
    yt-dlp -i -f "bestaudio[ext=m4a]" -o "~/Downloads" $argv
end
