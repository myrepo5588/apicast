local cjson = require('cjson')

local configuration = cjson.encode({
  services = setmetatable({
    {
      proxy = {
        hosts = {
          "localhost",
          "127.0.0.1"
        },
        policy_chain = setmetatable({
            { name = "apicast.policy.tls_validation",
              configuration = {
                  whitelist = setmetatable({
                      { pem_certificate = [[
-----BEGIN CERTIFICATE-----
MIICvDCCAaQCCQDyra7VGipAyzANBgkqhkiG9w0BAQsFADAgMR4wHAYDVQQDDBVD
ZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTgxMjA2MTcwOTA1WhcNMjgxMjAzMTcw
OTA1WjAgMQ8wDQYDVQQKDAZDbGllbnQxDTALBgNVBAMMBGN1cmwwggEiMA0GCSqG
SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDt9H6xhm0pGqARRGMaUrSbZvetrN1mo+O4
KuqPRr8I/YhvOEPlc/8VMxF3nyETGjQ+khO9FJGDoDD2S3yGzt1FFiNI6AOPkmux
DZMUQ2alnS7fG0zBUlxRx9otoMx/vH4gnKTfmHofuwPwkLPSWoHf0ZmPLXbm19ds
aKvllOX8vjEjtNprtUzveeDOnuov2GXqo/w+FOnDxYhys1Oidx3LOje5izV7EX4+
+HH+7EwRV7m4+s/G97z5soo1XIZHHQKKC0DONWTOdeLkqLlAqU0nuuRkFzmbrD4u
2haxqcuyficBgbFWZznLDxJ1fMJzen7YbYea1GycTKe6Wt4xviDDAgMBAAEwDQYJ
KoZIhvcNAQELBQADggEBADY5udciqAIAFtJWVQ+AT+5RAWClGlEfi7wAfsGWUIpi
1mQjkGSqbZ4DSEECsRNiokjSyA5Phi9REg8tDCVaovMANncptUX6PJzCkpkdD5Wo
cMWzF8dZpphyZH+RwGM7aTGmdz/mnxKtVoTt++wLNv2jardRKoFvyu+FBzpTbWBe
2EYaIlGHRrIMoU9ZK3D2rGHK3GsakZT3e76/P5KuyIp1+K7IEWmD4Fk3GM6uM+Rc
Q7zGkdX+LBr85p07DHTcDxAwIT6xXh2J1fhiyart5sHkMg6YZ5JpjitIOEypnyiq
KjTINz0a+0rohUDR6BWkdU5R8Bpbw1Pg7Owx9B51KQM=
-----END CERTIFICATE-----
]]},
                  }, cjson.array_mt),
              }
            },
            { name = "apicast.policy.echo" }
        }, cjson.array_mt)
      }
    }
  }, cjson.array_mt)
})

-- See https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URIs
local function data_url(mime_type, content)
  return string.format([[data:%s,%s]],mime_type, ngx.escape_uri(content))
end

return {
    worker_processes = '1',
    master_process = 'off',
    lua_code_cache = 'on',
    configuration_loader = 'lazy',
    configuration_cache = 0,
    configuration = data_url('application/json', configuration),
    port = { metrics = 9421 }, -- see https://github.com/prometheus/prometheus/wiki/Default-port-allocations,
    timer_resolution = false,
}
