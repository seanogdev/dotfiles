function emptytrash
    for files in ~/.Trash/
        sudo rm -rdfv $files
    end
end
