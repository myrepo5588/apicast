use lib 't';
use Test::APIcast::Blackbox 'no_plan';

env_to_apicast(
    'APICAST_HTTPS_PORT' => "$Test::Nginx::Util::ServerPortForClient",
    'APICAST_HTTPS_CERTIFICATE' => "$Test::Nginx::Util::ServRoot/html/server.crt",
    'APICAST_HTTPS_CERTIFICATE_KEY' => "$Test::Nginx::Util::ServRoot/html/server.key",
    'APICAST_HTTPS_PASSWORD_FILE' => "$Test::Nginx::Util::ServRoot/html/passwords.file",
    'APICAST_HTTPS_SESSION_REUSE' => 'on',
);

run_tests();

__DATA__

=== TEST 1: tls_validation accepts configuration
--- configuration
{
  "services": [
    {
      "proxy": {
        "policy_chain": [
          { "name": "apicast.policy.tls_validation",
            "configuration": { } },
          { "name": "apicast.policy.echo" }
        ]
      }
    }
  ]
}
--- request
GET /t
--- response_body
GET /t HTTP/1.1
--- error_code: 200
--- no_error_log
[error]
--- user_files fixture=mutual_ssl.pl eval
