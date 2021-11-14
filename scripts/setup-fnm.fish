set -l fnmVersions 14 16

if not type -q fnm
    exit
end

for fnmVersion in $fnmVersions
    fnm install $fnmVersion
end

echo "Settings default FNM version to $fnmVersions[0]"
fnm default $fnmVersions[0]
fnm list
