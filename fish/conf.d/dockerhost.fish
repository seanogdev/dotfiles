if type -f docker
    # docker context use colima;
    set -gx DOCKER_HOST unix://$HOME/.colima/default/docker.sock;
end

