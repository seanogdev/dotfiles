function dedupe-open-with --description "Remove duplicate entries from the Open With menu"
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user;
    killall Finder;
end