ngx.log(ngx.WARN, 'DEPRECATION: file renamed - change: require("apicast.policy.apicast")' ,' to: require("apicast.policy.3scale")')

return require('apicast.policy.3scale')
