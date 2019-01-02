use lib 't';
use Test::APIcast::Blackbox 'no_plan';

our $rsa = `cat t/fixtures/rsa.pem`;

run_tests();

__DATA__

=== TEST 1: the rule matches the path using "==" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "path",
                  "op": "==",
                  "value": "/a_path",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 2: the rule matches the path using "==" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "path",
                  "op": "==",
                  "value": "/",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /i_dont_match
--- response_body
GET /i_dont_match HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 3: the rule matches the path using "!=" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "path",
                  "op": "!=",
                  "value": "/",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /i_dont_match {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /i_dont_match
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 4: the rule matches the path using "!=" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "path",
                  "op": "!=",
                  "value": "/a_path",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path
--- response_body
GET /a_path HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 5: the rule matches the path using "matches" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "path",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /something_123_something
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 6: the rule matches the path using "matches" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "path",
                  "op": "matches",
                  "value": "^123$",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /something_123_something
--- response_body
GET /something_123_something HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 7: the rule matches a header using "==" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "header",
                  "entity_value": "Test-Header",
                  "op": "==",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers
Test-Header: some_value
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 8: the rule matches a header using "==" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "header",
                  "entity_value": "Test-Header",
                  "op": "==",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers
Test-Header: i_dont_match
--- response_body
GET / HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 9: the rule matches a header using "!=" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "header",
                  "entity_value": "Test-Header",
                  "op": "!=",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers
Test-Header: i_dont_match
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 10: the rule matches a header using "!=" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "header",
                  "entity_value": "Test-Header",
                  "op": "!=",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers
Test-Header: some_value
--- response_body
GET / HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 11: the rule matches the path using "matches" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "header",
                  "entity_value": "Test-Header",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers
Test-Header: something_123_something
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 12: the rule matches the path using "matches" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "header",
                  "entity_value": "Test-Header",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location / {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers
Test-Header: i_dont_match
--- response_body
GET / HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 13: the rule matches a query arg using "==" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "query_arg",
                  "entity_value": "test_arg",
                  "op": "==",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path?test_arg=some_value
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 14: the rule matches a query arg using "==" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "query_arg",
                  "entity_value": "test_arg",
                  "op": "==",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path?test_arg=i_dont_match
--- response_body
GET /a_path?test_arg=i_dont_match HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 15: the rule matches a query arg using "!=" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "query_arg",
                  "entity_value": "test_arg",
                  "op": "!=",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path?test_arg=i_dont_match
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 16: the rule matches a query arg "!=" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "query_arg",
                  "entity_value": "test_arg",
                  "op": "!=",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path?test_arg=some_value
--- response_body
GET /a_path?test_arg=some_value HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 17: the rule matches a query arg using "matches" and the condition is true
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "query_arg",
                  "entity_value": "test_arg",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path?test_arg=something_123_something
--- response_body
yay, api backend
--- error_code: 200
--- no_error_log
[error]

=== TEST 18: the rule matches a query arg using "matches" and the condition is false
--- configuration
{
  "services": [
    {
      "id": 42,
      "proxy": {
        "policy_chain": [
          {
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "query_arg",
                  "entity_value": "test_arg",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
          }
        ]
      }
    }
  ]
}
--- upstream
  location /a_path {
     content_by_lua_block {
       ngx.say('yay, api backend');
     }
  }
--- request
GET /a_path?test_arg=i_dont_match
--- response_body
GET /a_path?test_arg=i_dont_match HTTP/1.1
--- error_code: 200
--- no_error_log
[error]

=== TEST 19: the rule matches a jwt claim using "==" and the condition is true
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
      "config": {
        "id_token_signing_alg_values_supported": [
          "RS256"
        ]
      },
      "keys": {
        "somekid": {
          "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----"
        }
      }
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
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "jwt_claim",
                  "entity_value": "test_jwt_claim",
                  "op": "==",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
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
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
test_jwt_claim => 'some_value',
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

=== TEST 20: the rule matches a jwt claim using "==" and the condition is false
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
      "config": {
        "id_token_signing_alg_values_supported": [
          "RS256"
        ]
      },
      "keys": {
        "somekid": {
          "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----"
        }
      }
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
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "jwt_claim",
                  "entity_value": "test_jwt_claim",
                  "op": "==",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
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
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
test_jwt_claim => 'i_dont_match',
aud => 'the_token_audience',
sub => 'someone',
iss => 'https://example.com/auth/realms/apicast',
exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
GET / HTTP/1.1
--- no_error_log
[error]

=== TEST 21: the rule matches a jwt claim using "!=" and the condition is true
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
      "config": {
        "id_token_signing_alg_values_supported": [
          "RS256"
        ]
      },
      "keys": {
        "somekid": {
          "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----"
        }
      }
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
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "jwt_claim",
                  "entity_value": "test_jwt_claim",
                  "op": "!=",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
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
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
test_jwt_claim => 'i_dont_match',
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

=== TEST 22: the rule matches a jwt claim using "!=" and the condition is false
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
      "config": {
        "id_token_signing_alg_values_supported": [
          "RS256"
        ]
      },
      "keys": {
        "somekid": {
          "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----"
        }
      }
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
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "jwt_claim",
                  "entity_value": "test_jwt_claim",
                  "op": "!=",
                  "value": "some_value",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
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
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
test_jwt_claim => 'some_value',
aud => 'the_token_audience',
sub => 'someone',
iss => 'https://example.com/auth/realms/apicast',
exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
GET / HTTP/1.1
--- no_error_log
[error]

=== TEST 23: the rule matches a jwt claim using "matches" and the condition is true
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
      "config": {
        "id_token_signing_alg_values_supported": [
          "RS256"
        ]
      },
      "keys": {
        "somekid": {
          "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----"
        }
      }
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
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "jwt_claim",
                  "entity_value": "test_jwt_claim",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
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
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
test_jwt_claim => 'something_123_something',
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

=== TEST 24: the rule matches a jwt claim using "matches" and the condition is false
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
      "config": {
        "id_token_signing_alg_values_supported": [
          "RS256"
        ]
      },
      "keys": {
        "somekid": {
          "pem": "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBALClz96cDQ965ENYMfZzG+Acu25lpx2K\nNpAALBQ+catCA59us7+uLY5rjQR6SOgZpCz5PJiKNAdRPDJMXSmXqM0CAwEAAQ==\n-----END PUBLIC KEY-----"
        }
      }
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
            "name": "apicast.policy.routing",
            "configuration": {
              "rules": [
                {
                  "entity": "jwt_claim",
                  "entity_value": "test_jwt_claim",
                  "op": "matches",
                  "value": ".*123.*",
                  "url": "http://test:$TEST_NGINX_SERVER_PORT"
                }
              ]
            }
          },
          {
            "name": "apicast.policy.echo"
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
       ngx.say('yay, api backend');
     }
  }
--- request
GET /
--- more_headers eval
use Crypt::JWT qw(encode_jwt);
my $jwt = encode_jwt(payload => {
test_jwt_claim => 'i_dont_match',
aud => 'the_token_audience',
sub => 'someone',
iss => 'https://example.com/auth/realms/apicast',
exp => time + 3600 }, key => \$::rsa, alg => 'RS256', extra_headers=>{ kid => 'somekid' });
"Authorization: Bearer $jwt"
--- error_code: 200
--- response_body
GET / HTTP/1.1
--- no_error_log
[error]
