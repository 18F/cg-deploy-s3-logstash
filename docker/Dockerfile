FROM logstash:7.1.1 as builder
# Story time:
#   - logstash:7.x.x has EXPOSE 5044 9600
#   - having 2 ports exposed on a docker container confuses CF. 
#   - docker does not have a way to override an upstream's EXPOSE (despite 
#     having an issue open about it since 2013)
# so what we're doing here is abusing the mutistage build system to make the 
# upstream Logstash build do all the heavy lifting. 
# The goal here is that this is easier than maintaining a fork, but that 
# could be wrong ¯\_(ツ)_/¯


# the same base image as logstash:7 uses
FROM centos:7

# this is where all the goodies are in the upstream
COPY --from=builder --chown=1000 /usr/share/logstash /usr/share/logstash

# this is the stuff we built
COPY bin /usr/local/bin
COPY config /usr/share/logstash/config
# get their conf out of the way, but keep it around for reference
RUN mv /usr/share/logstash/pipeline/logstash.conf /usr/share/logstash/pipeline/logstash.conf.example

########
# copied from upstream
#######

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
RUN yum update -y && yum install -y java-1.8.0-openjdk-devel which && \
    yum clean all
WORKDIR /usr/share/logstash

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/logstash/bin:$PATH
# Ensure Logstash gets a UTF-8 locale by default.
ENV LANG='en_US.UTF-8' LC_ALL='en_US.UTF-8'
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
      --home-dir /usr/share/logstash --no-create-home \
      logstash
RUN ln -s /usr/share/logstash /opt/logstash
USER 1000
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
########
# end stuff from upstream
########

# what you all came here to see
EXPOSE 9600
