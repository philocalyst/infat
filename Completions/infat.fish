function __infat_file_extensions
    find . -type f -name "*.*" 2>/dev/null | sed 's/.*\.//' | sort -u
end

function __infat_macos_applications
    find /Applications /System/Applications ~/Applications -maxdepth 1 -name "*.app" 2>/dev/null | sed 's/.*\///;s/\.app$//' | sort -u
end

# Main command completions
complete -c infat -f
complete -c infat -n __fish_use_subcommand -s c -l config -d "Path to the configuration file" -r
complete -c infat -n __fish_use_subcommand -s v -l verbose -d "Enable verbose logging"
complete -c infat -n __fish_use_subcommand -s q -l quiet -d "Quiet output"
complete -c infat -n __fish_use_subcommand -s h -l help -d "Show help"
complete -c infat -n __fish_use_subcommand -l version -d "Show version"

# Subcommand completions
complete -c infat -n __fish_use_subcommand -a list -d "Lists information for a given filetype"
complete -c infat -n __fish_use_subcommand -a set -d "Sets an application association"
complete -c infat -n __fish_use_subcommand -a info -d "Displays system information"

# 'list' subcommand
complete -c infat -n "__fish_seen_subcommand_from list" -s a -l assigned -d "List all assigned apps for type"
complete -c infat -n "__fish_seen_subcommand_from list" -s h -l help -d "Show help"
complete -c infat -n "__fish_seen_subcommand_from list" -a "(__infat_file_extensions)"

# 'set' subcommand
complete -c infat -n "__fish_seen_subcommand_from set; and not __fish_seen_subcommand_from (__infat_macos_applications)" -a "(__infat_macos_applications)" -d Application

# After application name, suggest file extensions
complete -c infat -n "begin; 
    __fish_seen_subcommand_from set; 
    and test (count (commandline -opc)) -eq 3;
end" -a "(__infat_file_extensions)" -d "File type"

# 'info' subcommand
complete -c infat -n "__fish_seen_subcommand_from info" -s h -l help -d "Show help"
