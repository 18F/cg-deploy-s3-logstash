#!/usr/bin/env ruby
require "erb"
STRING_INPUT_SETTINGS = { "S3_BACKUP_ADD_PREFIX" => "backup_add_prefix",
                     "S3_BACKUP_TO_BUCKET" => "backup_to_bucket",
                     "S3_BUCKET" => "bucket",
                     "S3_EXCLUDE_PATTERN" => "exclude_pattern",
                     "S3_PREFIX" => "prefix",
                     "S3_PROXY_URI" => "proxy_uri",
                     "S3_REGION" => "region",
                     "S3_ROLE_ARN" => "role_arn",
                     "S3_ROLE_SESSION_NAME" => "role_session_name",
                     "S3_SINCEDB_PATH" => "sincedb_path",
                     "S3_TEMPORARY_DIRECTORY" => "temporary_directory"
            }
NUM_INPUT_SETTINGS = { "S3_INTERVAL" => "interval" }
BOOLEAN_INPUT_SETTINGS = { "S3_INCLUDE_OBJECT_PROPERTIES" => "include_object_properties",
                      "S3_DELETE" => "delete",
                      "S3_WATCH_FOR_NEW_FILES" => "watch_for_new_files"
}
STRING_OUTPUT_SETTINGS = {
    "ELASTICSEARCH_INDEX" => "index",
    "ELASTICSEARCH_DOCUMENT_ID" => "document_id",
    "ELASTICSEARCH_ROUTING" => "routing"
}
NUM_OUTPUT_SETTINGS = {
    "ELASTICSEARCH_IDLE_FLUSH_TIME" => "idle_flush_time"
}
BOOLEAN_OUTPUT_SETTINGS = {

}
def string_to_bool (str)
    return str == 'true' || str =~ /(true|t|yes|y|1)$/i
end

input_template = %q/
input {
<% if ENV['LOGSTASH_READ_FROM_FILE'] != nil %>
<%# for testing %>
    file {
        path => [ "<%= ENV['LOGSTASH_READ_FROM_FILE'] %>" ]
        mode => "read"
    }
<% else %>
    s3 {
<% STRING_INPUT_SETTINGS.each do |key, value| %>
<% if ENV[key] != nil %>
        <%= value %> => <%= ENV[key].inspect %>
<% end %>
<% end %>
<% NUM_INPUT_SETTINGS.each do |key, value| %>
<% if ENV[key] != nil %>
        <%= value %> => <%= ENV[key] %>
<% end %>
<% end %>
<% BOOLEAN_INPUT_SETTINGS.each do |key, value| %>
<% if ENV[key] != nil %>
        <%= value %> => <%= string_to_bool(ENV[key]).inspect %>
<% end %>
<% end %>
    }
<% end %>
}
/

