if status is-interactive
# Commands to run in interactive sessions can go here

# Add local bin to PATH
if not contains "$HOME/.local/bin" $PATH
    set -gx PATH $HOME/.local/bin $PATH
end
end 
fastfetch

function ani
    if test (count $argv) -lt 2
        echo "Usage: ani <anime|shortcut> <episode|range>"
        echo "  e.g. ani vs 1-5"
        echo "  e.g. ani vinland saga 1-5"
        return 1
    end

    set range $argv[-1]
    set shortcut (string join " " $argv[1..-2])

    switch $shortcut
        case jjk;    set anime "Jujutsu Kaisen"
        case vs;     set anime "Vinland Saga"
        case naruto; set anime "Naruto Shippuden"
        case op;     set anime "One Piece"
        case aot;    set anime "Attack on Titan"
        case '*';    set anime (echo $shortcut | sed 's/\b\(.\)/\u\1/g')
    end

    set anime_dir (string replace -a " " "_" $anime)
    set base_path "$HOME/Anime/$anime_dir"
    mkdir -p $base_path

    set start (string split "-" $range)[1]
    set end   (string split "-" $range)[2]
    test -z "$end"; and set end $start

    echo "===> Searching '$anime'..."
    echo "===> ani-cli shows latest season first (result 1 = newest)"
    read -P "===> How many total results are shown: " total
    read -P "===> Enter season number (1=oldest): " season_input
    set result_num (math $total - $season_input + 1)
    echo "===> Selecting result $result_num..."

    for ep in (seq $start $end)
        echo "===> Downloading $anime Episode $ep (dub)..."
        ani-cli -d --dub -S $result_num "$anime" -e $ep

        set file (find "$HOME" -maxdepth 1 -name "$anime*Episode $ep.mp4" 2>/dev/null | head -n 1)
        if test -z "$file"
            echo "Error: File not found for episode $ep"
            continue
        end

        set filename (basename $file)
        set season_num (string replace -ri '.*[Ss]eason[[:space:]]*([0-9]+).*' '$1' $filename)
        if test -n "$season_num"
            and string match -qr '^[0-9]+$' $season_num
            set season "season_$season_num"
        else
            set season "season_1"
        end

        mkdir -p "$base_path/$season"
        set ep_padded (printf "%02d" $ep)
        mv "$file" "$base_path/$season/$anime - Episode $ep_padded.mp4"
        echo "===> Saved: $base_path/$season/$anime - Episode $ep_padded.mp4"
    end
end
