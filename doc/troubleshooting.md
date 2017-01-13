# Troubleshooting APIcast

## Self-Managed

### Logging

When running APIcast, the default log level is `warn.` 

You can increase verbosity in the logs by appending (multiple) `-v` parameters when running the apicast binary, e.g 


You can also decrease verbosity by appending (multiple) `-q` parameters instead, e.g 

### DNS Issues

If you see the following error in your logs `[error] 1619#0: recv() failed (61: Connection refused) while resolving, resolver: 127.0.0.1:53`

It means that APIcast is unable to correctly detect your dns settings, from /etc/resolv.conf. In this case you should copy the nameserver IP 

e.g 

```
.
.
.
nameserver 1.2.3.4
nameserver 5.6.7.8
```

into apicast/http.d/resolver.conf as follows

```
resolver 1.2.3.4 ipv6=off;
resolver 5.6.7.8 ipv6=off;
```

You can read more about the resolver directive in the [Nginx Documentation](https://nginx.org/en/docs/http/ngx_http_core_module.html#resolver)

## Openshift

### Insecure Registry

## Docker

### Logging

When running APIcast, you can increase the default log level (warn) by setting the APICAST_LOG_LEVEL parameter. 

Values: debug | info | notice | warn | error | crit | alert | emerg
