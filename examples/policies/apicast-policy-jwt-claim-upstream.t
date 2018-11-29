use lib 't';
use Test::APIcast::Blackbox 'no_plan';

env_to_apicast(
    'APICAST_POLICY_LOAD_PATH' => "$ENV{PWD}/examples/policies"
);

our $rsa = `cat t/fixtures/rsa.pem`;

run_tests();

__DATA__

=== TEST 1: single rule that matches
In this test, we provide a rule that matches the request and sets the upstream
to the one we have set up. If this was not working we would notice, because
"api_backend" in the service configuration points to an invalid one.
--- backend
  location /transactions/oauth_authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- configuration
{
  "oidc": [
    {
      "issuer": "https://example.com/auth/realms/apicast",
      "config": { "id_token_signing_alg_values_supported": [ "RS256" ] },
      "keys": { "somekid": { "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----" } }
    }
  ],
  "services": [
    {
      "id": 42,
      "backend_version": "oauth",
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "authentication_method": "oidc",
        "oidc_issuer_endpoint": "https://example.com/auth/realms/apicast",
        "api_backend": "http://example.com:80/",
        "proxy_rules": [
          {
            "pattern": "/",
            "http_method": "GET",
            "metric_system_name": "hits",
            "delta": 2
          }
        ],
        "policy_chain": [
          {
            "name": "jwt_claim_upstream",
            "version": "1.0.0",
            "configuration": {
              "rules": [
                {
                  "jwt_claim": "some_claim",
                  "regex": "abc",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.apicast"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       require('luassert').are.equal('GET / HTTP/1.1',
                                     ngx.var.request)
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
  some_claim => 'abc',
  aud => 'the_token_audience',
  sub => 'someone',
  iss => 'https://example.com/auth/realms/apicast',
  exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
yay, api backend
--- no_error_log
[error]

=== TEST 2: multiple rules that match
In this example, we provide a rule that does not match and two that do.
Rules should be matched in order, so we set the first rule that matches to the
upstream we have set up.
--- backend
  location /transactions/oauth_authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- configuration
{
  "oidc": [
    {
      "issuer": "https://example.com/auth/realms/apicast",
      "config": { "id_token_signing_alg_values_supported": [ "RS256" ] },
      "keys": { "somekid": { "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----" } }
    }
  ],
  "services": [
    {
      "id": 42,
      "backend_version": "oauth",
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "authentication_method": "oidc",
        "oidc_issuer_endpoint": "https://example.com/auth/realms/apicast",
        "api_backend": "http://example:80/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ],
        "policy_chain": [
          {
            "name": "jwt_claim_upstream",
            "version": "1.0.0",
            "configuration": {
              "rules": [
                {
                  "jwt_claim": "some_claim",
                  "regex": "abc.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                },
                {
                  "jwt_claim": "some_claim",
                  "regex": "abc_123",
                  "url": "http://example.com"
                }
              ]
            }
          },
          { "name": "apicast.policy.apicast" }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       require('luassert').are.equal('GET / HTTP/1.1',
                                     ngx.var.request)
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
  some_claim => 'abc_123',
  aud => 'the_token_audience',
  sub => 'someone',
  iss => 'https://example.com/auth/realms/apicast',
  exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
yay, api backend
--- no_error_log
[error]

=== TEST 3: non-matching rules
In this example, none of the rules match, so the request will go to the
upstream in 'api_backend'.
--- backend
  location /transactions/oauth_authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- configuration
{
  "oidc": [
    {
      "issuer": "https://example.com/auth/realms/apicast",
      "config": { "id_token_signing_alg_values_supported": [ "RS256" ] },
      "keys": { "somekid": { "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----" } }
    }
  ],
  "services": [
    {
      "id": 42,
      "backend_version": "oauth",
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "authentication_method": "oidc",
        "oidc_issuer_endpoint": "https://example.com/auth/realms/apicast",
        "api_backend": "http://test:$TEST_NGINX_SERVER_PORT",
        "proxy_rules": [
          { "pattern": "/", "http_method": "GET", "metric_system_name": "hits", "delta": 2 }
        ],
        "policy_chain": [
          {
            "name": "jwt_claim_upstream",
            "version": "1.0.0",
            "configuration": {
              "rules": [
                {
                  "jwt_claim": "some_claim",
                  "regex": "i_dont_match",
                  "url": "http://example.com"
                },
                {
                  "jwt_claim": "some_claim",
                  "regex": "i_dont_match_either",
                  "url": "http://example.com"
                }
              ]
            }
          },
          { "name": "apicast.policy.apicast" }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       require('luassert').are.equal('GET / HTTP/1.1',
                                     ngx.var.request)
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
  some_claim => 'abc',
  aud => 'the_token_audience',
  sub => 'someone',
  iss => 'https://example.com/auth/realms/apicast',
  exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
yay, api backend
--- no_error_log
[error]

=== TEST 4: rule that matches contains url with path
--- backend
  location /transactions/oauth_authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- configuration
{
  "oidc": [
    {
      "issuer": "https://example.com/auth/realms/apicast",
      "config": { "id_token_signing_alg_values_supported": [ "RS256" ] },
      "keys": { "somekid": { "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----" } }
    }
  ],
  "services": [
    {
      "id": 42,
      "backend_version": "oauth",
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "authentication_method": "oidc",
        "oidc_issuer_endpoint": "https://example.com/auth/realms/apicast",
        "api_backend": "http://example.com:80/",
        "proxy_rules": [
          {
            "pattern": "/",
            "http_method": "GET",
            "metric_system_name": "hits",
            "delta": 2
          }
        ],
        "policy_chain": [
          {
            "name": "jwt_claim_upstream",
            "version": "1.0.0",
            "configuration": {
              "rules": [
                {
                  "jwt_claim": "some_claim",
                  "regex": "abc",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT/path_in_the_rule"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.apicast"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       require('luassert').are.equal('GET /path_in_the_rule/path_in_request HTTP/1.1',
                                     ngx.var.request)
       ngx.say('yay, api backend');
     }
  }
--- request
GET /path_in_request
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
  some_claim => 'abc',
  aud => 'the_token_audience',
  sub => 'someone',
  iss => 'https://example.com/auth/realms/apicast',
  exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
yay, api backend
--- no_error_log
[error]

=== TEST 5: rule that matches a POST request
--- backend
  location /transactions/oauth_authrep.xml {
    content_by_lua_block {
      ngx.exit(200)
    }
  }
--- configuration
{
  "oidc": [
    {
      "issuer": "https://example.com/auth/realms/apicast",
      "config": { "id_token_signing_alg_values_supported": [ "RS256" ] },
      "keys": { "somekid": { "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----" } }
    }
  ],
  "services": [
    {
      "id": 42,
      "backend_version": "oauth",
      "backend_authentication_type": "service_token",
      "backend_authentication_value": "token-value",
      "proxy": {
        "authentication_method": "oidc",
        "oidc_issuer_endpoint": "https://example.com/auth/realms/apicast",
        "api_backend": "http://example.com:80/",
        "proxy_rules": [
          { "pattern": "/", "http_method": "POST", "metric_system_name": "hits", "delta": 2 }
        ],
        "policy_chain": [
          { "name": "apicast.policy.upstream",
            "configuration":
              {
                "rules": [ { "regex": "/", "url": "http://test:$TEST_NGINX_SERVER_PORT" } ]
              }
          },
          { "name": "apicast.policy.apicast" }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       local luassert = require('luassert')

       luassert.are.equal('POST / HTTP/1.1', ngx.var.request)

       ngx.req.read_body()
       local post_args = ngx.req.get_post_args()
       luassert.are.equal('a_value', post_args['a_param'])

       ngx.say('yay, api backend')
     }
  }
--- request
POST /
a_param=a_value
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
  some_claim => 'abc',
  aud => 'the_token_audience',
  sub => 'someone',
  iss => 'https://example.com/auth/realms/apicast',
  exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
yay, api backend
--- no_error_log
[error]
