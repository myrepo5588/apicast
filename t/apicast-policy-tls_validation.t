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
--- configuration eval
use JSON qw(to_json);
use File::Slurp qw(read_file);

to_json({
  services => [{
    proxy => {
        policy_chain => [
          { name => 'apicast.policy.tls_validation',
            configuration => {
              whitelist => [
                { pem_certificate => CORE::join('', read_file('t/fixtures/client.crt')) }
              ]
            }
          },
          { name => 'apicast.policy.echo' },
        ]
    }
  }]
});
--- test env
proxy_ssl_certificate $TEST_NGINX_SERVER_ROOT/html/client.crt;
proxy_ssl_certificate_key $TEST_NGINX_SERVER_ROOT/html/client.key;
proxy_ssl_password_file $TEST_NGINX_SERVER_ROOT/html/passwords.file;
proxy_pass https://$server_addr:$apicast_port/t;
proxy_set_header Host localhost;
log_by_lua_block { collectgarbage() }
--- response_body
GET /t HTTP/1.0
--- error_code: 200
--- no_error_log
[error]
--- user_files fixture=mutual_ssl.pl eval
