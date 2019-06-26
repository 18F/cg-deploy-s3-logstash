#!/bin/bash -ex
mkdir -p generated-manifest
echo <<EOF
---
applications:
  - name: s3-logstash-ingestor
    instances: 1
    docker:
      image: 18fgsa/s3-logstash:`cat $1`
    no-route: true
    memory: 1G
    timeout: 18

EOF > generated-manifest/manifest.yml
