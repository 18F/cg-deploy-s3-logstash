#!/bin/bash -ex
echo <<EOF > generated-manifest/manifest.yml
---
applications:
  - name: s3-logstash-ingestor
    instances: 1
    docker:
      image: 18fgsa/s3-logstash:`cat $1`
    no-route: true
    memory: 1G
    timeout: 18

EOF
