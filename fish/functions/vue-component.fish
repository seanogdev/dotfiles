function vue-component --description 'Scaffold a Vue component'
    if [ -z "$argv" ]
        echo "No arguments supplied"
        return
    else
        mkd $argv
        touch $argv.{vue,js,scss}
        cd ../
    end
end
