function _swift_infat_using_command
    set -l cmd (commandline -opc)
    if [ (count $cmd) -eq (count $argv) ]
        for i in (seq (count $argv))
            if [ $cmd[$i] != $argv[$i] ]
                return 1
            end
        end
        return 0
    end
    return 1
end
complete -c infat -n '_swift_infat_using_command infat' -f -r -s c -l config -d 'Path to the configuration file.'
complete -c infat -n '_swift_infat_using_command infat' -f -s v -l verbose -d 'Enable verbose logging.'
complete -c infat -n '_swift_infat_using_command infat' -f -s q -l quiet -d 'Quiet output.'
complete -c infat -n '_swift_infat_using_command infat' -f -l version -d 'Show the version.'
complete -c infat -n '_swift_infat_using_command infat' -f -s h -l help -d 'Show help information.'
complete -c infat -n '_swift_infat_using_command infat' -f -a info -d 'Lists file association information.'
complete -c infat -n '_swift_infat_using_command infat' -f -a set -d 'Sets an application association.'
complete -c infat -n '_swift_infat_using_command infat' -f -a help -d 'Show subcommand help information.'
complete -c infat -n '_swift_infat_using_command infat info' -f -r -s a -l app -d 'Application name (e.g., \'Google Chrome\').'
complete -c infat -n '_swift_infat_using_command infat info' -f -r -s e -l ext -d 'File extension (without the dot, e.g., \'html\').'
complete -c infat -n '_swift_infat_using_command infat info' -f -r -s t -l type -d 'File type (e.g., text).'
complete -c infat -n '_swift_infat_using_command infat info -t' -f -k -a 'plain-text text csv image raw-image audio video movie mp4-audio quicktime mp4-movie archive sourcecode c-source cpp-source objc-source shell makefile data directory folder symlink executable unix-executable app-bundle'
complete -c infat -n '_swift_infat_using_command infat info --type' -f -k -a 'plain-text text csv image raw-image audio video movie mp4-audio quicktime mp4-movie archive sourcecode c-source cpp-source objc-source shell makefile data directory folder symlink executable unix-executable app-bundle'
complete -c infat -n '_swift_infat_using_command infat info' -f -s h -l help -d 'Show help information.'
complete -c infat -n '_swift_infat_using_command infat set' -f -r -l ext -d 'A file extension without leading dot.'
complete -c infat -n '_swift_infat_using_command infat set' -f -r -l scheme -d 'A URL scheme. ex: mailto.'
complete -c infat -n '_swift_infat_using_command infat set' -f -r -l type -d 'A file class. ex: image'
complete -c infat -n '_swift_infat_using_command infat set --type' -f -k -a 'plain-text text csv image raw-image audio video movie mp4-audio quicktime mp4-movie archive sourcecode c-source cpp-source objc-source shell makefile data directory folder symlink executable unix-executable app-bundle'
complete -c infat -n '_swift_infat_using_command infat set' -f -s h -l help -d 'Show help information.'
