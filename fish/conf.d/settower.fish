set -gx TOWER_PLIST_PATH "$HOME/Library/Application Support/com.fournova.Tower3/environment.plist"
rm -f $TOWER_PLIST_PATH
echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN\" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>PATH</key><string>'(echo $PATH)'</string></dict></plist>' > $TOWER_PLIST_PATH
