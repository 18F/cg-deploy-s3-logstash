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

# validate config with expected-ish args
docker run \
    --rm \
    -e AWS_SECRET_ACCESS_KEY=NOTAREALKEY \
    -e S3_REGION=us-west-2 \
    -e S3_BUCKET=some-rando-bucket \
    -e S3_PREFIX=a_prefix \
    -e ELASTICSEARCH_INDEX='logs-%{+YYYY.MM.dd}' \
    -e ELASTICSEARCH_HOSTS='host1.example.gov,host2.example.gov' \
    ${DOCKER_IMAGE} --config.test_and_exit

LOGSTASH_TEST_DOCKER_ARGS="-e LOGSTASH_READ_FROM_FILE=/logs/test.log -e LOGSTASH_STDOUT=1"
LOGSTASH_TEST_LOGSTASH_ARGS="-l /dev/null"

mkdir -p ${dir}/logs
rm ${dir}/logs/*
cp ${dir}/*.log ${dir}/logs/
for file in $(ls *.log); do
    stem=${file/%.log/}
    docker run -d -v ${dir}/logs:/logs \
        -e LOGSTASH_READ_FROM_FILE=/logs/${file} \
        -e LOGSTASH_OUT_FILE=/logs/${stem}.json \
        --name s3test-${stem} \
        ${DOCKER_IMAGE}

    # wait for logstash to finish processing, or give up after 2 minutes
    counter=0
    while [[ -e logs/${file} && ${counter} -lt 60 ]]; do
        sleep 2
        let counter+=1
    done
    docker stop s3test-${stem}
    python3 compare-json.py ${stem}-expected.json logs/${stem}.json
    #rm the container after running the tests in case you need to inspect it
    docker rm s3test-${stem}
done
