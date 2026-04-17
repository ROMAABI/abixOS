function ani
    if test (count $argv) -lt 2
        echo "Usage: ani <anime|shortcut> <episode|range> [--dub]"
        echo "  e.g. ani vs 1-5"
        echo "  e.g. ani vinland saga 1-5"
        echo "  e.g. ani vs 1-5 --dub"
        return 1
    end

    set dub_flag ""
    if contains -- "--dub" $argv
        set dub_flag "--dub"
        set argv (string match -v -- "--dub" $argv)
    end

    set range $argv[-1]
    set shortcut (string join " " $argv[1..-2])

    switch $shortcut
        case jjk;    set anime "Jujutsu Kaisen"
        case vs;     set anime "Vinland Saga"
        case naruto; set anime "Naruto Shippuden"
        case op;     set anime "One Piece"
        case aot;    set anime "Attack on Titan"
        case '*';    set anime $shortcut
    end

    set anime_dir (string replace -a " " "_" $anime)
    set base_path "/home/spix/Anime/$anime_dir"
    mkdir -p $base_path

    echo "===> Downloading $anime Episodes $range $dub_flag..."
    if test -n "$dub_flag"
        ani-cli -d $dub_flag "$anime" -e $range
    else
        ani-cli -d "$anime" -e $range
    end

    for file in (find "$HOME" -maxdepth 1 -name "$anime*Episode*.mp4" 2>/dev/null)
        set filename (basename $file)
        set ep_num (string replace -ri '.*Episode ([0-9]+).*' '$1' $filename)
        set season_num (string replace -ri '.*[Ss]eason[[:space:]]*([0-9]+).*' '$1' $filename)

        if test -n "$season_num"
            and string match -qr '^[0-9]+$' $season_num
            set season "season_$season_num"
        else
            set season "season_1"
        end

        mkdir -p "$base_path/$season"
        set ep_padded (printf "%02d" $ep_num)
        mv "$file" "$base_path/$season/$anime - Episode $ep_padded.mp4"
        echo "===> Saved: $base_path/$season/$anime - Episode $ep_padded.mp4"
    end
end
