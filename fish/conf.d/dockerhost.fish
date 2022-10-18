if type -f docker
    docker context use colima;
    set -gx DOCKER_HOST (docker context inspect --format '{{.Endpoints.docker.Host}}');
end

