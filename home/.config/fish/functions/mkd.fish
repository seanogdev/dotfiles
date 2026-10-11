function mkd --description 'Create a new directory and navigate to it'
    if [ -z "$argv" ]
        echo "No arguments supplied"
    else
        if [ -d "$argv" ]
            echo "Directory already exists, cd'ing into it"
            cd "$argv"
        else
            mkdir "$argv"
            cd "$argv"
        end
    end
end