filter_string = %q/
filter {
    # we have alb and elb logs in this bucket. Try ALB log format first, then ELB if that fails
    dissect {
        mapping => {
           "message" => '%{[@alb][type]} %{[@alb][timestamp]} %{[@alb][alb][id]} %{[@alb][client][ip]}:%{[@alb][client][port]} %{alb_target_ip_port} %{[@alb][request][processing_time]} %{alb_target_processing_time} %{[@alb][response][processing_time]} %{[@alb][alb][status_code]} %{alb_target_status_code} %{[@alb][received_bytes]} %{[@alb][sent_bytes]} "%{[@alb][request][request]}" "%{[@alb][user_agent]}" %{alb_ssl_cipher} %{alb_ssl_protocol} %{alb_target_group_arn} "%{[@alb][trace_id]}" "%{[@alb][domain_name]}" "%{[@alb][chosen_cert_arn]}" %{[@alb][matched_rule_priority]} %{[@alb][request][creation_time]} "%{[@alb][actions_executed]}" "%{alb_redirect_url}" "%{alb_error_reason}"'
        }
        id => "alb-dissect"
    }

    # dissect above will automatically add this tag
    if "_dissectfailure" not in [tags] {
        prune {
            # aws uses - to indicate something like null. Removing it lets us safely convert numbers later
            blacklist_values => [
                                 "alb_error_reason", "^-$",
                                 "alb_target_ip_port", "^-$",
                                 "alb_target_processing_time", "^-$",
                                 "alb_target_status_code", "^-$",
                                 "alb_target_group_arn", "^-$",
                                 "alb_redirect_url", "^-$",
                                 "alb_ssl_cipher", "^-$",
                                 "alb_ssl_protocol", "^-$"
                                ]
        }

        mutate {
            rename => {
                        "alb_error_reason" => "[@alb][error][reason]"
                        "alb_target_ip_port" => "[@alb][target][ip_port]"
                        "alb_target_processing_time" => "[@alb][target][processing_time]"
                        "alb_target_status_code" => "[@alb][target][status_code]"
                        "alb_target_group_arn" => "[@alb][target_group_arn]"
                        "alb_redirect_url" => "[@alb][redirect_url]"
                        "alb_ssl_cipher" => "[@alb][ssl_cipher]"
                        "alb_ssl_protocol" => "[@alb][ssl_protocol]"
            }
        }

        dissect {
            # this field may be "-", so we can't split it above
            # but we definitely want it to match client.ip and client.port if it exists
            mapping => {
                "[@alb][target][ip_port]" => "%{[@alb][target][ip]}:%{[@alb][target][port]}"
            }
            remove_field => [ "[@alb][target][ip_port]" ]
        }

        mutate {
            convert => {
                "[@alb][target][status_code]" => "integer"
                "[@alb][target][port]" => "integer"
                "[@alb][client][port]" => "integer"
                "[@alb][request][processing_time]" => "float"
                "[@alb][sent_bytes]" => "integer"
                "[@alb][received_bytes]" => "integer"
                "[@alb][alb][status_code]" => "integer"
            }
        }

        date {
            match => [ "[@alb][timestamp]", "ISO8601"]
        }
    } else {
        dissect {
            mapping => {
                "message" => '%{[@elb][timestamp]} %{[@elb][elb][id]} %{[@elb][client][ip]}:%{[@elb][client][port]} %{[elb_target_ip_port]} %{[@elb][request][processing_time]} %{[elb_target_processing_time]} %{[@elb][response][processing_time]} %{[@elb][elb][status_code]} %{[elb_target_status_code]} %{[@elb][received_bytes]} %{[@elb][sent_bytes]} "%{[@elb][request][verb]} %{[@elb][request][url]} %{[@elb][request][protocol]}" "%{[@elb][request][user_agent]}" %{[@elb][ssl][cipher]} %{[@elb][ssl][protocol]}'
            }
            remove_tag => [ "_dissectfailure" ]
            id => "elb-dissect"
        }
        prune {
            # aws uses - to indicate something like null. Removing it lets us safely convert numbers later
            blacklist_values => [
                                 "elb_target_ip_port", "^-$",
                                 "elb_target_processing_time", "^-$",
                                 "elb_target_status_code", "^-$",
                                 "elb_ssl_cipher", "^-$",
                                 "elb_ssl_protocol", "^-$"
                                ]
        }

        mutate {
            rename => {
                        "elb_target_ip_port" => "[@elb][target][ip_port]"
                        "elb_target_processing_time" => "[@elb][target][processing_time]"
                        "elb_target_status_code" => "[@elb][target][status_code]"
                        "elb_ssl_cipher" => "[@elb][ssl_cipher]"
                        "elb_ssl_protocol" => "[@elb][ssl_protocol]"
            }
            remove_tag => [ "_dissectfailure" ]
        }

        dissect {
            # this field may be "-", so we can't split it above
            # but we definitely want it to match client.ip and client.port if it exists
            mapping => {
                "[@elb][target][ip_port]" => "%{[@elb][target][ip]}:%{[@elb][target][port]}"
            }
            remove_field => [ "[@elb][target][ip_port]" ]
        }

        mutate {
            convert => {
                "[@elb][target][status_code]" => "integer"
                "[@elb][target][port]" => "integer"
                "[@elb][client][port]" => "integer"
                "[@elb][request][processing_time]" => "float"
                "[@elb][sent_bytes]" => "integer"
                "[@elb][received_bytes]" => "integer"
                "[@elb][elb][status_code]" => "integer"
            }
        }

        date {
            match => [ "[@elb][timestamp]", "ISO8601"]
        }
    }
}

/

output_template = %q/
output {
<% if ENV['LOGSTASH_STDOUT'] != nil %>
    stdout {
        codec => "json"
    }
<% elsif ENV['LOGSTASH_OUT_FILE'] != nil %>
    file {
        path => "<%= ENV['LOGSTASH_OUT_FILE'] %>"
    }
<% else %>
    elasticsearch {
        hosts =>  <%= ENV['ELASTICSEARCH_HOSTS'].split(',').inspect %> 
        manage_template => false
<% STRING_OUTPUT_SETTINGS.each do |key, value| %>
<% if ENV[key] != nil %>
        <%= value %> => <%= ENV[key].inspect %>
<% end %>
<% end %>
<% NUM_OUTPUT_SETTINGS.each do |key, value| %>
<% if ENV[key] != nil %>
        <%= value %> => <%= ENV[key] %>
<% end %>
<% end %>
    
<% BOOLEAN_OUTPUT_SETTINGS.each do |key, value| %>
<% if ENV[key] != nil %>
        <%= value %> => <%= string_to_bool(ENV[key]).inspect %>
<% end %>
<% end %>
    }
<% end %>
}
/
input_string = ERB.new(input_template, trim_mode: "-").result
output_string = ERB.new(output_template, trim_mode: "-").result
puts input_string
puts filter_string
puts output_string
