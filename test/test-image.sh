#!/bin/bash -ex

DOCKER_IMAGE=${1:-18f/logstash-s3}

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
