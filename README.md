# SQUID

This is a password protected version of squid, based on the
`sameersbn/squid:3.5.27-2` DockerHub image.  It uses basic HTTP authentication
with the `squid` username and whatever password you set.

Note:

1. Squid listens on port 80
2. Squid needs a password set in the PASSWORD environment variable

For example:

```
$ docker run -p 3128:80 -e PASSWORD=foo 2shortplanks/squid
```

And then in another window, you can use the proxy

```
curl -x squid@foo127.0.0.1:3128 google.com
```

