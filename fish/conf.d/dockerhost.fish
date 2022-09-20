if type -f docker
    set -gx DOCKER_HOST (docker context inspect --format '{{.Endpoints.docker.Host}}')
end

