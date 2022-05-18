#! /usr/bin/env fish

set -l fnmVersions 14.16.1 16
set -l defaultFnmVersion $fnmVersions[1]

if not type -q fnm
    exit
end

for fnmVersion in $fnmVersions
    fnm install $fnmVersion
end

echo "Settings default FNM version to $defaultFnmVersion"
fnm default $defaultFnmVersion
