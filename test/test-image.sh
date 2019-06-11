#!/bin/bash -ex

DOCKER_IMAGE=${1:-18f/logstash-s3}
# validate config with expected-ish args
docker run \
    -e AWS_SECRET_ACCESS_KEY=NOTAREALKEY \
    -e S3_REGION=us-west-2 \
    -e S3_BUCKET=some-rando-bucket \
    -e S3_PREFIX=a_prefix \
    -e ELASTICSEARCH_INDEX='logs-%{+YYYY.MM.dd}' \
    -e ELASTICSEARCH_HOSTS='host1.example.gov,host2.example.gov' \
    ${DOCKER_IMAGE} --config.test_and_exit
