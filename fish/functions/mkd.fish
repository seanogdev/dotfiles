function mkd --description 'Create a new directory and navigate to it'
    if [ -z "$argv" ]
        echo "No arguments supplied"
        return
    else
        mkdir -p $argv
        cd $argv
    end
end
