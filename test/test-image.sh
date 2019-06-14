#!/bin/bash -e

help () {
    cat <<EOF
Test the logstash-s3 docker container. 
Usage: logstash-s3 -h | CONTAINER

-h        : show this help and exit
CONTAINER : the name of the container to be tested,
            Can be the string "build" to build and test container
EOF
}
if [[ $# -ne 1 ]]; then
    help
    exit 1
fi

if  [[ "$1" =~ ^-{0,2}h(elp)?$ ]]; then
    help
    exit 0
fi

DOCKER_IMAGE=$1

dir=$(dirname ${BASH_SOURCE[0]})
pushd ${dir}
dir=$(pwd)
popd

if [[ ${DOCKER_IMAGE} == 'build' ]]; then
    DOCKER_IMAGE=local/logstash-s3
    docker build -t ${DOCKER_IMAGE} ${dir}/../docker/
fi

if [[ -z ${VIRTUAL_ENV} ]]; then
    python3 -m venv venv
    . venv/bin/activate
    pip install pytest
fi

pytest --image ${DOCKER_IMAGE}
