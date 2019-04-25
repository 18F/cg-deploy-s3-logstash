s3-logstash
-----------

## What it is ##
Simple logstash container for getting ALB logs from S3 to Elasticsearch.

## How do I use it? ##

All configuration is done via environment variables, most of which map directly
to config available from Logstash:

### input config ###


| environment variable            |  s3 plugin directive         | expected value  |   
|---------------------------------|------------------------------|-----------------|
| `S3_BACKUP_ADD_PREFIX`          | `backup_add_prefix`          | string          |
| `S3_BACKUP_TO_BUCKET`           | `backup_to_bucket`           | string          |
| `S3_BUCKET`                     | `bucket`                     | string          |
| `S3_EXCLUDE_PATTERN`            | `exclude_pattern`            | string          |
| `S3_PREFIX`                     | `prefix`                     | string          |
| `S3_PROXY_URI`                  | `proxy_uri`                  | string          |
| `S3_REGION`                     | `region`                     | string          |
| `S3_ROLE_ARN`                   | `role_arn`                   | string          |
| `S3_ROLE_SESSION_NAME`          | `role_session_name`          | string          |
| `S3_SINCEDB_PATH`               | `sincedb_path`               | string          |
| `S3_TEMPORARY_DIRECTORY`        | `temporary_directory`        | string          |
| `S3_INTERVAL`                   | `interval`                   | integer         |
| `S3_INCLUDE_OBJECT_PROPERTIES`  | `include_object_properties`  | t/true/f/false  |
| `S3_DELETE`                     | `delete`                     | t/true/f/false  |
| `S3_WATCH_FOR_NEW_FILES`        | `watch_for_new_files`        | t/true/f/false  |
|                                 |                              |                 |

You can alternately set `LOGSTASH_READ_FROM_FILE` to a path you'd like to read from. With this
set, all S3 settings will be ignored, and logstash will only read from a file (useful for testing).

### filter config ###

There is none. Sorry/you're welcome. 

Currently, this only expects to read ALB logs, and will parse the fillowing fields:

`@alb.actions_executed`
`@alb.alb.id`
`@alb.alb.status_code`
`@alb.chosen_cert_arn`
`@alb.client.ip`
`@alb.client.port`
`@alb.domain_name`
`@alb.error_reason` \*
`@alb.received_bytes`
`@alb.sent_bytes`
`@alb.matched_rule_priority`
`@alb.redirect_url` \*
`@alb.request.creation_time`
`@alb.request.processing_time`
`@alb.request.request`
`@alb.response.processing_time`
`@alb.ssl_cipher` \*
`@alb.ssl_protocol` \*
`@alb.target.group_arn` \*
`@alb.target.ip` \*
`@alb.target.port` \*
`@alb.target.processing_time`
`@alb.target.status_code`
`@alb.timestamp`
`@alb.trace_id`
`@alb.type`
`@alb.user_agent`

\* does not exist if it does not apply

### output config ###

Set the elasticsearch target hosts with `ELASTICSEARCH_HOSTS`, comma-separated. Ex: `ELASTICSEARCH_HOSTS=myhost.example.com:1234,localhost,123.45.67.89:9200`
Other settings directly map to Elasticsearch output plugin directives:

| environment variable            | elasticsearch plugin directive  | type          |
|---------------------------------|---------------------------------|---------------|
| `ELASTICSEARCH_INDEX`           | `index`                         | string        |
| `ELASTICSEARCH_DOCUMENT_ID`     | `document_id`                   | string        |
| `ELASTICSEARCH_ROUTING`         | `routing`                       | string        |
| `ELASTICSEARCH_IDLE_FLUSH_TIME` | `idle_flush_time`               | integer       |
|                                 |                                 |               |

You can alternately set `LOGSTASH_STDOUT` to any value, and logstash will instead print logs to stdout
