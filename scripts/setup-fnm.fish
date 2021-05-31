set -l fnmVersions 14.16 12.18.3

if not type -q fnm
  exit
end

for fnmVersion in $fnmVersions
  fnm install $fnmVersion
end

echo "Settings default FNM version to $fnmVersions[1]"
fnm default $fnmVersions[1]
fnm list
