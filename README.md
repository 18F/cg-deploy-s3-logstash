# cg-deploy-s3-logsearch

Build and deploy a container to get logs from S3 to Elasticsearch

## Development

The docker directory houses all of the resources necessary for building the docker container. They
can be tested using the tools in the test directory.

## Testing

`test/test-image.sh` will optionally build a container, and test a specified version of a container.
It validates that the container produces config that is parsable by logstash when run with expected 
environment variables, and tests the filters.

To test the filters, the test script expects to find files names `${something}.log` and 
`${something}-expected.json`. The log file should contain test log entries, and the json file
contains the expected results, one json object per line, of the expected results. The script
`test/test-image.sh` copies the log files into a separate directory, starts the docker container and
waits for it to finish reading the logs from the file. Once the file has been parsed, the script 
calls `compare-json.py` to compare the json objects in the expected and actual files.

### Sample log files

The sample log file `examples-from-docs.log` has all of the examples from the [ALB][1] and [ELB][2] 
logging documentation on AWS.



[1]: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
[2]: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html
