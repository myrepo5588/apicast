use lib 't';
use Test::APIcast::Blackbox 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: limits and metric hierarchy in config
In this test, the limits and the metric hierarchy are included in the config.
It does not retrieve them from 3scale's system. We define a metric with a limit
of 2 per minute. We make 2 calls, check that they succeed, make another with a
different user key to make sure it does not interfere, and finally, we make
another call with the original user key and check that the policy applies the
rate limit.
--- configuration
{
  "services": [
    {
      "id": 42,
      "backend_version":  1,
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "error_limits_exceeded": "limits exceeded!",
        "error_status_limits_exceeded": 429,
        "policy_chain": [
          {
            "name": "apicast.policy.threescale_rate_limit",
            "configuration": {
              "metrics_hierarchy": [
                {
                  "child": "child_metric",
                  "parent": "parent_metric"
                }
              ],
              "limits": [
                {
                  "plan": "Basic",
                  "metric": "child_metric",
                  "period": "minute",
                  "value": 2
                }
              ]
            }
          },
          {
            "name": "apicast.policy.apicast"
          }
        ],
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "child_metric", "delta": 1 }
        ]
      }
    }
  ]
}
--- backend
  location /transactions/authorize.xml {
    content_by_lua_block {
      -- Return a simplified response
      ngx.say(
        '<?xml version="1.0" encoding="UTF-8"?><status><authorized>true</authorized><plan>Basic</plan></status>'
      )
    }
  }
--- upstream
  location / {
     echo 'yay, api backend';
  }
--- request eval
["GET /?user_key=uk", "GET /?user_key=uk", "GET /?user_key=other_user_key", "GET /?user_key=uk"]
--- response_body eval
["yay, api backend\x{0a}", "yay, api backend\x{0a}", "yay, api backend\x{0a}", "limits exceeded!"]
--- error_code eval
[ 200, 200, 200, 429 ]
