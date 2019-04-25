FROM logstash:7.0.0

COPY bin /usr/local/bin
COPY config /usr/share/logstash/config

RUN mv /usr/share/logstash/pipeline/logstash.conf /usr/share/logstash/pipeline/logstash.conf.example
